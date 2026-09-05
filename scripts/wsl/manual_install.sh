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
    # gdalinfo 可能在 /usr/bin(apt)也可能在 conda env 里;非登录 shell
    # 看不到 conda → 退化显示,别误判成"未安装"
    printf "  %-16s %s\n" "gdalinfo :" "$(command -v gdalinfo >/dev/null 2>&1 \
        && gdalinfo --version 2>&1 || echo '不在当前 PATH(交互终端里再确认)')"
    printf "  %-16s %s\n" "lean     :" "$(command -v lean >/dev/null 2>&1 && lean --version 2>&1 | head -1 || echo '未安装')"
    printf "  %-16s %s\n" "lake     :" "$(command -v lake >/dev/null 2>&1 && lake --version 2>&1 | head -1 || echo '未安装')"
    printf "  %-16s %s\n" "dafny    :" "$(command -v dafny >/dev/null 2>&1 && dafny --version 2>&1 | head -1 || echo '未安装')"
    printf "  %-16s %s\n" "elan     :" "$(command -v elan >/dev/null 2>&1 && elan --version 2>&1 | head -1 || echo '未安装(可选)')"
    # shellcheck disable=SC1091
    # 非登录 bash 不加载 ~/.bashrc → conda base 未激活,可能没有 `python`
    # (只有 python3)。两个都试,别让汇总行假报缺失。
    source ~/verigis/venv/bin/activate 2>/dev/null
    printf "  %-16s %s\n" "venv py  :" "$(command -v python >/dev/null 2>&1 \
        && python -c 'import sys; print(sys.prefix)' 2>&1 \
        || python3 -c 'import sys; print(sys.prefix)' 2>&1)"
}

# ---------- 通用解压:zip 三级回退 ----------
# Ubuntu 22.04 最小化安装默认**没有 unzip**。别假设它在:
#   1) unzip 在 → 直接用
#   2) 不在 → apt-get install unzip(静默,失败不中断)
#   3) 还不行 → python3 -m zipfile(一定在,venv 外也有系统 python3)
# 用法:extract_zip ZIP_PATH DEST_DIR
extract_zip() {
    local zip="$1" dest="$2"
    mkdir -p "$dest" || return 1

    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$zip" -d "$dest" && return 0
    fi

    say "   unzip 不在,尝试 apt-get install unzip ..."
    if $SUDO apt-get install -y unzip >/dev/null 2>&1; then
        unzip -q "$zip" -d "$dest" && return 0
    fi

    say "   apt 装不上,改用 python3 -m zipfile ..."
    python3 - "$zip" "$dest" <<'PY' && return 0
import sys, zipfile
zip_path, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path) as z:
    z.extractall(dest)
PY
    return 1
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
say "  lake 已装: $LAKE_OK     dafny 已装: $DAFNY_INSTALLED     elan: $ELAN_OK_INSTALLED(可选)"
echo ""

# Lean + Dafny 都好了就退出(elan 可选,不作为完成条件)
if [ "$LAKE_OK" = "1" ] && [ "$DAFNY_INSTALLED" = "1" ]; then
    say "✅ Lean / Dafny 已就位,无需安装。"
    say "   要重装请先手动删除 ~/lean-${VER_LEAN} 和 /opt/dafny"
    print_summary
    exit 0
fi

# ---------- elan:可选组件,失败不阻塞主线 ----------
# 关键认知:elan-x86_64-unknown-linux-gnu.tar.gz 里**只有一个 elan-init**,
# 那是 12.9 MB 的 ELF 安装器,不是 elan 二进制——运行它会去联网下载,
# 在当前受限网络里必然失败。
# 而 elan 本身只是 Lean 的版本管理器(类比 rustup 之于 Rust),**并非必需**:
# 只要有 lean-4.18.0-linux.tar.zst 本体,解压后把 bin 加进 PATH 就能直接
# 用 lake / lean。所以这里把 elan 降级为可选。
if [ "$ELAN_OK_INSTALLED" = "1" ]; then
    say "📦 elan 已装,跳过"
elif [ "$ELAN_OK" = "1" ]; then
    if tar -tzf "$ELAN_TGZ" 2>/dev/null | grep -qE '(^|/)bin/elan$'; then
        say "📦 安装 elan → ~/.elan"
        mkdir -p "$HOME/.elan"
        tar -xzf "$ELAN_TGZ" -C "$HOME/.elan" --strip-components=1 2>/dev/null
        if [ -x "$HOME/.elan/bin/elan" ]; then
            say "✅ elan: $($HOME/.elan/bin/elan --version 2>&1 | head -1)"
        else
            say "⚠️  elan 解压后 binary 不在,跳过(不影响 Lean 使用)"
        fi
    else
        say "⚠️  跳过 elan:该 tarball 只含 elan-init(安装器),不是二进制"
        say "    运行它会联网下载,在受限网络里必然失败。"
        say "    **但 elan 并非必需** —— Lean toolchain 本体解压后加 PATH 即可用。"
    fi
else
    say "⚠️  跳过 elan:没找到 elan.tar.gz(不影响 Lean / Dafny)"
fi

export PATH="$HOME/.elan/bin:$PATH"
if ! grep -q '\.elan/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
fi
echo ""

# ---------- 装 Lean toolchain(不依赖 elan,直接解压 + 加 PATH)----------
LEAN_HOME="$HOME/lean-${VER_LEAN}"
if [ "$LAKE_OK" = "1" ]; then
    say "📦 Lean 已装,跳过:$(lake --version 2>&1 | head -1)"
elif [ "$LEAN_OK" = "1" ]; then
    say "📦 安装 Lean ${VER_LEAN} → ${LEAN_HOME}/"
    rm -rf "$LEAN_HOME"
    mkdir -p "$LEAN_HOME"

    EXTRACT=/tmp/lean_extract
    rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
    tar --use-compress-program=unzstd -xf "$LEAN_ZST" -C "$EXTRACT" \
        || tar -xzf "$LEAN_ZST" -C "$EXTRACT" \
        || { say "❌ Lean 解压失败,文件可能仍损坏"; exit 1; }
    TOP=$(ls "$EXTRACT" | head -1)
    say "   tarball 顶层:$TOP"
    if [ -x "$EXTRACT/$TOP/bin/lake" ]; then
        cp -r "$EXTRACT/$TOP/." "$LEAN_HOME/"
    elif [ -x "$EXTRACT/bin/lake" ]; then
        cp -r "$EXTRACT/." "$LEAN_HOME/"
    else
        say "❌ Lean 解后找不到 bin/lake"; find "$EXTRACT" -maxdepth 3 -type f | head -10; exit 1
    fi
    rm -rf "$EXTRACT"

    if [ ! -x "$LEAN_HOME/bin/lake" ]; then
        say "❌ 装完 lake binary 仍不存在"; exit 1
    fi

    # 直接把 toolchain 的 bin 写进 ~/.bashrc(不需要 elan)
    if ! grep -q "lean-${VER_LEAN}/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo "export PATH=\"\$HOME/lean-${VER_LEAN}/bin:\$PATH\"" >> "$HOME/.bashrc"
        say "   已把 \$HOME/lean-${VER_LEAN}/bin 写进 ~/.bashrc"
    fi
    export PATH="$LEAN_HOME/bin:$PATH"
    say "✅ lake: $(lake --version 2>&1 | head -1)"
    say "✅ lean: $(lean --version 2>&1 | head -1)"
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

    # 先解到临时目录再 sudo 搬迁:extract_zip 内部可能用 python,
    # 直接 sudo python 到 /opt 会有权限/属主问题,分两步更稳。
    TMPD=/tmp/dafny_extract
    rm -rf "$TMPD"
    if ! extract_zip "$DAFNY_ZIP" "$TMPD"; then
        say "❌ Dafny zip 解压失败(三级回退全挂)"; exit 1
    fi

    TOP=$(ls "$TMPD" | head -1)
    say "   zip 顶层:$TOP"
    if [ -d "$TMPD/$TOP" ]; then
        $SUDO cp -r "$TMPD/$TOP/." /opt/dafny/
    else
        $SUDO cp -r "$TMPD/." /opt/dafny/
    fi
    rm -rf "$TMPD"

    DAFNY_BIN=$(ls /opt/dafny/dafny /opt/dafny/bin/dafny 2>/dev/null | head -1)
    if [ -z "$DAFNY_BIN" ]; then
        say "❌ Dafny 解后找不到可执行"; find /opt/dafny -maxdepth 3 -name 'dafny*' | head -5; exit 1
    fi
    # zip 不保留 unix 权限位(尤其 python 解压路径)→ 整包补执行位
    $SUDO chmod -R +x /opt/dafny 2>/dev/null
    $SUDO ln -sf "$DAFNY_BIN" /usr/local/bin/dafny
    # Dafny 4.x 自带 .NET runtime,首次运行需要 HOME 可写(已在)
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
