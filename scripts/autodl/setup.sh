#!/usr/bin/env bash
# scripts/autodl/setup.sh
# -----------------------------------------------------------------------------
# 在 AutoDL 实例里首次装机 — Lean 4.18 + Dafny 4.11 + GDAL/Python + clone 仓 + 冒烟
# 适用:autoDL Ubuntu 22.04 + PyTorch 2.5.1 + CUDA 12.4 镜像(autodl-rental.md §二)
# 由 PI 在本机用 sshpass 包装,一行启动:
#   sshpass -f ~/.autodl_pwd ssh -p <your-autoDL-port> root@<your-autoDL-host> \
#       'bash -s' < scripts/autodl/setup.sh
# 零本地凭据,所有密码都从 ssh 通道过。
# -----------------------------------------------------------------------------

set -uo pipefail   # 不带 -e:mathlib 首次构建允许非致命超时

# ---- 日志全开 ----
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$HOME/.workbuddy"
LOG="$LOG_DIR/setup_${RUN_ID}.log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG") 2>&1
echo "============================================================"
echo "AutoDL setup START @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "LOG : $LOG"
echo "============================================================"

# ---- 0. 工具链盘点(开始前) ----
echo "==[0/7] 起点盘点 =="
for t in curl wget git unzip python3; do
    command -v "$t" >/dev/null && echo "  ✅ $t  $(command -v $t)" \
                              || echo "  ❌ $t  not in PATH"
done

# ---- 1. apt 基础工具 ----
echo "==[1/7] apt 基础工具 =="
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq 2>&1 | tail -5
sudo apt-get install -y -qq \
    unzip git curl wget build-essential pkg-config \
    python3-venv python3-pip python3-dev \
    libgdal-dev gdal-bin zstd \
    2>&1 | tail -10 || true
echo "  ℹ apt 完成(unzip/git/curl/wget/gdal-bin/zstd)"

# ---- 2. Lean 4.18 (走 elan;云端网好,直接装最简版本) ----
echo "==[2/7] Lean 4.18 via elan =="
if command -v lean >/dev/null 2>&1 && command -v lake >/dev/null 2>&1; then
    echo "  ⏭  已装(lean $(lean --version | head -1)),跳过"
else
    curl -sSf https://elan.lean-lang.org/elan-init.sh \
        | sh -s -- -y --default-toolchain lean-4.18.0 2>&1 | tail -10
    # 注入到当前 shell (source 完才生效)
    if [ -f "$HOME/.elan/env" ]; then
        . "$HOME/.elan/env"
    fi
fi
if command -v lean >/dev/null 2>&1; then
    echo "  ✅ lean $(lean --version | head -1)"
    echo "  ✅ lake $(lake --version)"
else
    echo "  ❌ lean 仍不可用,后续步骤会跳过 lake build"
fi

# ---- 3. Dafny 4.11.0 (.zip 解 /opt/dafny) ----
echo "==[3/7] Dafny 4.11.0 =="
if command -v dafny >/dev/null 2>&1; then
    echo "  ⏭  已装 ($(dafny --version | head -1)),跳过"
else
    DAFNY_TMP="/tmp/dafny_$$.zip"
    # wget 走 GitHub release 直链(云端网好)
    wget -q --timeout=120 "https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip" \
         -O "$DAFNY_TMP"
    if [ ! -s "$DAFNY_TMP" ]; then
        echo "  ❌ 下载失败(或空文件),跳过 Dafny"
    else
        # 解到 /tmp 先看顶层目录名
        TOPDIR=$(unzip -q "$DAFNY_TMP" -d /tmp && ls /tmp | grep -i dafny | head -1)
        [ -z "$TOPDIR" ] && TOPDIR="dafny"
        sudo mkdir -p /opt/dafny
        sudo cp -r "/tmp/$TOPDIR/." /opt/dafny/
        sudo chmod -R +x /opt/dafny
        sudo ln -sf /opt/dafny/dafny /usr/local/bin/dafny
        rm -f "$DAFNY_TMP"
    fi
fi
if command -v dafny >/dev/null 2>&1; then
    echo "  ✅ dafny $(dafny --version | head -1)"
else
    echo "  ❌ dafny 不可用,后续 dafny verify 会失败"
fi

# ---- 4. Python venv + 地理包 ----
echo "==[4/7] Python venv ~/verigis/venv =="
if [ -d "$HOME/verigis/venv" ]; then
    echo "  ⏭  已存在,跳过创建"
else
    python3 -m venv --system-site-packages ~/verigis/venv
    ~/verigis/venv/bin/pip install --quiet --upgrade pip
    ~/verigis/venv/bin/pip install --quiet numpy scipy osgeo
fi
# shellcheck disable=SC1091
source ~/verigis/venv/bin/activate
python -c 'import numpy, scipy, osgeo; print("  ✅ numpy", numpy.__version__, "scipy", scipy.__version__)'

# ---- 5. Clone 本仓(若不存在) ----
echo "==[5/7] 本仓 ~/verigis/repo =="
REPO="$HOME/verigis/repo"
if [ -d "$REPO/.git" ]; then
    echo "  ⏭  已存在,跳过 clone(可手动 git pull 更新)"
    (cd "$REPO" && git fetch --quiet 2>&1 | tail -3) || true
else
    git clone --depth=1 https://github.com/fariell/verifiable-geocomputation.git "$REPO" 2>&1 | tail -5
fi

# ---- 6. 跑冒烟(Dafny Abs + Lean mathlib 暖机) ----
echo "==[6/7] 冒烟测试 =="
# 6a) Dafny Abs 冒烟 — 写到一个临时 .dfy
cat > /tmp/SmokeAbs.dfy <<'EOF'
method Abs(x: int) returns (y: int)
  ensures 0 <= y
  ensures y == x || y == -x
{
  if x < 0 { return -x; } else { return x; }
}
EOF
if command -v dafny >/dev/null 2>&1; then
    dafny verify /tmp/SmokeAbs.dfy 2>&1 | tail -5
else
    echo "  ⏭  跳过(Dafny 未装)"
fi

# 6b) Lean mathlib 暖机 — 首次 30-60 min,不强求完成
if command -v lake >/dev/null 2>&1; then
    cd "$REPO/formal/lean4"
    echo "  ℹ  开始 lake update + lake build(首次 30-60 min,允许超时)"
    timeout 1500 bash -c 'lake update && lake build' 2>&1 | tail -20 || \
        echo "  ⚠️  lake build 未在 25 min 内完成 — 这不是错误,mathlib 首次编译就是这样,下次续即可"
fi

# ---- 7. 终态盘点(用户读这里) ----
echo "==[7/7] 终态盘点 =="
for t in curl wget git unzip python3 pip3 lean lake dafny unzip gdalinfo; do
    if command -v "$t" >/dev/null 2>&1; then
        V=$("$t" --version 2>/dev/null | head -1 | sed 's/^/ /')
        echo "  ✅ $t  $(command -v $t) $V"
    else
        echo "  ❌ $t  not in PATH"
    fi
done
echo "  📁 Repo: $REPO"
echo "  📁 venv: $HOME/verigis/venv"
echo "  📁 装包日志原档: $LOG"

echo "============================================================"
echo "AutoDL setup DONE  @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
