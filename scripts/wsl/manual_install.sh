#!/usr/bin/env bash
#
# manual_install.sh — 网络根本到不了 GitHub/镜像时的最后退路(纯本地摆位)
#
# 前提:已经在"能上 GitHub 的设备"上把文件下载好,放进 Windows 下载目录。
# 本脚本**不做任何网络下载**,只做:找文件 → 魔数校验 → 解包 → 摆位 → 验证。
#
# 支持的文件名(原始名和重命名后的都认,不用手动改名):
#   elan  : elan.tar.gz  或  elan-x86_64-unknown-linux-gnu.tar.gz
#   lean  : lean.tar.zst 或  lean-4.18.0-linux.tar.zst
#   dafny : dafny.zip    或  dafny-4.11.0-x64-ubuntu-22.04.zip
#
# 用法(WSL bash 里):
#   bash scripts/wsl/manual_install.sh
#
# 用法(WSL bash 里):
#   每个组件独立:已装好的自动跳过,只补缺的。
#   Lean toolchain 是大文件(318 MB),如果只下了一部分(.crdownload),
#   本脚本会提示先跑 resume_lean.sh 续传。
#
set -uo pipefail

say()  { printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

VER_LEAN="4.18.0"
VER_DAFNY="4.11.0"

# 汇总打印(定义在前面,供"已全部就位提前退出"分支调用)
print_summary() {
    say ""
    say "===== 汇总 ====="
    printf "  %-16s %s\n" "gdalinfo :" "$(gdalinfo --version 2>&1)"
    printf "  %-16s %s\n" "elan     :" "$($HOME/.elan/bin/elan --version 2>&1 | head -1)"
    printf "  %-16s %s\n" "lake     :" "$(command -v lake >/dev/null 2>&1 && lake --version 2>&1 | head -1 || echo '未安装')"
    printf "  %-16s %s\n" "dafny    :" "$(command -v dafny >/dev/null 2>&1 && dafny --version 2>&1 | head -1 || echo '未安装')"
    # shellcheck disable=SC1091
    source ~/verigis/venv/bin/activate 2>/dev/null
    printf "  %-16s %s\n" "venv py  :" "$(python -c 'import sys; print(sys.prefix)' 2>&1)"
}

# ---------- 自动探测 Windows 下载目录 ----------
# WSL 的 $USER 是 Linux 用户名(如 fariel),但 Windows 用户目录可能是
# Administrator / 其它名字 → 不能写死,要探测。
detect_downloads() {
    local cands=(
        "/mnt/c/Users/Administrator/Downloads"
        "/mnt/c/Users/${USER}/Downloads"
        "/mnt/c/Users/Public/Downloads"
    )
    # 也扫 /mnt/c/Users/ 下所有用户的 Downloads
    if [ -d /mnt/c/Users ]; then
        for d in /mnt/c/Users/*/Downloads; do
            [ -d "$d" ] && cands+=("$d")
        done
    fi
    for d in "${cands[@]}"; do
        if [ -d "$d" ]; then
            echo "$d"
            return 0
        fi
    done
    return 1
}

DOWNLOADS=$(detect_downloads) || DOWNLOADS="/mnt/c/Users/Administrator/Downloads"
say "=== manual_install.sh 开始 $(date '+%Y-%m-%d %H:%M:%S') ==="
say "Windows 下载目录:$DOWNLOADS"
echo ""

# ---------- 找文件(多候选名)----------
find_file() {
    local primary="$1"; shift
    for name in "$primary" "$@"; do
        local p="$DOWNLOADS/$name"
        if [ -f "$p" ] && [ -s "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

ELAN_TGZ=$(find_file "elan.tar.gz"  "elan-x86_64-unknown-linux-gnu.tar.gz" 2>/dev/null) || ELAN_TGZ=""
LEAN_ZST=$(find_file "lean.tar.zst" "lean-${VER_LEAN}-linux.tar.zst" "$HOME/lean-${VER_LEAN}-linux.tar.zst" 2>/dev/null) || LEAN_ZST=""
DAFNY_ZIP=$(find_file "dafny.zip"   "dafny-${VER_DAFNY}-x64-ubuntu-22.04.zip" 2>/dev/null) || DAFNY_ZIP=""

# Lean 是否只有 .crdownload 片段
LEAN_PARTIAL=$(find_file "lean-${VER_LEAN}-linux.tar.zst.crdownload" 2>/dev/null) || LEAN_PARTIAL=""

# ---------- 魔数校验 ----------
check_magic() {
    local f="$1" expect="$2"
    [ -n "$f" ] && [ -f "$f" ] || return 1
    local sz; sz=$(du -h "$f" | cut -f1)
    local magic; magic=$(head -c4 "$f" | od -An -tx1 | tr -d ' \n')
    case "$expect" in
        gzip) [ "${magic:0:4}" = "1f8b" ]   || { say "❌ $(basename "$f") ($sz) magic=$magic 非 gzip"; return 1; } ;;
        zstd) [ "${magic:0:6}" = "28b52f" ] || { say "❌ $(basename "$f") ($sz) magic=$magic 非 zstd";  return 1; } ;;
        zip)  [ "${magic:0:4}" = "504b" ]   || { say "❌ $(basename "$f") ($sz) magic=$magic 非 zip";   return 1; } ;;
    esac
    say "✅ $(basename "$f") ($sz) magic=$magic"
    return 0
}

say "── 文件检查 ──"
ELAN_OK=0; LEAN_OK=0; DAFNY_OK=0
# Lean 先查完整件,再查 zstd CRC
check_magic "$ELAN_TGZ" gzip && ELAN_OK=1
if [ -n "$LEAN_ZST" ] && check_magic "$LEAN_ZST" zstd; then
    if command -v unzstd >/dev/null 2>&1 && unzstd -t "$LEAN_ZST" >/dev/null 2>&1; then
        say "   (zstd CRC 通过,文件完整)"
        LEAN_OK=1
    else
        say "⚠️  $(basename "$LEAN_ZST") 头部对但 CRC 不完整 → 需要续传"
    fi
fi
check_magic "$DAFNY_ZIP" zip && DAFNY_OK=1

# Lean 只有片段 → 明确指引
if [ "$LEAN_OK" = "0" ] && [ -n "$LEAN_PARTIAL" ]; then
    PSIZE=$(stat -c%s "$LEAN_PARTIAL" 2>/dev/null || echo 0)
    say "⚠️  发现 Lean 半成品:$LEAN_PARTIAL ($((PSIZE/1048576)) MiB)"
    say "   它是有效的已下载部分,不要删!先续传剩余:"
    say "     bash scripts/wsl/resume_lean.sh"
elif [ "$LEAN_OK" = "0" ] && [ -z "$LEAN_ZST" ]; then
    say "⚠️  没找到 Lean toolchain 文件。需要下载:"
    say "   https://github.com/leanprover/lean4/releases/download/v${VER_LEAN}/lean-${VER_LEAN}-linux.tar.zst"
    say "   放进 $DOWNLOADS 后重跑本脚本"
fi
echo ""

# ---------- 检查已装状态 ----------
LAKE_OK=0; DAFNY_INSTALLED=0; ELAN_OK_INSTALLED=0
command -v lake  >/dev/null 2>&1 && LAKE_OK=1
command -v dafny >/dev/null 2>&1 && DAFNY_INSTALLED=1
[ -x "$HOME/.elan/bin/elan" ] && ELAN_OK_INSTALLED=1

say "── 当前状态 ──"
say "  elan 已装: $ELAN_OK_INSTALLED    lake 已装: $LAKE_OK    dafny 已装: $DAFNY_INSTALLED"
echo ""

# 如果全装好了,直接退出
if [ "$LAKE_OK" = "1" ] && [ "$DAFNY_INSTALLED" = "1" ] && [ "$ELAN_OK_INSTALLED" = "1" ]; then
    say "✅ Lean / Dafny / elan 全部已就位,无需安装。"
    say "   要重装请先手动删除 ~/.elan 和 /opt/dafny"
    print_summary
    exit 0
fi

# ---------- 装 elan ----------
if [ "$ELAN_OK_INSTALLED" = "1" ]; then
    say "📦 elan 已装,跳过"
elif [ "$ELAN_OK" = "1" ]; then
    say "📦 安装 elan → ~/.elan"
    mkdir -p "$HOME/.elan"
    if tar -xzf "$ELAN_TGZ" -C "$HOME/.elan" --strip-components=1 2>/dev/null; then
        :
    else
        # 顶层结构不对,试探测模式
        EXTRACT=/tmp/elan_extract
        rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
        tar -xzf "$ELAN_TGZ" -C "$EXTRACT" || { say "❌ elan 解压失败"; exit 1; }
        TOP=$(ls "$EXTRACT" | head -1)
        rm -rf "$HOME/.elan" && mkdir -p "$HOME/.elan"
        if [ -x "$EXTRACT/$TOP/bin/elan" ]; then
            cp -r "$EXTRACT/$TOP/." "$HOME/.elan/"
        elif [ -x "$EXTRACT/bin/elan" ]; then
            cp -r "$EXTRACT/." "$HOME/.elan/"
        else
            say "❌ elan tarball 结构未知"; find "$EXTRACT" -maxdepth 3 | head -10; exit 1
        fi
        rm -rf "$EXTRACT"
    fi
    [ -x "$HOME/.elan/bin/elan" ] || { say "❌ 解压后 \$HOME/.elan/bin/elan 不存在"; exit 1; }
    say "✅ elan: $($HOME/.elan/bin/elan --version 2>&1 | head -1)"
else
    say "⚠️  跳过 elan:没找到有效的 elan.tar.gz"
    say "   下载:https://github.com/leanprover/elan/releases/download/v3.1.0/elan-x86_64-unknown-linux-gnu.tar.gz"
fi

export PATH="$HOME/.elan/bin:$PATH"
if ! grep -q '\.elan/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
fi
echo ""

# ---------- 装 Lean toolchain ----------
if [ "$LAKE_OK" = "1" ]; then
    say "📦 Lean 已装,跳过:$(lake --version 2>&1 | head -1)"
elif [ "$LEAN_OK" = "1" ]; then
    say "📦 安装 Lean ${VER_LEAN} → ~/.elan/toolchains/lean-${VER_LEAN}/"
    mkdir -p "$HOME/.elan/toolchains"
    rm -rf "$HOME/.elan/toolchains/lean-${VER_LEAN}"
    mkdir -p "$HOME/.elan/toolchains/lean-${VER_LEAN}"

    EXTRACT=/tmp/lean_extract
    rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
    tar --use-compress-program=unzstd -xf "$LEAN_ZST" -C "$EXTRACT" \
        || tar -xzf "$LEAN_ZST" -C "$EXTRACT" \
        || { say "❌ Lean 解压失败,文件可能仍损坏"; exit 1; }
    TOP=$(ls "$EXTRACT" | head -1)
    say "   tarball 顶层:$TOP"
    if [ -x "$EXTRACT/$TOP/bin/lake" ]; then
        cp -r "$EXTRACT/$TOP/." "$HOME/.elan/toolchains/lean-${VER_LEAN}/"
    elif [ -x "$EXTRACT/bin/lake" ]; then
        cp -r "$EXTRACT/." "$HOME/.elan/toolchains/lean-${VER_LEAN}/"
    else
        say "❌ Lean 解后找不到 bin/lake"; find "$EXTRACT" -maxdepth 3 -type f | head -10; exit 1
    fi
    rm -rf "$EXTRACT"
    ln -sfn "$HOME/.elan/toolchains/lean-${VER_LEAN}" "$HOME/.elan/toolchains/stable"

    if [ ! -x "$HOME/.elan/toolchains/lean-${VER_LEAN}/bin/lake" ]; then
        say "❌ 装完 lake binary 仍不存在"; exit 1
    fi
    # 用 elan 注册(若 elan 在)
    if command -v elan >/dev/null 2>&1; then
        elan toolchain link "${VER_LEAN}" "$HOME/.elan/toolchains/lean-${VER_LEAN}" 2>&1 | tail -1
        elan default "${VER_LEAN}" 2>&1 | tail -1
    fi
    export PATH="$HOME/.elan/bin:$PATH"
    say "✅ lake: $(lake --version 2>&1 | head -1)"
else
    say "⚠️  跳过 Lean:没有完整文件,先跑续传:"
    say "     bash scripts/wsl/resume_lean.sh"
fi
echo ""

# ---------- 装 Dafny ----------
if [ "$DAFNY_INSTALLED" = "1" ]; then
    say "📦 Dafny 已装,跳过:$(dafny --version 2>&1 | head -1)"
elif [ "$DAFNY_OK" = "1" ]; then
    say "📦 安装 Dafny ${VER_DAFNY} → /opt/dafny"
    $SUDO rm -rf /opt/dafny && $SUDO mkdir -p /opt/dafny
    $SUDO unzip -q "$DAFNY_ZIP" -d /opt/dafny

    DAFNY_HOME=$(ls -d /opt/dafny/dafny-*/ 2>/dev/null | head -1)
    [ -z "$DAFNY_HOME" ] && DAFNY_HOME=/opt/dafny
    DAFNY_BIN=$(ls "$DAFNY_HOME"/dafny "$DAFNY_HOME"/bin/dafny 2>/dev/null | head -1)
    if [ -z "$DAFNY_BIN" ]; then
        say "❌ Dafny 解后找不到可执行"; find /opt/dafny -maxdepth 3 -name 'dafny*' -type f | head -5; exit 1
    fi
    $SUDO chmod +x "$DAFNY_BIN"
    $SUDO ln -sf "$DAFNY_BIN" /usr/local/bin/dafny
    say "✅ dafny: $(dafny --version 2>&1 | head -1)"
else
    say "⚠️  跳过 Dafny:没找到有效的 dafny.zip"
    say "   下载:https://github.com/dafny-lang/dafny/releases/download/v${VER_DAFNY}/dafny-${VER_DAFNY}-x64-ubuntu-22.04.zip"
fi
echo ""

# ---------- Dafny 验证测试 ----------
if command -v dafny >/dev/null 2>&1; then
    say "🧪 Dafny verify 测试(Abs 定理):"
    cat > /tmp/hello.dfy <<'EOF'
method Abs(x: int) returns (y: int)
  ensures y >= 0
  ensures y == x || y == -x
{ if x >= 0 { y := x; } else { y := -x; } }
EOF
    dafny verify /tmp/hello.dfy 2>&1 | tail -3
fi

# ---------- Lean 项目脚手架 ----------
if command -v lake >/dev/null 2>&1; then
    say ""
    say "📚 Lean 项目脚手架 ~/verigis/lean4_proj"
    mkdir -p ~/verigis/lean4_proj
    cd ~/verigis/lean4_proj
    if [ ! -f lakefile.lean ] && [ ! -f lakefile.toml ]; then
        lake new verigis 2>&1 | tail -3
    fi
    if [ -f lakefile.lean ] && ! grep -q mathlib lakefile.lean; then
        cat >> lakefile.lean <<'EOF'

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"@"master"
EOF
        say "   mathlib 依赖已挂。首次构建 30–60 min,手动跑:"
        say "     cd ~/verigis/lean4_proj && lake build"
    else
        say "   项目已存在"
    fi
fi

# ---------- 汇总 ----------
print_summary

say ""
say "下一步:新开终端(或 source ~/.bashrc)让 PATH 生效"
