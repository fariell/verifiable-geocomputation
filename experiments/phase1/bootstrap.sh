#!/usr/bin/env bash
# VeriGIS Phase 1 — bootstrap: install env on the remote, run the experiment, build Lean skeleton.
# Runs detached (nohup setsid) so it survives the launching SSH session.
set -u
export VERIGIS_HOME=/root/verigis
export VERIGIS_LOG=$VERIGIS_HOME/logs
export DEBIAN_FRONTEND=noninteractive
mkdir -p "$VERIGIS_LOG" "$VERIGIS_HOME/results" "$VERIGIS_HOME/experiments" "$VERIGIS_HOME/lean4_proj"
LOG="$VERIGIS_LOG/bootstrap.log"
PROGRESS="$VERIGIS_LOG/progress.log"
exec > >(tee -a "$LOG") 2>&1

now() { date '+%Y-%m-%d %H:%M:%S'; }

echo "[$(now)] BOOTSTRAP start (pid $$)"
echo "[$(now)] OS: $(uname -a)"
echo "[$(now)] GPU:"; nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "  (no GPU / nvidia-smi missing)"
echo "[$(now)] CPU: $(nproc) cores, RAM $(free -h | awk '/Mem:/{print $2}')"

# 30-minute heartbeat — satisfies "output progress every 30 min".
( while true; do sleep 1800; echo "[$(now)] HEARTBEAT alive. last progress: $(tail -1 "$PROGRESS" 2>/dev/null)"; done ) &
HB=$!

echo "[$(now)] [1/5] system deps (apt)"
apt-get update -qq && apt-get install -y -qq python3-venv python3-pip git curl build-essential 2>&1 | tail -2 || echo "apt step had issues (non-fatal)"

echo "[$(now)] [2/5] python venv + packages"
python3 -m venv "$VERIGIS_HOME/venv"
# shellcheck disable=SC1091
source "$VERIGIS_HOME/venv/bin/activate"
pip install -q --upgrade pip
pip install -q numpy scipy matplotlib 2>&1 | tail -3
pip install -q rasterio whiteboxtools richdem 2>&1 | tail -3 || echo "optional geo packages skipped (non-fatal)"
python -c "import numpy, scipy, matplotlib; print('python env OK numpy', numpy.__version__)" | tee -a "$PROGRESS"

echo "[$(now)] [3/5] run Phase-1 experiment"
bash "$VERIGIS_HOME/experiments/phase1/run_experiment.sh"

echo "[$(now)] [4/5] Lean 4 toolchain (elan)"
if ! command -v lake >/dev/null 2>&1; then
  # Pin a version and bound the download so it never blocks the whole bootstrap.
  timeout 200 bash -c 'curl -sSfL --connect-timeout 20 https://elan.lean-lang.org/elan-init.sh -o /tmp/elan-init.sh && sh /tmp/elan-init.sh -y --default-toolchain leanprover/lean4:v4.12.0' 2>&1 | tail -3 || echo "elan install failed or timed out (non-fatal)"
  # shellcheck disable=SC1091
  [ -f "$HOME/.elan/env" ] && source "$HOME/.elan/env"
fi
if command -v lake >/dev/null 2>&1; then
  cp -r "$VERIGIS_HOME/experiments/phase1/lean4_proj/." "$VERIGIS_HOME/lean4_proj/" 2>/dev/null
  cd "$VERIGIS_HOME/lean4_proj" && timeout 300 lake build 2>&1 | tail -15 && echo "[$(now)] LEAN BUILD OK" | tee -a "$PROGRESS" || echo "[$(now)] LEAN BUILD had errors or timed out"
else
  echo "[$(now)] lake not available, skipping Lean build (non-fatal)"
fi

echo "[$(now)] [5/5] finalize"
echo "[$(now)] RESULTS:"; ls -la "$VERIGIS_HOME/results" 2>/dev/null
echo "[$(now)] BOOTSTRAP done"
kill "$HB" 2>/dev/null || true
