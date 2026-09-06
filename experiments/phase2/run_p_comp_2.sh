#!/usr/bin/env bash
# P-COMP-2 / GPB-022 入口 — 全平面闭包(256² 0 起伏 + 行扰动)
# AutoDL: bash /root/verigis/repo/experiments/phase2/run_p_comp_2.sh
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

echo "==[GPB-022] $PYTHON $HERE/p_comp_2.py =="
exec "$PYTHON" "$HERE/p_comp_2.py"
