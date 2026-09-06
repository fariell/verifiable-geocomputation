#!/usr/bin/env bash
# scripts/autodl/results_pull.sh
# -----------------------------------------------------------------------------
# 冻结(2026-09-06 PI):结果留在 AutoDL ~/.workbuddy/,不再拉回本机。
# -----------------------------------------------------------------------------

set -uo pipefail

# PowerShell $env: 进不了 WSL bash;改从仓库根 autodl.env 读(gitignore)
_AD_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$_AD_DIR/_load_env.sh"

PWD_FILE="${AUTODL_PWD_FILE:-$HOME/.autodl_pwd}"
HOST="${AUTODL_SSH_HOST:?Set AUTODL_SSH_HOST in autodl.env (copy from autodl.env.example)}"
PORT="${AUTODL_SSH_PORT:?Set AUTODL_SSH_PORT in autodl.env (copy from autodl.env.example)}"

if [ ! -r "$PWD_FILE" ]; then
    echo "❌ 找不到 $PWD_FILE (mode 600)"
    echo "   创建: echo '你的密码' > ~/.autodl_pwd && chmod 600 ~/.autodl_pwd"
    exit 1
fi

# shellcheck disable=SC1091
. "$_AD_DIR/_ssh.sh"

# 本机落点
TS="$(date +%Y%m%d_%H%M%S)"
DEST="$(cd "$(dirname "$0")/../.." && pwd)/experiments/phase1/logs/cloud_${TS}"
mkdir -p "$DEST"
echo "==[results_pull] 拉到 $DEST =="

# 先查云端有哪些 summary
echo "-- ssh 列文件 --"
autodl_ssh "$HOST" \
    'ls -lt ~/.workbuddy/summary_*.txt 2>/dev/null | head -3' \
    | tee "$DEST/_ls.log"
echo ""

# 拉最新 1 个 summary + 对应 verify log(云端没保留大文件就尽力)
echo "-- scp summary + log --"
LATEST_SUMMARY=$(autodl_ssh "$HOST" \
    'ls -t ~/.workbuddy/summary_*.txt 2>/dev/null | head -1' | tr -d '\r\n')
echo "  最新 summary: $LATEST_SUMMARY"

if [ -n "$LATEST_SUMMARY" ]; then
    BASE=$(basename "$LATEST_SUMMARY")
    autodl_scp \
        "$HOST:$LATEST_SUMMARY" \
        "$DEST/$BASE"
    TS_PART=$(echo "$BASE" | sed -n 's/summary_\([0-9_]*\)\.txt/\1/p')
    autodl_scp \
        "$HOST:$HOME/.workbuddy/verify_${TS_PART}.log" \
        "$DEST/verify_${TS_PART}.log" 2>&1 || true
fi

# 写 STATUS.md 一行(如在)
STATUS="$(cd "$(dirname "$0")/../.." && pwd)/experiments/phase1/STATUS.md"
if [ -f "$DEST/summary_"*.txt ]; then
    {
        echo
        echo "## cloud pull @ $(date '+%Y-%m-%d %H:%M:%S') (id=$TS)"
        grep -E 'OK|FAIL|status:' "$DEST/"summary_*.txt | head -30 || true
    } >> "$STATUS"
    echo "✏️  append $STATUS"
fi

echo "==[done] 拉到本地的文件:"
ls -la "$DEST"
