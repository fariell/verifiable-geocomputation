#!/usr/bin/env bash
# scripts/autodl/setup.sh
# -----------------------------------------------------------------------------
# 在 AutoDL 实例里首次装机 — Lean 4.18 + Dafny 4.11 + 冒烟
# 可重入:lean/dafny 已装则跳过。失败时以非 0 退出(不要再伪装 rc=0)。
#
# AutoDL 容器要点(2026-09-06 实测):
#   - 已是 root,没有 sudo
#   - github.com:443 直连会超时;必须 source /etc/network_turbo
# -----------------------------------------------------------------------------

set -uo pipefail   # 不带 -e:mathlib 首次构建允许非致命超时

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$HOME/.workbuddy"
LOG="$LOG_DIR/setup_${RUN_ID}.log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG") 2>&1
echo "============================================================"
echo "AutoDL setup START @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "LOG : $LOG"
echo "============================================================"

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "  ❌ 需要 root 或 sudo: $*"
        return 1
    fi
}

github_fetch() {
    local url="$1" dest="$2"
    local mirrors=(
        "$url"
        "https://ghfast.top/$url"
        "https://ghproxy.net/$url"
    )
    local u
    rm -f "$dest"
    for u in "${mirrors[@]}"; do
        echo "  ℹ GET $u"
        if curl -fL --connect-timeout 20 --retry 2 --retry-delay 2 -o "$dest" "$u" \
            && [ -s "$dest" ]; then
            echo "  ✅ 下载完成 $(wc -c < "$dest") bytes"
            return 0
        fi
        rm -f "$dest"
    done
    echo "  ❌ 所有镜像都失败: $url"
    return 1
}

# ---- 0. 起点盘点 ----
echo "==[0/7] 起点盘点 =="
echo "  ℹ uid=$(id -u) user=$(id -un) sudo=$(command -v sudo || echo none)"
for t in curl wget git unzip python3; do
    command -v "$t" >/dev/null && echo "  ✅ $t  $(command -v $t)" \
                              || echo "  ❌ $t  not in PATH"
done

# ---- 1. apt(不要走 GitHub 代理,用发行版源) ----
echo "==[1/7] apt 基础工具 =="
export DEBIAN_FRONTEND=noninteractive
http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY= as_root apt-get update -qq 2>&1 | tail -5
http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY= as_root apt-get install -y -qq \
    unzip git curl wget build-essential pkg-config \
    python3-venv python3-pip python3-dev \
    libgdal-dev gdal-bin zstd \
    2>&1 | tail -10 || true
echo "  ℹ apt 完成(unzip/git/curl/wget/gdal-bin/zstd)"

# ---- 1.5 GitHub 学术加速(elan / Dafny / mathlib 都要) ----
if [ -f /etc/network_turbo ]; then
    # shellcheck disable=SC1091
    . /etc/network_turbo
    echo "  ℹ 已 source /etc/network_turbo  https_proxy=${https_proxy:-unset}"
else
    echo "  ⚠️  没有 /etc/network_turbo,将试 ghfast/ghproxy 镜像"
fi

# ---- 2. Lean 4.18 via elan ----
echo "==[2/7] Lean 4.18 via elan =="
if [ -f "$HOME/.elan/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.elan/env"
fi
if command -v lean >/dev/null 2>&1 && command -v lake >/dev/null 2>&1; then
    echo "  ⏭  已装(lean $(lean --version | head -1)),跳过"
else
    if curl -sSf --connect-timeout 20 https://elan.lean-lang.org/elan-init.sh \
        | sh -s -- -y --default-toolchain lean-4.18.0 2>&1 | tail -20; then
        :
    else
        echo "  ⚠️  elan-init 直连失败,改下安装器 tar.gz"
        if github_fetch \
            "https://github.com/leanprover/elan/releases/latest/download/elan-x86_64-unknown-linux-gnu.tar.gz" \
            /tmp/elan.tar.gz; then
            mkdir -p /tmp/elan_unpack
            tar -xzf /tmp/elan.tar.gz -C /tmp/elan_unpack
            ELAN_BIN=$(find /tmp/elan_unpack -type f -name 'elan-init' -o -name 'elan' | head -1)
            if [ -n "$ELAN_BIN" ]; then
                chmod +x "$ELAN_BIN"
                "$ELAN_BIN" -y --default-toolchain lean-4.18.0 2>&1 | tail -20 || true
            fi
        fi
    fi
    if [ -f "$HOME/.elan/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.elan/env"
        grep -q 'elan/env' "$HOME/.bashrc" 2>/dev/null \
            || echo '. "$HOME/.elan/env"' >> "$HOME/.bashrc"
    fi
fi
if command -v lean >/dev/null 2>&1; then
    echo "  ✅ lean $(lean --version | head -1)"
    echo "  ✅ lake $(lake --version)"
else
    echo "  ❌ lean 仍不可用,后续步骤会跳过 lake build"
fi

# ---- 3. Dafny 4.11.0 ----
echo "==[3/7] Dafny 4.11.0 =="
if [ -x /usr/local/bin/dafny ] || [ -x /opt/dafny/dafny ]; then
    export PATH="/usr/local/bin:/opt/dafny:$PATH"
fi
if command -v dafny >/dev/null 2>&1; then
    echo "  ⏭  已装 ($(dafny --version | head -1)),跳过"
else
    DAFNY_ZIP="/tmp/dafny-4.11.0.zip"
    DAFNY_URL="https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip"
    if github_fetch "$DAFNY_URL" "$DAFNY_ZIP"; then
        rm -rf /tmp/dafny_unpack
        mkdir -p /tmp/dafny_unpack
        unzip -q "$DAFNY_ZIP" -d /tmp/dafny_unpack
        as_root mkdir -p /opt/dafny
        as_root cp -a /tmp/dafny_unpack/. /opt/dafny/
        DAFNY_BIN=$(find /opt/dafny /tmp/dafny_unpack -type f -name dafny | head -1)
        if [ -n "$DAFNY_BIN" ]; then
            as_root chmod +x "$DAFNY_BIN"
            as_root ln -sf "$DAFNY_BIN" /usr/local/bin/dafny
            export PATH="/usr/local/bin:$PATH"
        else
            echo "  ❌ zip 里找不到 dafny 可执行文件"
            find /tmp/dafny_unpack -maxdepth 3 | head -20
        fi
        rm -f "$DAFNY_ZIP"
    fi
fi
if command -v dafny >/dev/null 2>&1; then
    echo "  ✅ dafny $(dafny --version | head -1)"
else
    echo "  ❌ dafny 不可用,后续 dafny verify 会失败"
fi

# ---- 4. Python venv(W1 不强制 osgeo;包名是 gdal 不是 osgeo) ----
echo "==[4/7] Python venv ~/verigis/venv =="
if [ -d "$HOME/verigis/venv" ]; then
    echo "  ⏭  venv 已存在"
else
    python3 -m venv --system-site-packages ~/verigis/venv
fi
~/verigis/venv/bin/pip install --quiet --upgrade pip
~/verigis/venv/bin/pip install --quiet numpy scipy || true
# shellcheck disable=SC1091
source ~/verigis/venv/bin/activate
python -c 'import numpy, scipy; print("  ✅ numpy", numpy.__version__, "scipy", scipy.__version__)' \
    || echo "  ⚠️  numpy/scipy 未就绪"
python -c 'import osgeo; print("  ✅ osgeo ok")' 2>/dev/null \
    || echo "  ⚠ osgeo/GDAL Python 绑定未装 — W1 形式化不阻塞,有 gdalinfo 即可"

# ---- 5. 本仓 ----
echo "==[5/7] 本仓 ~/verigis/repo =="
REPO="$HOME/verigis/repo"
if [ -d "$REPO/.git" ]; then
    echo "  ⏭  已是 git clone,跳过"
    (cd "$REPO" && git fetch --quiet 2>&1 | tail -3) || true
elif [ -f "$REPO/formal/dafny/P002_pit_filling.dfy" ] || [ -f "$REPO/formal/lean4/VeriGIS.lean" ]; then
    echo "  ⏭  已有 sync_push overlay、但还没有 .git — 跳过 clone"
else
    mkdir -p "$(dirname "$REPO")"
    git clone --depth=1 https://github.com/fariell/verifiable-geocomputation.git "$REPO" 2>&1 | tail -5
fi

# ---- 6. 冒烟 ----
echo "==[6/7] 冒烟测试 =="
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

if command -v lake >/dev/null 2>&1; then
    cd "$REPO/formal/lean4"
    echo "  ℹ  开始 lake update + lake build(首次 30-60 min,允许超时)"
    timeout 1500 bash -c 'lake update && lake build' 2>&1 | tail -20 || \
        echo "  ⚠️  lake build 未在 25 min 内完成 — 这不是错误,mathlib 首次编译就是这样,下次续即可"
fi

# ---- 7. 终态盘点 ----
echo "==[7/7] 终态盘点 =="
FAIL=0
for t in curl wget git unzip python3 pip3 lean lake dafny gdalinfo; do
    if command -v "$t" >/dev/null 2>&1; then
        V=$("$t" --version 2>/dev/null | head -1 | sed 's/^/ /')
        echo "  ✅ $t  $(command -v $t) $V"
    else
        echo "  ❌ $t  not in PATH"
        case "$t" in
            lean|lake|dafny) FAIL=1 ;;
        esac
    fi
done
echo "  📁 Repo: $REPO"
echo "  📁 venv: $HOME/verigis/venv"
echo "  📁 装包日志原档: $LOG"
if [ "$FAIL" -ne 0 ]; then
    echo "============================================================"
    echo "AutoDL setup FAILED @ $(date '+%Y-%m-%d %H:%M:%S')  (lean/dafny 未就绪)"
    echo "============================================================"
    exit 1
fi
echo "============================================================"
echo "AutoDL setup DONE  @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
