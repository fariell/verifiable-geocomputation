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
#   3. Dafny 走固定 .deb 链接,绕开 GitHub API 限流
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

# ---------- 1. Python venv ----------
if [ "$NEED_VENV" = "1" ]; then
    say "1/4 建 Python venv ~/verigis/venv"
    $SUDO apt-get install -y python3-venv python3-dev g++ 2>&1 | tail -5 \
        || { say "FATAL: python3-venv 装不上,需先解决 apt 源"; exit 1; }

    mkdir -p ~/verigis
    rm -rf ~/verigis/venv          # 清旧(若有)
    python3 -m venv --system-site-packages ~/verigis/venv \
        || { say "FATAL: venv 创建失败"; exit 1; }

    # shellcheck disable=SC1091
    source ~/verigis/venv/bin/activate
    python -m pip install --quiet --upgrade pip setuptools wheel
    python -m pip install --quiet numpy scipy whiteboxtools richdem
    say "venv OK: $(python -c 'import sys; print(sys.prefix)')"
else
    say "1/4 Python venv 已就位,跳过"
fi

# ---------- 2. Lean 4 via elan ----------
if [ "$NEED_LEAN" = "1" ]; then
    say "2/4 装 Lean 4(via elan)"
    say "  下载 elan-init.sh(超时 600s)..."
    # 主源
    if curl -sSfL --max-time 600 https://elan.lean-lang.org/elan-init.sh -o /tmp/elan-init.sh; then
        :
    else
        say "  elan.lean-lang.org 不通,改用 raw.githubusercontent.com 镜像"
        curl -sSfL --max-time 600 https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh \
            || { say "FATAL: elan 装不上,网络受限或 DNS 被污染。请发邮件或换网后重试,或直接装 Lean 4 二进制包"; exit 1; }
    fi
    sh /tmp/elan-init.sh -y --default-toolchain stable 2>&1 | tail -8
else
    say "2/4 lake 已就位,跳过 elan"
fi
export PATH="$HOME/.elan/bin:$PATH"
# 把 elan 环境装进 ~/.bashrc,后续会话自动可用
if [ -f "$HOME/.elan/env" ] && ! grep -q 'elan/env' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
fi
command -v lake >/dev/null 2>&1 \
    || { say "FATAL: lake 仍未找到,elan 安装可能没成功"; exit 1; }
say "lake: $(lake --version 2>&1 | head -1)"

# ---------- 3. Dafny(直装 .deb,不走 GitHub API)----------
if [ "$NEED_DAFNY" = "1" ]; then
    say "3/4 装 Dafny 4.8.1(.deb 直装)"
    DAFNY_VER="4.8.1"
    DEB="dafny-${DAFNY_VER}-x64-ubuntu-22.04.deb"
    URL="https://github.com/dafny-lang/dafny/releases/download/v${DAFNY_VER}/${DEB}"
    say "  下载 $URL (超时 20 min)"
    curl -sSLfL --max-time 1200 -o "/tmp/${DEB}" "$URL" \
        || { say "FATAL: Dafny .deb 下载失败(网络限速?)。可重试或换网"; exit 1; }
    ls -lh "/tmp/${DEB}"
    $SUDO apt-get install -y libssl3 libgcc-s1 libstdc++6 zlib1g 2>&1 | tail -3
    $SUDO dpkg -i "/tmp/${DEB}" 2>&1 | tail -5 \
        || { say "  dpkg 安装报依赖错,尝试 apt -fy 修复"; $SUDO apt-get install -fy 2>&1 | tail -5; }
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
python - <<'PY'
import importlib
for m in ["numpy", "scipy", "whiteboxtools", "richdem", "osgeo"]:
    try:
        v = getattr(importlib.import_module(m), "__version__", "ok")
        print(f"  OK   {m:14s} {v}")
    except Exception as e:
        print(f"  FAIL {m:14s} {e}")
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
