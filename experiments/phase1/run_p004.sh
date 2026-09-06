#!/usr/bin/env bash
# P-004 / GPB-019 代数入口 — 二次精确 + 三次 O(w²)
# AutoDL: bash /root/verigis/repo/experiments/phase1/run_p004.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="${REPO:-$(cd "$HERE/../.." && pwd)}"
VENV="${VENV:-$HOME/verigis/venv}"
export REPO
export VERIGIS_HOME="${VERIGIS_HOME:-$HOME/verigis}"

if [ -x "$VENV/bin/python" ]; then
    PYTHON="$VENV/bin/python"
else
    PYTHON="python3"
fi

echo "==[GPB-019 algebra] $PYTHON $HERE/p004_consistency.py =="
exec "$PYTHON" "$HERE/p004_consistency.py"
