#!/usr/bin/env bash
# GPB-019 入口 — Horn 坡度在网格间距 → 0 时的经验一致性(+ 噪声对照)
# AutoDL: bash /root/verigis/repo/experiments/phase1/run_benchmark.sh
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

echo "==[GPB-019] $PYTHON $HERE/gpb019_consistency.py =="
exec "$PYTHON" "$HERE/gpb019_consistency.py"
