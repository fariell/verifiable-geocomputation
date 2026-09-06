#!/usr/bin/env bash
# P-COMP-1 multi-res / GPB-024 — same algorithm on 4 DEM sizes
# AutoDL: bash /root/verigis/repo/experiments/phase2/run_p_comp_1_multires.sh
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

echo "==[GPB-024] $PYTHON $HERE/p_comp_1_multires.py =="
set +e
"$PYTHON" "$HERE/p_comp_1_multires.py"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
    echo "GPB-024 ENTRY: PASS"
    exit 0
fi
echo "GPB-024 ENTRY: FAIL"
exit "$rc"
