#!/usr/bin/env bash
# VeriGIS Phase 1 — experiment driver. Called by bootstrap.sh after the env is ready.
set -u
export VERIGIS_HOME=/root/verigis
export VERIGIS_LOG=$VERIGIS_HOME/logs
source "$VERIGIS_HOME/venv/bin/activate"
cd "$VERIGIS_HOME"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE1 experiment start ===" | tee -a "$VERIGIS_LOG/progress.log"
python "$VERIGIS_HOME/experiments/phase1/experiment.py" 2>&1 | tee -a "$VERIGIS_LOG/progress.log"
python "$VERIGIS_HOME/experiments/phase1/propositions.py" 2>&1 | tee -a "$VERIGIS_LOG/progress.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE1 experiment end ===" | tee -a "$VERIGIS_LOG/progress.log"
