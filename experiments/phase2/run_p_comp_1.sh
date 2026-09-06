#!/usr/bin/env bash
# P-COMP-1 / GPB-021 入口 — 填洼后流域唯一
# AutoDL: bash /root/verigis/repo/experiments/phase2/run_p_comp_1.sh
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

echo "==[GPB-021] $PYTHON $HERE/p_comp_1.py =="
exec "$PYTHON" "$HERE/p_comp_1.py"
