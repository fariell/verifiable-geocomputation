#!/usr/bin/env bash
# P-006 / GPB-015 入口 — 流域唯一性 + flat 环反例
# AutoDL: bash /root/verigis/repo/experiments/phase1/run_p006.sh
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

echo "==[GPB-015] $PYTHON $HERE/p006_watershed.py =="
exec "$PYTHON" "$HERE/p006_watershed.py"
