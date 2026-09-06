#!/usr/bin/env bash
# scripts/autodl/sync_push.sh
# -----------------------------------------------------------------------------
# 冻结(2026-09-06 PI):不再本机 overlay。实验只在 AutoDL /root/verigis/repo。
# 本文件留档,不要作为日常入口。
# -----------------------------------------------------------------------------

set -uo pipefail

_AD_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$_AD_DIR/_load_env.sh"

PWD_FILE="${AUTODL_PWD_FILE:-$HOME/.autodl_pwd}"
HOST="${AUTODL_SSH_HOST:?Set AUTODL_SSH_HOST in autodl.env (copy from autodl.env.example)}"
PORT="${AUTODL_SSH_PORT:?Set AUTODL_SSH_PORT in autodl.env (copy from autodl.env.example)}"
REMOTE_REPO="${AUTODL_REMOTE_REPO:-/root/verigis/repo}"

if [ ! -r "$PWD_FILE" ]; then
    echo "❌ 找不到 $PWD_FILE (mode 600)"
    echo "   创建: echo '<your-autoDL-password>' > ~/.autodl_pwd && chmod 600 ~/.autodl_pwd"
    exit 1
fi

# shellcheck disable=SC1091
. "$_AD_DIR/_ssh.sh"
set -e

ROOT="$(cd "$_AD_DIR/../.." && pwd)"
echo "==[sync_push] $ROOT/{formal,scripts/autodl} → $HOST:$REMOTE_REPO =="

autodl_ssh "$HOST" \
    "mkdir -p '$REMOTE_REPO/formal/dafny' '$REMOTE_REPO/formal/lean4/VeriGIS' '$REMOTE_REPO/scripts/autodl'"

autodl_scp \
    "$ROOT/formal/dafny/"*.dfy \
    "$ROOT/formal/dafny/"*.md \
    "$HOST:$REMOTE_REPO/formal/dafny/"

autodl_scp \
    "$ROOT/formal/lean4/lakefile.toml" \
    "$ROOT/formal/lean4/lean-toolchain" \
    "$ROOT/formal/lean4/VeriGIS.lean" \
    "$HOST:$REMOTE_REPO/formal/lean4/"

autodl_scp \
    "$ROOT/formal/lean4/VeriGIS/"*.lean \
    "$HOST:$REMOTE_REPO/formal/lean4/VeriGIS/"

autodl_scp \
    "$ROOT/scripts/autodl/"*.sh \
    "$ROOT/scripts/autodl/"*.py \
    "$HOST:$REMOTE_REPO/scripts/autodl/"

echo "==[done] overlay 完成。下一步在 JupyterLab 跑 verify_all.sh =="
