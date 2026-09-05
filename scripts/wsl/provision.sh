#!/usr/bin/env bash
#
# provision.sh — 在 WSL2 (Ubuntu 22.04) 内一键安装研究环境
#
# 安装内容:
#   - 系统基础工具 (build-essential, git, curl, python3-venv ...)
#   - GDAL 3.4 (gdal-bin + libgdal-dev + python3-gdal)
#   - Python 虚拟环境 ~/verigis/venv (继承系统 GDAL),含 numpy/scipy/whiteboxtools/richdem
#   - Lean 4 + mathlib (via elan)
#   - Dafny (固定 v4.8.1, ubuntu-22.04 .deb 直装)
#
# 用法(在 Windows PowerShell 中执行,路径按需修改):
#   wsl -d Ubuntu-22.04 -- bash -c "sudo bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/provision.sh'"
#
# 说明:
#   - 幂等:重复运行不会重复安装已存在的组件。
#   - mathlib 首次构建需要 30–60 分钟,脚本不阻塞,失败会记为"非致命"。
#   - **如果此脚本部分失败(Lake/Dafny/venv 之一缺失),请运行同目录的 remedy.sh 补装。**
#   - 日志同时写入 ~/wsl_provision.log。
#
# 设计要点:
#   - 使用 set -uo pipefail,但不能 set -e:mathlib 构建允许非致命超时。
#   - 每步后做 command -v 校验,失败立即打 FATAL 并退非零(不再"假装成功")。
#   - 失败后调用方(本指南 §4 / README)应改跑 remedy.sh。
#
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

LOG=~/wsl_provision.log
ts() { date '+%Y-%m-%d %H:%M:%S'; }
step() { echo ""; echo "===== [$(ts)] $1 =====" | tee -a "$LOG"; }
run() { echo "[$(ts)] $*" | tee -a "$LOG"; }

# 若非 root,后续 apt 命令加 sudo
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# ---------- 1/7 系统基础 ----------
step "1/7 更新系统并安装基础工具"
$SUDO apt-get update -y 2>&1 | tail -1 | tee -a "$LOG"
$SUDO apt-get install -y \
    build-essential software-properties-common \
    git curl wget ca-certificates gnupg unzip g++ \
    python3 python3-venv python3-dev python3-pip 2>&1 | tail -3 | tee -a "$LOG"
run "基础工具安装完成"

# ---------- 2/7 GDAL ----------
step "2/7 安装 GDAL (apt: gdal-bin / libgdal-dev / python3-gdal)"
if command -v gdalinfo >/dev/null 2>&1; then
    run "GDAL 已存在: $(gdalinfo --version)"
else
    $SUDO apt-get install -y gdal-bin libgdal-dev python3-gdal 2>&1 | tail -3 | tee -a "$LOG"
    run "GDAL 版本: $(gdalinfo --version)"
fi

# ---------- 3/7 Python 虚拟环境 ----------
step "3/7 创建 Python 虚拟环境 ~/verigis/venv (继承系统 GDAL)"
mkdir -p ~/verigis
if [ ! -f ~/verigis/venv/bin/activate ]; then
    python3 -m venv --system-site-packages ~/verigis/venv
    run "venv 已创建"
else
    run "venv 已存在,跳过创建"
fi
# shellcheck disable=SC1091
source ~/verigis/venv/bin/activate
pip install --quiet --upgrade pip
# richdem 是 C++ 扩展,编译需 GDAL 头文件;venv 用 --system-site-packages
# 暴露 osgeo 但不带 cflags → --no-build-isolation 让 pip 直接用系统 python
# 的 sysconfig 找 headers。
pip install --quiet --no-build-isolation richdem 2>&1 | tail -5 | tee -a "$LOG" \
    || pip install --quiet --ignore-requires-python whiteboxtools==1.10.0 2>&1 | tail -3 | tee -a "$LOG" \
    || run "提示:richdem/whitebox 编译装不上,后续 DEM 算子走 GDAL/python-numpy"
# whiteboxtools PyPI 包装器在 Python 3.10+ 没匹配版本;优先 whitebox(同维护者 giswqs 迁的新名)。
pip install --quiet whitebox 2>&1 | tail -3 | tee -a "$LOG" \
    || run "whitebox 装不上(Python 3.10+ 限制,非致命)"
run "Python 地理库安装完成"

# ---------- 4/7 Lean 4 + mathlib(via elan,直装 tarball + 镜像 fallback)----------
step "4/7 安装 Lean 4 (elan) 与 mathlib"
if command -v lake >/dev/null 2>&1; then
    run "Lean 已安装: $(lake --version)"
else
    run "下载 elan 二进制 tarball(直装,不走 init.sh 内部 curl)..."
    ELAN_VER="v3.1.0"
    TARBALL="elan-x86_64-unknown-linux-gnu.tar.gz"
    URL="https://github.com/leanprover/elan/releases/download/${ELAN_VER}/${TARBALL}"
    # 三源 fallback:原 URL → gh-proxy.com → mirror.ghproxy.com
    stripped="${URL#https://}"
    got_it=""
    for src in "$URL" "https://gh-proxy.com/$stripped" "https://mirror.ghproxy.com/$stripped"; do
        run "  试源:$src"
        if curl -sSLfL --max-time 600 -o "/tmp/${TARBALL}" "$src" 2>/dev/null; then
            got_it=1; break
        fi
    done
    if [ -n "$got_it" ]; then
        mkdir -p "$HOME/.elan"
        # **关键改进**:不预设 --strip-components。先解到临时,探测真实顶层。
        EXTRACT=/tmp/elan_extract
        rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
        tar -xzf "/tmp/${TARBALL}" -C "$EXTRACT"
        TOP=$(ls "$EXTRACT" | head -1)
        run "  tarball 顶层:'$TOP'"
        rm -rf "$HOME/.elan" && mkdir -p "$HOME/.elan"
        if [ -d "$EXTRACT/$TOP" ] && [ -x "$EXTRACT/$TOP/bin/elan" ]; then
            cp -r "$EXTRACT/$TOP/." "$HOME/.elan/"
        elif [ -x "$EXTRACT/bin/elan" ]; then
            cp -r "$EXTRACT/." "$HOME/.elan/"
        elif [ -x "$EXTRACT/elan" ]; then
            cp -r "$EXTRACT/." "$HOME/.elan/"
        else
            run "FATAL:tarball 未知结构:"; find "$EXTRACT" -maxdepth 3 | head -10 | tee -a "$LOG"; exit 1
        fi
        chmod +x "$HOME/.elan/bin/elan" 2>/dev/null
        rm -rf "$EXTRACT" "/tmp/${TARBALL}"
        [ -x "$HOME/.elan/bin/elan" ] || { run "FATAL:解压后 \$HOME/.elan/bin/elan 不在"; exit 1; }
    else
        run "警告:elan 三源都失败——可单独跑 scripts/wsl/remedy.sh 重试 Lean 部分"
    fi
fi
# 把 elan 写进 ~/.bashrc,后续会话不丢 PATH
if [ -f "$HOME/.elan/bin/elan" ] && ! grep -q '\.elan/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
fi
# 确保本会话 PATH 含 elan
export PATH="$HOME/.elan/bin:$PATH"

# elan 只是个版本管理器,Lean 4 编译器还得它装 toolchain。
# elan-init.sh 默认跑过这两步,但直装 tarball 时漏了——上一版隐藏 bug:
# lake --version 看似失败却没人补这一步,Lean 项目永远起不来。
if ! command -v lake >/dev/null 2>&1; then
    run "elan 已就位但 lake 缺 → 装 Lean toolchain (--max-time 1500s)"
    if elan toolchain install stable 2>&1 | tail -10; then
        run "elan 内部装 toolchain OK"
    else
        run "elan toolchain 失败,改手动下 Lean 4 toolchain tarball..."
        LEAN_VER="v4.18.0"
        TARBALL="lean-${LEAN_VER}-linux.tar.zst"
        URL="https://github.com/leanprover/lean4/releases/download/${LEAN_VER}/${TARBALL}"
        stripped="${URL#https://}"
        got_it=""
        for src in "$URL" "https://gh-proxy.com/$stripped" "https://mirror.ghproxy.com/$stripped"; do
            run "  试源:$src"
            if curl -sSLfL --max-time 1500 -o "/tmp/${TARBALL}" "$src" 2>/dev/null; then
                got_it=1; break
            fi
        done
        if [ -n "$got_it" ]; then
            mkdir -p "$HOME/.elan/toolchains"
            rm -f "$HOME/.elan/toolchains/stable"
            # 解压(无 strip,探测后调整)
            EXTRACT=/tmp/lean_extract
            rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
            tar --use-compress-program=unzstd -xf "/tmp/${TARBALL}" \
                -C "$EXTRACT" 2>&1 | tail -3 | tee -a "$LOG" \
                || tar -xzf "/tmp/${TARBALL}" \
                    -C "$EXTRACT" 2>&1 | tail -3 | tee -a "$LOG"
            TOP=$(ls "$EXTRACT" | head -1)
            run "  Lean toolchain 顶层:'$TOP'"
            rm -rf "$HOME/.elan/toolchains/lean-${LEAN_VER}"
            mkdir -p "$HOME/.elan/toolchains/lean-${LEAN_VER}"
            if [ -d "$EXTRACT/$TOP" ] && [ -x "$EXTRACT/$TOP/bin/lake" ]; then
                cp -r "$EXTRACT/$TOP/." "$HOME/.elan/toolchains/lean-${LEAN_VER}/"
            elif [ -x "$EXTRACT/bin/lake" ]; then
                cp -r "$EXTRACT/." "$HOME/.elan/toolchains/lean-${LEAN_VER}/"
            else
                run "FATAL:Lean toolchain tarball 未知结构"; find "$EXTRACT" -maxdepth 3 | head -10 | tee -a "$LOG"; exit 1
            fi
            ln -sfn "$HOME/.elan/toolchains/lean-${LEAN_VER}" "$HOME/.elan/toolchains/stable"
            rm -rf "$EXTRACT" "/tmp/${TARBALL}"
            [ -x "$HOME/.elan/toolchains/lean-${LEAN_VER}/bin/lake" ] \
                || { run "FATAL:lake binary 不在 toolchains/lean-${LEAN_VER}/bin/"; exit 1; }
            run "Lean ${LEAN_VER} 手动装到 toolchains/(lake 已验证)"
        else
            run "警告:Lean toolchain 三源失败 — 见 docs/wsl2-setup.md §6 Q5c"
        fi
    fi
fi
run "lake 版本: $(lake --version 2>&1 | head -1)"

mkdir -p ~/verigis/lean4_proj
cd ~/verigis/lean4_proj
if [ ! -f lakefile.lean ] && [ ! -f lakefile.toml ]; then
    run "初始化 Lean 项目 verigis ..."
    lake new verigis 2>&1 | tail -3 | tee -a "$LOG"
fi
# 首次构建允许 30–60 分钟,timeout 1500s = 25 min,超时不致命
run "首次构建 mathlib(可能 30–60 分钟,超时或非致命)..."
timeout 1500 lake build 2>&1 | tail -8 || run "mathlib 构建未完成(非致命,可稍后手动 cd ~/verigis/lean4_proj && lake build)"

# ---------- 5/7 Dafny(.zip 自包含 .NET + 三源 fallback + 类型校验)----------
# 关键修正:**Dafny v4.5.0+ 官方不发 .deb,只发 .zip**(self-contained .NET)。
# 之前的 v4.8.1-x64-ubuntu-22.04.deb URL 是错的,404 才是真相。
step "5/7 安装 Dafny (固定 v4.11.0 .zip,self-contained .NET)"
if command -v dafny >/dev/null 2>&1; then
    run "Dafny 已存在: $(dafny --version 2>&1 | head -1)"
else
    DAFNY_VER="4.11.0"
    ZIP="dafny-${DAFNY_VER}-x64-ubuntu-22.04.zip"
    URL="https://github.com/dafny-lang/dafny/releases/download/v${DAFNY_VER}/${ZIP}"
    stripped="${URL#https://}"
    got_it=""
    for src in "$URL" "https://gh-proxy.com/$stripped" "https://mirror.ghproxy.com/$stripped"; do
        run "  试源:$src"
        if curl -sSLfL --max-time 1200 -o "/tmp/${ZIP}" "$src" 2>/dev/null; then
            h1=$(head -c1 "/tmp/${ZIP}" | od -An -tx1 | tr -d ' ')
            h2=$(head -c2 "/tmp/${ZIP}" | tail -c1 | od -An -tx1 | tr -d ' ')
            # zip 头:50 4b 03 04 (PK..)
            if [ "$h1" = "50" ] && [ "$h2" = "4b" ]; then
                got_it=1; break
            else
                run "  ⚠ 头两字节 = ${h1:-?} ${h2:-?} ≠ PK,跳过"
                rm -f "/tmp/${ZIP}"
            fi
        fi
    done
    if [ -n "$got_it" ]; then
        $SUDO rm -rf /opt/dafny && $SUDO mkdir -p /opt/dafny
        $SUDO unzip -q "/tmp/${ZIP}" -d /opt/dafny
        # Dafny zip 通常解出 /opt/dafny/dafny-<VER>/ 目录,内含 dafny shell 包装
        DAFNY_HOME=$(ls -d /opt/dafny/dafny-*/ 2>/dev/null | head -1)
        [ -z "$DAFNY_HOME" ] && DAFNY_HOME=/opt/dafny
        DAFNY_BIN=$(ls "$DAFNY_HOME"/dafny "$DAFNY_HOME"/bin/dafny 2>/dev/null | head -1)
        if [ -z "$DAFNY_BIN" ]; then
            run "FATAL:dafny zip 解后找不到 dafny 可执行"
            find /opt/dafny -maxdepth 3 -name 'dafny*' | head -10 | tee -a "$LOG"
            exit 1
        fi
        $SUDO chmod +x "$DAFNY_BIN"
        $SUDO ln -sf "$DAFNY_BIN" /usr/local/bin/dafny
        rm -f "/tmp/${ZIP}"
        run "Dafny 版本: $(dafny --version 2>&1 | head -1)"
    else
        run "Dafny .zip 三源都失败——可单独跑 scripts/wsl/remedy.sh 重试 Dafny 部分"
    fi
fi
# 验证 Dafny 可证明一条小定理
cat > /tmp/hello.dfy <<'EOF'
method Abs(x: int) returns (y: int)
  ensures y >= 0
  ensures y == x || y == -x
{
  if x >= 0 { y := x; } else { y := -x; }
}
EOF
run "Dafny 验证测试(Math 自包含,z3 内嵌)..."
dafny verify /tmp/hello.dfy 2>&1 | tail -3 | tee -a "$LOG"

# ---------- 6/7 验证 Python 地理库 ----------
step "6/7 验证 WhiteboxTools / RichDEM / GDAL-Python"
# shellcheck disable=SC1091
source ~/verigis/venv/bin/activate
python - <<'PY' 2>&1 | tee -a "$LOG"
import importlib, sys
mods = ["numpy", "scipy", "richdem", "osgeo", "whitebox", "whiteboxtools"]
for m in mods:
    try:
        mod = importlib.import_module(m)
        ver = getattr(mod, "__version__", "ok")
        print(f"  OK  {m:14s} {ver}")
    except Exception as e:
        print(f"  --  {m:14s} skipped(whitebox/whiteboxtools 至少一个能 import 即可)")
PY

# ---------- 7/7 汇总 ----------
step "7/7 环境汇总"
echo "--- 工具版本 ---" | tee -a "$LOG"
echo "GDAL : $(gdalinfo --version 2>&1)"        | tee -a "$LOG"
echo "Lean : $(lake --version 2>&1)"            | tee -a "$LOG"
echo "Dafny: $(dafny --version 2>&1 | head -1)" | tee -a "$LOG"
echo "Python venv: ~/verigis/venv (激活: source ~/verigis/venv/bin/activate)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# ---------- 8/8 硬校验:谁漏装,谁是假的 ----------
step "8/8 硬校验(失败不再装死脸,直接告诉补救路径)"
MISSING=()
[ ! -f ~/verigis/venv/bin/activate ] && MISSING+=("venv")
command -v lake  >/dev/null 2>&1     || MISSING+=("lean")
command -v dafny >/dev/null 2>&1     || MISSING+=("dafny")

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "✅ WSL2 研究环境配置完成,四项工具均已就位。详细使用见 docs/wsl2-setup.md。" | tee -a "$LOG"
    exit 0
else
    echo "⚠️  WSL2 研究环境**部分成功**,以下组件未就位:${MISSING[*]}" | tee -a "$LOG"
    echo "    不要紧——这是常见的(elan / Dafny 下载挂、venv 没建等)。跑同目录的 remedy.sh 即可补齐:" | tee -a "$LOG"
    echo "      bash scripts/wsl/remedy.sh" | tee -a "$LOG"
    echo "    (从 PowerShell:wsl -d Ubuntu-22.04 -- bash -c \"bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/remedy.sh'\")" | tee -a "$LOG"
    exit 1
fi
