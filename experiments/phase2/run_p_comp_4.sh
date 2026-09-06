#!/usr/bin/env bash
# P-COMP-4 / GPB-025 入口 — 重采样同伦
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="${REPO:-$(cd "$HERE/../.." && pwd)}"
VENV="${VENV:-$HOME/verigis/venv}"
export REPO
if [ -x "$VENV/bin/python" ]; then
    PYTHON="$VENV/bin/python"
else
    PYTHON="python3"
fi
echo "==[GPB-025] $PYTHON $HERE/p_comp_4.py =="
exec "$PYTHON" "$HERE/p_comp_4.py"
