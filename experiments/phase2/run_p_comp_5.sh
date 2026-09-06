#!/usr/bin/env bash
# P-COMP-5 / GPB-026 入口 — 填洼元一致
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
echo "==[GPB-026] $PYTHON $HERE/p_comp_5.py =="
exec "$PYTHON" "$HERE/p_comp_5.py"
