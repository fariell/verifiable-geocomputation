#!/usr/bin/env bash
#
# provision.sh — 在 WSL2 (Ubuntu 22.04) 内一键安装研究环境
#
# 安装内容:
#   - 系统基础工具 (build-essential, git, curl, python3-venv ...)
#   - GDAL 3.4 (gdal-bin + libgdal-dev + python3-gdal)
#   - Python 虚拟环境 ~/verigis/venv (继承系统 GDAL),含 numpy/scipy/whiteboxtools/richdem
#   - Lean 4 + mathlib (via elan)
#   - Dafny (最新 release, ubuntu-22.04 自包含构建)
#
# 用法(在 Windows PowerShell 中执行,路径按需修改):
#   wsl -d Ubuntu-22.04 -- bash -c "sudo bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/provision.sh'"
#
# 说明:
#   - 幂等:重复运行不会重复安装已存在的组件。
#   - mathlib 首次构建需要 30–60 分钟,脚本不阻塞,失败会记为"非致命"并继续。
#   - 日志同时写入 ~/wsl_provision.log。
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
pip install --quiet numpy scipy whiteboxtools richdem 2>&1 | tail -5 | tee -a "$LOG"
run "Python 地理库安装完成"

# ---------- 4/7 Lean 4 + mathlib ----------
step "4/7 安装 Lean 4 (elan) 与 mathlib"
if command -v lake >/dev/null 2>&1; then
    run "Lean 已安装: $(lake --version)"
else
    run "下载并安装 elan (Lean 版本管理器) ..."
    curl -sSf https://elan.lean-lang.org/elan-init.sh | sh -s -- -y --default-toolchain stable 2>&1 | tail -3 | tee -a "$LOG"
fi
# 确保本会话 PATH 含 elan
export PATH="$HOME/.elan/bin:$PATH"
run "lake 版本: $(lake --version 2>&1)"

mkdir -p ~/verigis/lean4_proj
cd ~/verigis/lean4_proj
if [ ! -f lakefile.toml ]; then
    run "初始化 Lean 项目 verigis ..."
    lake new . --name verigis >/dev/null 2>&1 || lake new verigis >/dev/null 2>&1
fi
run "拉取 mathlib (lake update) ..."
lake update 2>&1 | tail -3 | tee -a "$LOG"
run "首次构建 mathlib(可能 30–60 分钟,超时或非致命)..."
timeout 1500 lake build 2>&1 | tail -8 || run "mathlib 构建未完成(非致命,可稍后手动 cd ~/verigis/lean4_proj && lake build"

# ---------- 5/7 Dafny ----------
step "5/7 安装 Dafny (最新 release, ubuntu-22.04 自包含构建)"
if command -v dafny >/dev/null 2>&1; then
    run "Dafny 已存在: $(dafny --version 2>&1 | head -1)"
else
    ver=$(curl -s https://api.github.com/repos/dafny-lang/dafny/releases/latest | grep -oP '"tag_name": "\K[^"]+')
    [ -z "$ver" ] && ver="v4.8.1"
    url="https://github.com/dafny-lang/dafny/releases/download/${ver}/dafny-${ver}-x64-ubuntu-22.04.zip"
    run "下载 Dafny $ver ..."
    tmp=$(mktemp -d)
    curl -sSL "$url" -o "$tmp/dafny.zip"
    $SUDO mkdir -p /opt/dafny
    $SUDO unzip -o "$tmp/dafny.zip" -d /opt/dafny >/dev/null
    $SUDO ln -sf /opt/dafny/dafny /usr/local/bin/dafny
    rm -rf "$tmp"
    run "Dafny 版本: $(dafny --version 2>&1 | head -1)"
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
mods = ["numpy", "scipy", "whiteboxtools", "richdem", "osgeo"]
for m in mods:
    try:
        mod = importlib.import_module(m)
        ver = getattr(mod, "__version__", "ok")
        print(f"  OK  {m:14s} {ver}")
    except Exception as e:
        print(f"  FAIL {m:14s} {e}")
PY

# ---------- 7/7 汇总 ----------
step "7/7 环境汇总"
echo "--- 工具版本 ---" | tee -a "$LOG"
echo "GDAL : $(gdalinfo --version 2>&1)"        | tee -a "$LOG"
echo "Lean : $(lake --version 2>&1)"            | tee -a "$LOG"
echo "Dafny: $(dafny --version 2>&1 | head -1)" | tee -a "$LOG"
echo "Python venv: ~/verigis/venv (激活: source ~/verigis/venv/bin/activate)" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "✅ WSL2 研究环境配置完成。详细排错见 docs/wsl2-setup.md" | tee -a "$LOG"
