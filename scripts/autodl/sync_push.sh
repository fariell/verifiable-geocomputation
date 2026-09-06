#!/usr/bin/env bash
# scripts/autodl/sync_push.sh
# -----------------------------------------------------------------------------
# 本机 formal/ + scripts/autodl/ → AutoDL ~/verigis/repo/
# Cursor 改完源码后 overlay;实验仍在云端跑。
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
echo "==[sync_push] $ROOT/{formal,scripts/autodl,experiments/phase1} → $HOST:$REMOTE_REPO =="

autodl_ssh "$HOST" \
    "mkdir -p '$REMOTE_REPO/formal/dafny' '$REMOTE_REPO/formal/lean4/VeriGIS' '$REMOTE_REPO/scripts/autodl' '$REMOTE_REPO/experiments/phase1'"

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

autodl_scp \
    "$ROOT/experiments/phase1/"*.py \
    "$ROOT/experiments/phase1/"*.sh \
    "$HOST:$REMOTE_REPO/experiments/phase1/"

if ls "$ROOT/experiments/phase1/"*.wl >/dev/null 2>&1; then
    autodl_scp \
        "$ROOT/experiments/phase1/"*.wl \
        "$HOST:$REMOTE_REPO/experiments/phase1/"
fi

echo "==[done] overlay 完成。下一步在 AutoDL 跑实验 =="
