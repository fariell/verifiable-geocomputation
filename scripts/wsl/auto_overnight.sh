#!/usr/bin/env bash
# ============================================================================
# auto_overnight.sh — 睡前启动、晨起收成
#
# 设计目标
# ---------
# 把 PI 睡着的 8 小时,变成"无人值守"的离线跑批:
#   1) 自动盘点 WSL 现状(不向任何外部地址发请求,纯本地)
#   2) 重新跑 P-001 Horn 坡度的 Dafny 验证(确认昨夜结果稳定)
#   3) 如果 lake 在,试编译数学库(只跑一次,不阻塞)
#   4) 把上述结果落到 .workbuddy/memory/2026-09-07.md,PI 醒来直接读
#   5) 不写磁盘任何其它东西,失败也不破坏既有文件
#
# 用法(在 WSL bash 里)
# -----------
#   bash /mnt/e/AI\ for\ Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/auto_overnight.sh
#
# 然后放心睡。晨起:
#   - 看 .workbuddy/memory/2026-09-07.md 是摘要
#   - 详细原始日志在 ~/.workbuddy/overnight/<时间戳>.log
#
# 失败模式
# ---------
# - 脚本里所有 step 都用 `|| true` 隔开,任何一步失败都不会让后面跑不下去
# - 找不到 dafny / lake 是常态(Lean 还没装好),写到 SUMMARY 里不报错
# - 找不到仓库 → exit 1(这种情况就是真出错,不该继续)
# ============================================================================

set -uo pipefail

# ---------- 找仓库根 ----------
find_repo() {
    local cands=(
        "/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation"
        "/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation-main"
        "$HOME/verigis/verifiable-geocomputation"
        "$HOME/verigis/verifiable-geocomputation-main"
    )
    for c in "${cands[@]}"; do
        if [ -d "$c/.git" ]; then
            echo "$c"
            return 0
        fi
    done
    # 退化:用 /mnt 搜
    if [ -d /mnt/e ]; then
        for d in /mnt/e/AI*/verifiable-geocomputation*; do
            [ -d "$d/.git" ] && { echo "$d"; return 0; }
        done
    fi
    return 1
}

REPO="$(find_repo)"
if [ -z "$REPO" ]; then
    echo "❌ auto_overnight: 找不到仓库根,放弃"
    exit 1
fi

# ---------- 日志 ----------
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$HOME/.workbuddy/overnight"
LOG="$LOG_DIR/${RUN_ID}.log"
SUMMARY="$REPO/.workbuddy/memory/$(date +%Y-%m-%d).md"
mkdir -p "$LOG_DIR"
# 用 install 而非 exec tee,把整个脚本输出同时拉到终端(若人看着)+ 日志
# 退出码保留:不强求 exec,失败时下一步也要接着跑(我们只要记录)
exec > >(tee -a "$LOG") 2>&1

START_TS="$(date '+%F %T')"
echo "============================================================"
echo " auto_overnight START @ $START_TS"
echo " REPO : $REPO"
echo " LOG  : $LOG"
echo "============================================================"

# ---------- 工具链盘点 ----------
echo ""
echo "==[1/4] 工具链盘点 =="
for c in lake lean dafny elan python3 pip3 gdalinfo unzip tar unzstd; do
    p=$(command -v "$c" 2>/dev/null || true)
    if [ -n "$p" ]; then
        # 取版本:lake/lean/dafny/elan 取第一行;其它跳过
        v=""
        case "$c" in
            lake|lean|dafny|elan) v=$($c --version 2>&1 | head -1) ;;
            python3)              v=$(python3 --version 2>&1) ;;
            gdalinfo)             v=$(gdalinfo --version 2>&1) ;;
            tar|unzip|unzstd)     v="(built-in)" ;;
        esac
        printf "  ✅  %-10s  %s  (%s)\n" "$c" "$v" "$p"
    else
        printf "  ❌  %-10s  not in PATH\n" "$c"
    fi
done

# ---------- 2) Dafny 烟雾测试 + 重验证 P-001 ----------
echo ""
echo "==[2/4] Dafny 验证 =="
DAFNY_VERIFY_LOG="$LOG_DIR/${RUN_ID}_dafny.log"
if command -v dafny >/dev/null 2>&1; then
    # 2a. 冒烟:标准库自带 Abs
    cat > /tmp/auto_overnight_hello.dfy <<'EOF'
method Abs(x: int) returns (y: int)
  ensures y >= 0
  ensures y == x || y == -x
{ if x >= 0 { y := x; } else { y := -x; } }
EOF
    echo "  -- 冒烟 (Abs) --"
    dafny verify /tmp/auto_overnight_hello.dfy 2>&1 | tail -3 | sed 's/^/    /'

    # 2b. P-001 重跑
    P001="$REPO/formal/dafny/P001_horn_slope.dfy"
    if [ -f "$P001" ]; then
        echo ""
        echo "  -- P-001 (Horn 坡度 6 引理) --"
        T0=$(date +%s)
        if dafny verify "$P001" 2>&1 | tee "$DAFNY_VERIFY_LOG" | tail -10; then
            T1=$(date +%s); DUR=$((T1-T0))
            echo "    ⏱  ${DUR} 秒"
        else
            echo "    ⚠️  P-001 验证未通过(详细见 dafny.log)"
        fi
    else
        echo "  ⚠️  P-001 文件不存在($P001),跳过"
    fi
else
    echo "  ❌  dafny 不在 PATH,跳过验证"
fi

# ---------- 3) Lean 试编译(如装好)----------
echo ""
echo "==[3/4] Lean build 试编译 =="
LEAN_BUILD_LOG="$LOG_DIR/${RUN_ID}_lake.log"
if command -v lake >/dev/null 2>&1; then
    # 优先用仓库自带的 formal/lean4/,否则用 ~/verigis/lean4_proj
    LEAN_DIR=""
    if [ -f "$REPO/formal/lean4/lakefile.toml" ] || [ -f "$REPO/formal/lean4/lakefile.lean" ]; then
        LEAN_DIR="$REPO/formal/lean4"
    elif [ -d "$HOME/verigis/lean4_proj" ]; then
        LEAN_DIR="$HOME/verigis/lean4_proj"
    fi

    if [ -n "$LEAN_DIR" ]; then
        echo "  lake target: $LEAN_DIR"
        cd "$LEAN_DIR"
        # 第一次 lake build 30–60 min,超时不算致命
        echo "  -- lake update(取 mathlib v4.18.0) --"
        timeout 600 lake update 2>&1 | tail -5 | sed 's/^/    /' || true
        echo ""
        echo "  -- lake build(数学库编译) --"
        T0=$(date +%s)
        if timeout 1500 lake build 2>&1 | tee "$LEAN_BUILD_LOG" | tail -20; then
            T1=$(date +%s); DUR=$((T1-T0))
            echo "    ⏱  lake build 完成 ${DUR} 秒"
        else
            echo "    ⚠️  lake build 超时或失败(详细见 lake.log)"
            echo "        首次 30–60 min 属正常;失败通常是 network 或 mathlib 仓库未取到"
        fi
    else
        echo "  ⚠️  没有 Lake 项目目录,跳过"
    fi
else
    echo "  ❌  lake 不在 PATH,跳过"
fi

# ---------- 4) 写次日摘要 ----------
echo ""
echo "==[4/4] 写次日摘要 =="
END_TS="$(date '+%F %T')"
{
    if [ ! -f "$SUMMARY" ]; then
        # 当日 memory 文件不存在,从这里创建(append-only 原则:首次创建)
        printf -- "---\n\n"
    fi
    cat <<EOF

## auto_overnight run @ $START_TS → $END_TS

### 工具链真状态(Git Bash 看不进 WSL,以本行为准)
EOF

    for c in lake lean dafny elan python3 gdalinfo; do
        p=$(command -v "$c" 2>/dev/null || true)
        if [ -n "$p" ]; then
            v=""
            case "$c" in
                lake|lean|dafny|elan) v=$($c --version 2>&1 | head -1) ;;
                python3)              v=$(python3 --version 2>&1) ;;
                gdalinfo)             v=$(gdalinfo --version 2>&1) ;;
            esac
            printf -- "- ✅ \`%s\`  %s  (%s)\n" "$c" "$v" "$p"
        else
            printf -- "- ❌ \`%s\`  not in PATH\n" "$c"
        fi
    done

    cat <<EOF

### Dafny 验证
EOF
    if [ -f "$DAFNY_VERIFY_LOG" ]; then
        # 抽取 "X verified, Y errors" 行
        grep -E "verified|errors|verifier" "$DAFNY_VERIFY_LOG" 2>/dev/null | tail -5 \
            | sed 's/^/    /' || echo "    (无 verifier 输出)"
    else
        echo "    (dafny 不在,跳过)"
    fi

    cat <<EOF

### Lean build
EOF
    if [ -f "$LEAN_BUILD_LOG" ]; then
        # 取末尾 5 行
        tail -5 "$LEAN_BUILD_LOG" 2>/dev/null | sed 's/^/    /' \
            || echo "    (无 lake 输出)"
    else
        echo "    (lake 不在或无 lean 项目,跳过)"
    fi

    cat <<EOF

### 原始日志
- 完整:\`~/.workbuddy/overnight/${RUN_ID}.log\`
- Dafny:\`~/.workbuddy/overnight/${RUN_ID}_dafny.log\`
- Lake :\`~/.workbuddy/overnight/${RUN_ID}_lake.log\`
EOF
} >> "$SUMMARY"

echo "  → 已写入 $SUMMARY"
echo ""
echo "============================================================"
echo " auto_overnight DONE  @ $(date '+%F %T')"
echo "============================================================"
