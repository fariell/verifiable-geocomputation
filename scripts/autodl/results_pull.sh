#!/usr/bin/env bash
# scripts/autodl/results_pull.sh
# -----------------------------------------------------------------------------
# 把云端 ~/.workbuddy/ 里今天跑出的摘要 + 原始日志拉到本机 experiments/phase1/logs/
# 幂等:同名文件 .bak 留底
# -----------------------------------------------------------------------------

set -uo pipefail

# 凭据:全部从环境变量读(must 在 ~/.bashrc 设),不进 commit
# 必设:
#   export AUTODL_SSH_HOST="root@<your-autoDL-host>"
#   export AUTODL_SSH_PORT="<your-autoDL-port>"
#   export AUTODL_PWD_FILE="$HOME/.autodl_pwd"   # 或保留默认
PWD_FILE="${AUTODL_PWD_FILE:-$HOME/.autodl_pwd}"
HOST="${AUTODL_SSH_HOST:?Set AUTODL_SSH_HOST (e.g. root@<your-autoDL-host>) in ~/.bashrc}"
PORT="${AUTODL_SSH_PORT:?Set AUTODL_SSH_PORT (your autoDL instance SSH port) in ~/.bashrc}"

if [ ! -r "$PWD_FILE" ]; then
    echo "❌ 找不到 $PWD_FILE (mode 600)"
    echo "   创建: echo '你的密码' > ~/.autodl_pwd && chmod 600 ~/.autodl_pwd"
    exit 1
fi

# 本机落点
TS="$(date +%Y%m%d_%H%M%S)"
DEST="$(cd "$(dirname "$0")/../.." && pwd)/experiments/phase1/logs/cloud_${TS}"
mkdir -p "$DEST"
echo "==[results_pull] 拉到 $DEST =="

# 先查云端有哪些 summary
echo "-- ssh 列文件 --"
sshpass -f "$PWD_FILE" ssh -p "$PORT" \
    -o StrictHostKeyChecking=no \
    "$HOST" \
    'ls -lt ~/.workbuddy/summary_*.txt 2>/dev/null | head -3' \
    | tee "$DEST/_ls.log"
echo ""

# 拉最新 1 个 summary + 对应 verify log(云端没保留大文件就尽力)
echo "-- scp summary + log --"
LATEST_SUMMARY=$(sshpass -f "$PWD_FILE" ssh -p "$PORT" \
    -o StrictHostKeyChecking=no "$HOST" \
    'ls -t ~/.workbuddy/summary_*.txt 2>/dev/null | head -1' | tr -d '\r\n')
echo "  最新 summary: $LATEST_SUMMARY"

if [ -n "$LATEST_SUMMARY" ]; then
    BASE=$(basename "$LATEST_SUMMARY")
    sshpass -f "$PWD_FILE" scp -P "$PORT" -o StrictHostKeyChecking=no \
        "$HOST:$LATEST_SUMMARY" \
        "$DEST/$BASE"
    # 拉同一个时间戳的 verify log(若有)
    TS_PART=$(echo "$BASE" | sed -n 's/summary_\([0-9_]*\)\.txt/\1/p')
    if [ -n "$TS_PART" ] && [ -f "$HOME/.workbuddy/verify_${TS_PART}.log" ] 2>/dev/null; then
        :  # 跳过,本机那份看不见云端的,直接 scp 同名
    fi
    sshpass -f "$PWD_FILE" scp -P "$PORT" -o StrictHostKeyChecking=no \
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
