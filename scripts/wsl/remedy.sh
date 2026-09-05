#!/usr/bin/env bash
#
# remedy.sh — 修补 provision.sh 没装上的三项:Lean 4 / Dafny / Python venv
#
# 同一仓库、同位置、与 provision.sh 共存。能补什么补什么,全部已就位则秒退。
#
# 用法(WSL 内,从仓库根目录):
#   bash scripts/wsl/remedy.sh
#
# 或从 PowerShell(管理员):
#   wsl -d Ubuntu-22.04 -- bash -c "bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/remedy.sh'"
#
# 关键改进(相对原始 provision.sh):
#   1. 先做漏装检查,不重复装已有组件
#   2. elan 下载加 --max-time 600 + 备用 GitHub raw 镜像
#   3. Dafny 走 .zip 链接(自包含 .NET,也是官方唯一 Linux 发布),绕开 GitHub API 限流
#   4. 每步真的失败会打印 FATAL 并 exit 1,不再假装成功
#
set -uo pipefail
LOG=~/wsl_remedy.log
: > "$LOG"          # 每次覆盖,文件不至于无限增长
exec > >(tee -a "$LOG") 2>&1

say()   { printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# 任何 apt 操作前:等锁释放(典型场景 unattended-upgrades 自动跑了 ~16 min)
# fuser 非零 = 锁被占;最多等 5 分钟。卡死时给出明确"kill 这些 PID 解锁"的回退。
wait_for_apt() {
    local tries=0 max=30 pid
    while [ "$tries" -lt "$max" ]; do
        if ! fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock >/dev/null 2>&1; then
            return 0
        fi
        pid=$(fuser /var/lib/dpkg/lock-frontend 2>/dev/null | tr -d ' \n')
        say "apt 锁被 PID ${pid:-?} 占用,等 10s... ($((tries+1))/$max)"
        sleep 10
        tries=$((tries+1))
    done
    say "apt 锁等了 $((max*10))s 仍未释放。手动解锁:"
    say "  sudo systemctl stop unattended-upgrades && sudo kill -9 $pid 2>/dev/null"
    return 1
}

# 通用下载:三源(原 URL → gh-proxy.com → mirror.ghproxy.com)+ 真解析验证。
# 关键改进(相对之前的版本):
#   - **只信 magic bytes**(前 4 字节),不再靠 URL 字符串 case 匹配——
#     上一版 case `*.tar.gz?` 漏了 URL 末尾,elan 永远被判错。
#   - 真解析:gz 用 tar -tzf、zip 用 unzip -l、zst 用 tar --use-compress-program
#     unzstd -tf、deb 查 ar 头,**任意解析失败立刻 continue**。HTML 错误页
#     即便被 gzip 包了,内部 tar 也认不出。
# 用法:download URL OUTPUT_PATH  → echo "路径"
download_with_fallback() {
    local url="$1" out="$2" src
    local stripped="${url#https://}"
    for src in \
        "$url" \
        "https://gh-proxy.com/$stripped" \
        "https://mirror.ghproxy.com/$stripped"; do
        say "    试源: $src"
        if ! curl -sSLfL --max-time 600 -o "$out" "$src" 2>/dev/null; then
            say "      → curl 失败"
            rm -f "$out"; continue
        fi
        [ -s "$out" ] || { say "      → 文件空"; rm -f "$out"; continue; }
        # 取前 4 字节 hex
        local magic
        magic=$(head -c4 "$out" | od -An -tx1 | tr -d ' \n')
        say "      magic: $magic ($(du -h "$out" | cut -f1))"
        case "$magic" in
            "1f8b"*)        # gzip(.tar.gz 主流)
                if first=$(tar -tzf "$out" 2>/dev/null | head -1) && [ -n "$first" ]; then
                    say "      ✅ gzip 真 tar,首项:$first"
                    return 0
                else
                    say "      → gzip magic 但 tar 解析失败(可能 HTML 错误页)"
                    rm -f "$out"; continue
                fi
                ;;
            "504b"*)        # zip(Dafny 走这个)
                if first=$(unzip -l "$out" 2>/dev/null | awk 'NR==4{print $4}') && [ -n "$first" ]; then
                    say "      ✅ zip 真,首项:$first"
                    return 0
                else
                    say "      → zip magic 但 unzip 失败"
                    rm -f "$out"; continue
                fi
                ;;
            "28b52ffd"*|"28b52f"*)   # zstd
                if first=$(tar --use-compress-program=unzstd -tf "$out" 2>/dev/null | head -1) && [ -n "$first" ]; then
                    say "      ✅ zstd 真 tar,首项:$first"
                    return 0
                else
                    say "      → zstd magic 但 tar 解析失败"
                    rm -f "$out"; continue
                fi
                ;;
            "213c"*)        # .deb = ar 归档
                if ar t "$out" 2>/dev/null | head -1 | grep -q '^control.tar'; then
                    say "      ✅ deb ar 归档 OK"
                    return 0
                else
                    say "      → deb magic 但 ar 解析失败"
                    rm -f "$out"; continue
                fi
                ;;
            *)
                say "      → 未知 magic(可能是 HTML 错误页)"
                rm -f "$out"; continue
                ;;
        esac
    done
    say "    FATAL:三源都失败或文件不可解析"
    return 1
}

# ---------- 0. 漏装检查 ----------
say "=== remedy.sh 开始 $(date '+%Y-%m-%d %H:%M:%S') ==="
say "0/5 等 apt 锁释放"
wait_for_apt
say "0/4 漏装检查"

NEED_VENV=0; NEED_LEAN=0; NEED_DAFNY=0
[ -f ~/verigis/venv/bin/activate ]   || NEED_VENV=1
command -v lake  >/dev/null 2>&1     || NEED_LEAN=1
command -v dafny >/dev/null 2>&1     || NEED_DAFNY=1

cat <<EOF | column -t -s'|'
  venv missing  :|$NEED_VENV
  lake missing  :|$NEED_LEAN
  dafny missing :|$NEED_DAFNY
EOF

if [ "$NEED_VENV$NEED_LEAN$NEED_DAFNY" = "000" ]; then
    say "三项全已就位,无需修复,退出。"
    exit 0
fi

# ---------- 1. Python venv(幂等:已存在就验证 + 补装缺的)----------
if [ -f ~/verigis/venv/bin/activate ]; then
    say "1/4 Python venv 已就位,验证包..."
    # shellcheck disable=SC1091
    source ~/verigis/venv/bin/activate
    if ! python -c "import whitebox, whiteboxtools" 2>/dev/null; then
        say "  whitebox/whiteboxtools 缺,补装"
    else
        say "  关键地理包齐全"
        NEED_VENV=0
    fi
fi
if [ "$NEED_VENV" = "1" ]; then
    say "1/4 建 Python venv ~/verigis/venv"
    # unzip 必须在这里就装:Dafny 是 .zip 分发,Ubuntu 最小化安装默认没有
    $SUDO apt-get install -y python3-venv python3-dev g++ unzip 2>&1 | tail -5 \
        || { say "FATAL: python3-venv 装不上,需先解决 apt 源"; exit 1; }

    mkdir -p ~/verigis
    rm -rf ~/verigis/venv          # 清旧(若有)
    python3 -m venv --system-site-packages ~/verigis/venv \
        || { say "FATAL: venv 创建失败"; exit 1; }

    # shellcheck disable=SC1091
    source ~/verigis/venv/bin/activate
fi
# 不管 NEED_VENV 是什么,都跑一遍:幂等,缺啥补啥,已装的秒过
python -m pip install --quiet --upgrade pip setuptools wheel

# richdem 是 C++ 扩展,编译需 GDAL 头文件,venv 用 --system-site-packages
# 暴露 osgeo 但不带 cflags → 必须 --no-build-isolation 用系统 python sysconfig
# 来找 headers。whitebox 是纯 Python 包装器,优先装,失败再 whiteboxtools。
say "  pip 装地理包(numpy/scipy 已就位,补 richdem/whitebox)..."
if python -m pip install --quiet --no-build-isolation richdem 2>&1 | tail -3; then
    say "  richdem OK(--no-build-isolation 编译成功)"
else
    say "  richdem --no-build-isolation 失败,再试一次 + 装编译依赖"
    $SUDO apt-get install -y libgdal-dev g++ 2>&1 | tail -3
    python -m pip install --quiet --no-build-isolation richdem 2>&1 | tail -3 \
        || say "  警告:richdem 编译失败,GDAL/osgeo 已可用于 DEM 算子"
fi
# whitebox / whiteboxtools:Python 3.10+ PyPI 版本限定冲突,通常装不上,
# 接受 warning(走 GDAL/RichDEM 兜底),不阻塞主线。
if python -m pip install --quiet whitebox 2>&1 | tail -2; then
    say "  whitebox OK"
else
    say "  whitebox 装不上(Python 3.10+ PyPI 限制,非致命)"
fi
say "venv OK: $(python -c 'import sys; print(sys.prefix)')"

# ---------- 2. Lean 4 via elan(直装 tarball,绕开 init.sh 内部 curl)----------
if [ "$NEED_LEAN" = "1" ]; then
    say "2/4 装 Lean 4(via elan,直装 tarball)"
    # elan-init.sh 内部还会 curl 拉 tarball,在被限制的网络里容易卡。
    # 我们直接拿 elan 的预编译 tarball 解压,完全跳过 init 流程。
    ELAN_VER="v3.1.0"
    TARBALL="elan-x86_64-unknown-linux-gnu.tar.gz"
    URL="https://github.com/leanprover/elan/releases/download/${ELAN_VER}/${TARBALL}"
    say "  下载 elan ${ELAN_VER}..."
    if download_with_fallback "$URL" "/tmp/${TARBALL}"; then
        # 关键:**不预设顶层结构**。先解到 /tmp/elan_extract,探测真实顶层。
        # 上轮 bug:--strip-components=1 假设顶层是 elan-x86_64-unknown-linux-gnu/,
        # 实际若顶层就是 bin/,strip 会全删掉,--strip 后 .elan/ 变空目录。
        EXTRACT=/tmp/elan_extract
        rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
        tar -xzf "/tmp/${TARBALL}" -C "$EXTRACT" || {
            say "FATAL: tar 解压失败,说明下载文件被污染或不算 gzip"; exit 1; }
        # 探测顶层
        TOP=$(ls "$EXTRACT" | head -1)
        say "  tarball 顶层:'$TOP'"
        # 三种情况都支持:整个顶层目录 / 直接 bin+share / 单文件
        rm -rf "$HOME/.elan"
        mkdir -p "$HOME/.elan"
        if [ -d "$EXTRACT/$TOP" ] && [ -x "$EXTRACT/$TOP/bin/elan" ]; then
            # 情况 A:顶层是包装目录,内含 bin/elan(elan 主流发布)
            cp -r "$EXTRACT/$TOP/." "$HOME/.elan/"
        elif [ -x "$EXTRACT/bin/elan" ]; then
            # 情况 B:顶层直接是 bin/(少数特殊情况)
            cp -r "$EXTRACT/." "$HOME/.elan/"
        elif [ -x "$EXTRACT/elan" ]; then
            # 情况 C:顶层是单文件(legacy)
            cp -r "$EXTRACT/." "$HOME/.elan/"
        else
            say "FATAL: tarball 未知结构,find 出的内容:"
            find "$EXTRACT" -maxdepth 3 | head -10
            exit 1
        fi
        chmod +x "$HOME/.elan/bin/elan" 2>/dev/null
        rm -rf "$EXTRACT" "/tmp/${TARBALL}"
        # 真验证:**elan binary 必须在磁盘上且可执行**
        if [ ! -x "$HOME/.elan/bin/elan" ]; then
            say "FATAL: 解压后 \$HOME/.elan/bin/elan 不存在或不可执行"
            say "  ls 实际:"
            ls -laR "$HOME/.elan" | head -20
            exit 1
        fi
        say "  elan 解压验证通过:$HOME/.elan/bin/elan"
        "$HOME/.elan/bin/elan" --version
    else
        say "FATAL: elan 三源都下载失败。"
        say "  手动方案(任选其一):"
        say "    1. 换网(手机热点 / VPN)后重跑本脚本"
        say "    2. 在能上 GitHub 的设备下载 ${TARBALL},拷到 WSL 后:"
        say "         bash scripts/wsl/remedy.sh"
        exit 1
    fi
else
    say "2/4 lake 已就位,跳过 elan"
fi
export PATH="$HOME/.elan/bin:$PATH"
# 把 elan 装进 ~/.bashrc,后续会话自动可用
if [ -f "$HOME/.elan/bin/elan" ] && ! grep -q '\.elan/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
fi

# 关键差距:elan 只是个版本管理器,Lean 4 toolchain 还要再拉。
# elan-init.sh 默认会跑 `elan toolchain install stable` + `elan default stable`,
# 我们直装 tarball 跳过了它——lake 自然找不到,这是上一版的隐藏 bug。
if ! command -v lake >/dev/null 2>&1; then
    say "  elan 已装,但 lake 缺失 → 拉 Lean 4 toolchain (--max-time 1500s ~ 25 min)"
    say "    试 'elan toolchain install stable'(优先,内部走 GitHub + cache)"
    if elan toolchain install stable 2>&1 | tail -10; then
        elan default stable 2>&1 | tail -3
    else
        # 手动 fallback:从 gh-proxy.com 拉 Lean 4 toolchain tarball
        # Lean 4 toolchain 命名:**最新稳定版 lean4 v4.18.0 的 linux tarball
        # 不一定叫 'lean-${VER}-linux.tar.zst'。事实上 Lean 4 GitHub
        # release 资产名是 lean-4.18.0-linux.tar.zst(没有 v 前缀)
        LEAN_VER="4.18.0"        # 注意不带 v 前缀(资产名习惯)
        TARBALL="lean-${LEAN_VER}-linux.tar.zst"
        URL="https://github.com/leanprover/lean4/releases/download/v${LEAN_VER}/${TARBALL}"
        say "    备援 Lean toolchain download: $URL"
        say "    (注:v4.18.0 在 2024-Q4 发布;最新稳定可在 lean4 release 页查)"
        if download_with_fallback "$URL" "/tmp/${TARBALL}"; then
            rm -rf "$HOME/.elan/toolchains"
            mkdir -p "$HOME/.elan/toolchains"
            # 先解到 /tmp/lean_extract 探测真实顶层(Lean 4 release 资产
            # 命名不固定:lean-4.18.0-linux.tar.zst 顶层是 lean-4.18.0-linux/,
            # 但其它版本可能直接平铺 bin/+lib/+,不能预设 strip)
            EXTRACT=/tmp/lean_extract
            rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
            tar --use-compress-program=unzstd -xf "/tmp/${TARBALL}" -C "$EXTRACT" \
                || tar -xzf "/tmp/${TARBALL}" -C "$EXTRACT"
            TOP=$(ls "$EXTRACT" | head -1)
            say "    tarball 顶层:'$TOP'"
            mkdir -p "$HOME/.elan/toolchains/lean-${LEAN_VER}"
            if [ -x "$EXTRACT/$TOP/bin/lake" ]; then
                # 顶层是包装目录(常见)
                cp -r "$EXTRACT/$TOP/." "$HOME/.elan/toolchains/lean-${LEAN_VER}/"
            elif [ -x "$EXTRACT/bin/lake" ]; then
                # 顶层直接 bin/(少数情况)
                cp -r "$EXTRACT/." "$HOME/.elan/toolchains/lean-${LEAN_VER}/"
            else
                say "FATAL: lean toolchain 解后找不到 bin/lake,实际:"
                find "$EXTRACT" -maxdepth 3 -type f | head -10
                exit 1
            fi
            ln -sfn "$HOME/.elan/toolchains/lean-${LEAN_VER}" "$HOME/.elan/toolchains/stable"
            rm -rf "$EXTRACT" "/tmp/${TARBALL}"
            # 真验证:lake binary 必须在磁盘上
            if [ ! -x "$HOME/.elan/toolchains/lean-${LEAN_VER}/bin/lake" ]; then
                say "FATAL: lean toolchain 解后 bin/lake 不存在,看实际结构:"
                find "$HOME/.elan/toolchains/lean-${LEAN_VER}" -maxdepth 3 -type f | head -10
                exit 1
            fi
            say "    手动装 Lean $LEAN_VER 到 toolchains/lean-${LEAN_VER}"
        else
            say "FATAL: Lean toolchain 三源都失败。手动:"
            say "  1. 浏览器下 'lean-x86_64-linux.tar.zst' from https://github.com/leanprover/lean4/releases"
            say "  2. 解到 ~/.elan/toolchains/lean-<VER>/ 并 ln -s 到 ~/.elan/toolchains/stable"
            say "  3. 重跑本脚本"
            exit 1
        fi
    fi
fi
command -v lake >/dev/null 2>&1 \
    || { say "FATAL: lake 仍未找到,所有路径都试过"; exit 1; }
say "lake: $(lake --version 2>&1 | head -1)"

# ---------- 3. Dafny(走 .zip + 镜像)----------
# 关键修正:**Dafny v4.5.0+ 官方不发 .deb,只发 .zip**(self-contained .NET)。
# 之前的 v4.8.1-x64-ubuntu-22.04.deb URL 是错的——404 才是真相。
# 当前最新稳定:v4.11.0(2025-08-25 发布),资产:
#   dafny-4.11.0-x64-ubuntu-22.04.zip  (Linux x64 ubuntu-22.04 自包含)
if [ "$NEED_DAFNY" = "1" ]; then
    say "3/4 装 Dafny 4.11.0(.zip 直解压)"
    DAFNY_VER="4.11.0"
    ZIP="dafny-${DAFNY_VER}-x64-ubuntu-22.04.zip"
    URL="https://github.com/dafny-lang/dafny/releases/download/v${DAFNY_VER}/${ZIP}"
    say "  下载 $URL (走镜像 fallback,类型校验 zip PK..)"
    if download_with_fallback "$URL" "/tmp/${ZIP}"; then
        $SUDO rm -rf /opt/dafny
        $SUDO mkdir -p /opt/dafny
        $SUDO unzip -q "/tmp/${ZIP}" -d /opt/dafny
        # Dafny zip 解到 /opt/dafny/dafny-{VER}/ 目录,顶层是 bin/z3/dafny 等
        # 但最常见是直接平铺。探测后做符号链。
        DAFNY_HOME=$(ls -d /opt/dafny/dafny-*/ 2>/dev/null | head -1)
        [ -z "$DAFNY_HOME" ] && DAFNY_HOME=/opt/dafny
        DAFNY_BIN=$(ls "$DAFNY_HOME"/dafny "$DAFNY_HOME"/bin/dafny 2>/dev/null | head -1)
        if [ -z "$DAFNY_BIN" ]; then
            say "FATAL: dafny zip 解后找不到 dafny 可执行"
            find /opt/dafny -maxdepth 3 -name 'dafny*' -type f | head -5
            exit 1
        fi
        $SUDO chmod +x "$DAFNY_BIN"
        $SUDO ln -sf "$DAFNY_BIN" /usr/local/bin/dafny
        rm -f "/tmp/${ZIP}"
    else
        say "FATAL: Dafny 三源都失败。手动方案:"
        say "  1. 浏览器下 ${ZIP} from https://github.com/dafny-lang/dafny/releases/tag/v${DAFNY_VER}"
        say "  2. 拷到 WSL:/tmp/${ZIP},再跑本脚本"
        say "  3. 或在有网的容器装好后带回 Dafny 目录"
        exit 1
    fi
else
    say "3/4 dafny 已就位,跳过"
fi
command -v dafny >/dev/null 2>&1 \
    || { say "FATAL: dafny 仍未找到"; exit 1; }
say "dafny: $(dafny --version 2>&1 | head -1)"

# ---------- 4. mathlib 项目脚手架(非致命)----------
say "4/4 准备 Lean 项目 ~/verigis/lean4_proj(供后续写证明用)"
mkdir -p ~/verigis/lean4_proj
cd ~/verigis/lean4_proj
export PATH="$HOME/.elan/bin:$PATH"
if [ ! -f lakefile.lean ]; then
    lake new verigis 2>&1 | tail -5 \
        || say "  lake new 失败(项目可手动 cd 后再试)"
fi
# 若项目就绪但未拉 mathlib,挂上(避免长时间阻塞,只挂不拉)
if [ -f lakefile.lean ] && ! grep -q 'mathlib' lakefile.lean; then
    cat >> lakefile.lean <<'EOF'

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"@"master"
EOF
    say "  mathlib 依赖已写进 lakefile.lean。首次 lake build 仍需 30–60 min,请手动执行:"
    say "    export PATH=\"\$HOME/.elan/bin:\$PATH\""
    say "    cd ~/verigis/lean4_proj && lake build"
else
    say "  Lean 项目结构已存在,跳过 scaffold"
fi

# ---------- 验证汇总 ----------
say "===== 最终验证 ====="
# shellcheck disable=SC1091
source ~/verigis/venv/bin/activate
# 在新名称和老名称之间二选一;两边都试,谁成算谁
python - <<'PY'
import importlib, sys
for m in ["numpy", "scipy", "richdem", "osgeo"]:
    try:
        v = getattr(importlib.import_module(m), "__version__", "ok")
        print(f"  OK   {m:14s} {v}")
    except Exception as e:
        print(f"  FAIL {m:14s} {e}")
# 地形分析后端,二选一:新 whitebox 或旧 whiteboxtools
for m in ["whitebox", "whiteboxtools"]:
    try:
        importlib.import_module(m); print(f"  OK   {m:14s} (选了这个)")
        sys.modules["__wb__"] = importlib.import_module(m); break
    except ImportError:
        print(f"  -    {m:14s} 跳过")
else:
    print("  WARN 都没有 whitebox / whiteboxtools,后续 DEM 算子脚本走 GDAL/RichDEM")
PY

printf "  %-22s %s\n" "gdalinfo :"  "$(gdalinfo --version 2>&1)"
printf "  %-22s %s\n" "lake     :"  "$(lake --version 2>&1 | head -1)"
printf "  %-22s %s\n" "dafny    :"  "$(dafny --version 2>&1 | head -1)"
printf "  %-22s %s\n" "venv     :"  "$(python -c 'import sys; print(sys.prefix)' 2>&1)"

# 跑一条 dafny 小定理验证可证明性
cat > /tmp/hello.dfy <<'EOF'
method Abs(x: int) returns (y: int)
  ensures y >= 0
  ensures y == x || y == -x
{ if x >= 0 { y := x; } else { y := -x; } }
EOF
say "  dafny 验证 sample:"
dafny verify /tmp/hello.dfy 2>&1 | tail -3

say "✅ remedy.sh 完成 $(date '+%Y-%m-%d %H:%M:%S')"
say "日志:~/wsl_remedy.log"
