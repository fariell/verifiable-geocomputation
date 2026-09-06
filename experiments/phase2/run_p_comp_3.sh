#!/usr/bin/env bash
# P-COMP-3 / GPB-023 入口 — ZT 曲率不蕴含 Horn 二次斜率(阴性结果)
# AutoDL: bash /root/verigis/repo/experiments/phase2/run_p_comp_3.sh
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

echo "==[GPB-023] $PYTHON $HERE/p_comp_3.py =="
set +e
"$PYTHON" "$HERE/p_comp_3.py"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
    echo "GPB-023 ENTRY: NEGATIVE-RESULT PASS"
    exit 0
fi
echo "GPB-023 ENTRY: FAIL"
exit "$rc"
