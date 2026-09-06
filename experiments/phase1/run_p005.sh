#!/usr/bin/env bash
# P-005 / GPB-010+011 入口 — D8 洼地无流向 + 平面恒定
# AutoDL: bash /root/verigis/repo/experiments/phase1/run_p005.sh
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

echo "==[GPB-010/011] $PYTHON $HERE/p005_d8.py =="
exec "$PYTHON" "$HERE/p005_d8.py"
