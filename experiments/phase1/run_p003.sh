#!/usr/bin/env bash
# P-003 / GPB-003 入口 — ZT Hessian + Phase-1 错误模板对照
# AutoDL: bash /root/verigis/repo/experiments/phase1/run_p003.sh
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

echo "==[GPB-003] $PYTHON $HERE/p003_curvature.py =="
exec "$PYTHON" "$HERE/p003_curvature.py"
