#!/usr/bin/env bash
# scripts/autodl/verify_all.sh
# -----------------------------------------------------------------------------
# 在 AutoDL 实例里跑"今天该验的几件事",把摘要写到 ~/.workbuddy/summary_<ts>.txt
# 跑法: sshpass -f ~/.autodl_pwd ssh -p <your-autoDL-port> root@<your-autoDL-host> \
#         'bash -s' < scripts/autodl/verify_all.sh
# -----------------------------------------------------------------------------

set -uo pipefail

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$HOME/.workbuddy"
LOG="$LOG_DIR/verify_${RUN_ID}.log"
SUMMARY="$LOG_DIR/summary_${RUN_ID}.txt"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG") 2>&1

echo "============================================================"
echo "verify_all START @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "LOG    : $LOG"
echo "SUMMARY: $SUMMARY"
echo "============================================================"
> "$SUMMARY"  # 清空

# 默认仓库位置(setup.sh 装的);若不在则用 fallback
REPO="${REPO:-$HOME/verigis/repo}"
[ -d "$REPO/formal" ] || REPO="$(dirname "$(cd "$(dirname "$0")" && pwd)")"
echo "[repo] $REPO"

run_step() {
    local name="$1"; shift
    echo "==[ $name ]=="
    echo "---- $name ----" >> "$SUMMARY"
    if "$@" 2>&1 | tee -a "$LOG" | tail -10; then
        echo "status: OK" >> "$SUMMARY"
    else
        echo "status: FAIL" >> "$SUMMARY"
    fi
    echo "" >> "$SUMMARY"
}

# ---- 1. 工具链现状 ----
echo "==[1/4] 工具链现状 =="
{
    echo "---- tools ----"
    for t in lean lake dafny python3 gdalinfo unzip; do
        if command -v "$t" >/dev/null 2>&1; then
            echo "  ✅ $t  $(command -v $t)"
        else
            echo "  ❌ $t  not in PATH"
        fi
    done
} | tee -a "$LOG" "$SUMMARY"

# ---- 2. Dafny ----
echo "==[2/4] Dafny P-001 + P-002 =="
if command -v dafny >/dev/null 2>&1; then
    if [ -f "$REPO/formal/dafny/P001_horn_slope.dfy" ]; then
        echo "[dafny] P-001" | tee -a "$SUMMARY"
        dafny verify "$REPO/formal/dafny/P001_horn_slope.dfy" 2>&1 \
            | tail -3 | tee -a "$LOG" "$SUMMARY" || true
    fi
    if [ -f "$REPO/formal/dafny/P002_pit_filling.dfy" ]; then
        echo "[dafny] P-002 (SMT 可能超时)" | tee -a "$SUMMARY"
        timeout 180 dafny verify "$REPO/formal/dafny/P002_pit_filling.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-002 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
else
    echo "[dafny] ⏭  未装,跳过" | tee -a "$SUMMARY"
fi

# ---- 3. Lean ----
echo "==[3/4] Lean P-001 =="
if command -v lake >/dev/null 2>&1; then
    cd "$REPO/formal/lean4"
    if [ -d ".lake/build" ]; then
        echo "[lean] lake build 增量" | tee -a "$SUMMARY"
        timeout 600 lake build 2>&1 | tail -5 \
            | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ lake build 超时" | tee -a "$SUMMARY"
    else
        echo "[lean] ⏭  mathlib 未暖机;先跑 setup.sh 暖一次" | tee -a "$SUMMARY"
    fi
else
    echo "[lean] ⏭  未装,跳过" | tee -a "$SUMMARY"
fi

# ---- 4. (可选) GPB-019 入口 ----
echo "==[4/4] GPB-019 DEM 噪声实验入口 =="
if [ -f "$REPO/experiments/phase1/run_benchmark.sh" ]; then
    echo "[gpb019] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase1/run_benchmark.sh" 2>&1 \
        | tail -10 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-019 失败" | tee -a "$SUMMARY"
else
    echo "[gpb019] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
    echo "        待补:experiments/phase1/run_benchmark.sh" | tee -a "$SUMMARY"
fi

echo "============================================================"
echo "verify_all DONE  @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 摘要: $SUMMARY"
echo "📄 全文: $LOG"
echo "============================================================"
cat "$SUMMARY"
