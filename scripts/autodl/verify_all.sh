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

# ---- 0. PATH + GitHub 加速(新开的 bash 默认没有 elan / 代理) ----
[ -f /etc/network_turbo ] && . /etc/network_turbo
[ -f "$HOME/.elan/env" ] && . "$HOME/.elan/env"
export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH"

# ---- 1. 工具链现状 ----
echo "==[1/5] 工具链现状 =="
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
echo "==[2/5] Dafny P-001 + P-002 + P-002-bis + P-003 + P-004 =="
if command -v dafny >/dev/null 2>&1; then
    if [ -f "$REPO/formal/dafny/P001_horn_slope.dfy" ]; then
        echo "[dafny] P-001" | tee -a "$SUMMARY"
        dafny verify "$REPO/formal/dafny/P001_horn_slope.dfy" 2>&1 \
            | tail -3 | tee -a "$LOG" "$SUMMARY" || true
    fi
    if [ -f "$REPO/formal/dafny/P002_pit_filling.dfy" ]; then
        echo "[dafny] P-002 (1D Fill; 若 SMT 超时把 log 贴回)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P002_pit_filling.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-002 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/P002_pit_filling_2d.dfy" ]; then
        echo "[dafny] P-002-bis (2D RaiseNbr)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P002_pit_filling_2d.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-002-bis verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/P003_curvature.dfy" ]; then
        echo "[dafny] P-003 (ZT Hessian)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P003_curvature.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-003 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/P004_consistency.dfy" ]; then
        echo "[dafny] P-004 (Horn w→0)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P004_consistency.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-004 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/P005_d8.dfy" ]; then
        echo "[dafny] P-005 (D8)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P005_d8.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-005 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/P006_watershed.dfy" ]; then
        echo "[dafny] P-006 (watershed)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P006_watershed.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-006 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/P006_terminate_under_strict.dfy" ]; then
        echo "[dafny] P-006 T6 (strict descent ⇒ terminate)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/P006_terminate_under_strict.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-006 T6 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
    if [ -f "$REPO/formal/dafny/PCOMP_1.dfy" ]; then
        echo "[dafny] P-COMP-1 (fill then watershed)" | tee -a "$SUMMARY"
        timeout 300 dafny verify "$REPO/formal/dafny/PCOMP_1.dfy" 2>&1 \
            | tail -10 | tee -a "$LOG" "$SUMMARY" || \
            echo "  ⚠️ P-COMP-1 verify 超时或失败,详见 $LOG" | tee -a "$SUMMARY"
    fi
else
    echo "[dafny] ⏭  未装,跳过" | tee -a "$SUMMARY"
fi

# ---- 3. Lean(首次 lake update+build 30-60 min;不要因为没有 .lake/build 就跳过) ----
echo "==[3/5] Lean =="
if command -v lake >/dev/null 2>&1; then
    cd "$REPO/formal/lean4"
    echo "[lean] lake update + lake build (首次会拉 mathlib)" | tee -a "$SUMMARY"
    timeout 1800 bash -c 'lake update && lake build' 2>&1 | tail -20 \
        | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ lake 超时或失败 — 这在首次暖机时可能非致命,详见 $LOG" | tee -a "$SUMMARY"
else
    echo "[lean] ⏭  未装,跳过" | tee -a "$SUMMARY"
fi

# ---- 4. GPB-019 / P-003 实验入口 ----
echo "==[4/5] GPB-019 DEM 噪声实验入口 =="
if [ -f "$REPO/experiments/phase1/run_benchmark.sh" ]; then
    echo "[gpb019] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase1/run_benchmark.sh" 2>&1 \
        | tail -10 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-019 失败" | tee -a "$SUMMARY"
else
    echo "[gpb019] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
fi

echo "==[5/5] GPB-003 / P-003 曲率入口 =="
if [ -f "$REPO/experiments/phase1/run_p003.sh" ]; then
    echo "[gpb003] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase1/run_p003.sh" 2>&1 \
        | tail -20 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-003 失败" | tee -a "$SUMMARY"
else
    echo "[gpb003] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
fi

echo "==[6/6] GPB-019 algebra / P-004 =="
if [ -f "$REPO/experiments/phase1/run_p004.sh" ]; then
    echo "[gpb004] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase1/run_p004.sh" 2>&1 \
        | tail -20 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-004 失败" | tee -a "$SUMMARY"
else
    echo "[gpb004] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
fi

echo "==[7/8] GPB-010/011 / P-005 =="
if [ -f "$REPO/experiments/phase1/run_p005.sh" ]; then
    echo "[gpb005] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase1/run_p005.sh" 2>&1 \
        | tail -20 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-005 失败" | tee -a "$SUMMARY"
else
    echo "[gpb005] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
fi

echo "==[8/9] GPB-015 / P-006 =="
if [ -f "$REPO/experiments/phase1/run_p006.sh" ]; then
    echo "[gpb015] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase1/run_p006.sh" 2>&1 \
        | tail -20 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-015 失败" | tee -a "$SUMMARY"
else
    echo "[gpb015] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
fi

echo "==[9/9] GPB-021 / P-COMP-1 =="
if [ -f "$REPO/experiments/phase2/run_p_comp_1.sh" ]; then
    echo "[gpb021] 跑实验中" | tee -a "$SUMMARY"
    bash "$REPO/experiments/phase2/run_p_comp_1.sh" 2>&1 \
        | tail -20 | tee -a "$LOG" "$SUMMARY" || \
        echo "  ⚠️ GPB-021 失败" | tee -a "$SUMMARY"
else
    echo "[gpb021] ⏭  实验脚本未就位,跳过" | tee -a "$SUMMARY"
fi

echo "============================================================"
echo "verify_all DONE  @ $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 摘要: $SUMMARY"
echo "📄 全文: $LOG"
echo "============================================================"
cat "$SUMMARY"
