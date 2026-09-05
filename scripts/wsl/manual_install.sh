#!/usr/bin/env bash
#
# manual_install.sh — 当网络根本到不了 GitHub/镜像时的最后退路
#
# 用法(在 WSL bash 里):
#   1. 在另一台能上 GitHub 的设备(手机+流量也行)下载下面四个文件:
#      - elan:  https://github.com/leanprover/elan/releases/download/v3.1.0/elan-x86_64-unknown-linux-gnu.tar.gz
#      - lean:  https://github.com/leanprover/lean4/releases/download/v4.18.0/lean-4.18.0-linux.tar.zst
#      - dafny: https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip
#
#   2. 把它们丢进 WSL 的 /mnt/c/Users/<你的用户名>/Downloads/ 目录
#      (即 WSL 内 /mnt/c/Users/<user>/Downloads/),重命名为:
#        /mnt/c/Users/<user>/Downloads/elan.tar.gz
#        /mnt/c/Users/<user>/Downloads/lean.tar.zst
#        /mnt/c/Users/<user>/Downloads/dafny.zip
#
#   3. 然后跑:
#        bash scripts/wsl/manual_install.sh
#
#   这个脚本会:
#     a) 用文件魔数(magic bytes)校验三个文件,坏文件立即报错
#     b) 把 elan 解到 ~/.elan,跑 `elan toolchain install stable`
#        (这一步如果你 lean.tar.zst 已经在本地,会跳过下载,直接用它)
#     c) 把 lean 解到 ~/.elan/toolchains/lean-4.18.0/,并 symlink 到 stable
#     d) 把 dafny 解到 /opt/dafny,符号链到 /usr/local/bin/dafny
#     e) 跑 dafny verify /tmp/hello.dfy 验证一条 Abs 定理
#
# 任意一步失败,脚本 exit 1 并指明哪一步失败,不会假成功。
#
set -uo pipefail

say()  { printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

DOWNLOADS="/mnt/c/Users/${USER}/Downloads"
ELAN_TGZ="$DOWNLOADS/elan.tar.gz"
LEAN_ZST="$DOWNLOADS/lean.tar.zst"
DAFNY_ZIP="$DOWNLOADS/dafny.zip"

say "=== manual_install.sh 开始 $(date '+%Y-%m-%d %H:%M:%S') ==="
say "期望三个文件位于:"
say "  $ELAN_TGZ"
say "  $LEAN_ZST"
say "  $DAFNY_ZIP"
echo ""

# ---------- 文件存在 + 魔数校验 ----------
check_magic() {
    local f="$1" expect="$2"
    [ -f "$f" ] || { say "❌ 缺文件:$f"; return 1; }
    local sz; sz=$(du -h "$f" | cut -f1)
    local magic; magic=$(head -c4 "$f" | od -An -tx1 | tr -d ' \n')
    case "$expect" in
        gzip)  [ "${magic:0:4}" = "1f8b" ] || { say "❌ $f ($sz) magic=$magic,期望 gzip 1f8b..."; return 1; } ;;
        zstd)  [ "${magic:0:6}" = "28b52f" ] || { say "❌ $f ($sz) magic=$magic,期望 zstd 28b52ffd..."; return 1; } ;;
        zip)   [ "${magic:0:4}" = "504b" ] || { say "❌ $f ($sz) magic=$magic,期望 zip 504b03..."; return 1; } ;;
    esac
    say "✅ $f ($sz) magic=$magic"
    return 0
}

ELAN_OK=0; LEAN_OK=0; DAFNY_OK=0
check_magic "$ELAN_TGZ" gzip && ELAN_OK=1
check_magic "$LEAN_ZST" zstd && LEAN_OK=1
check_magic "$DAFNY_ZIP" zip && DAFNY_OK=1

if [ "$ELAN_OK$LEAN_OK$DAFNY_OK" != "111" ]; then
    say ""
    say "⚠️  三个文件中至少一个不通过校验。请确认:"
    say "  - 文件名是否重命名为 elan.tar.gz / lean.tar.zst / dafny.zip"
    say "  - 文件大小 > 1MB(elan 4M+,lean 250M+,dafny 16M+)"
    say "  - 是否下错版本(v4.18.0 的 lean tarball 必须含 v 前缀 URL,但文件名无 v)"
    say "  - 下载源:建议用 GitHub release 直链或 gh-proxy.com"
    say ""
    say "Lean 4 toolchain 准确 URL:"
    say "  https://github.com/leanprover/lean4/releases/download/v4.18.0/lean-4.18.0-linux.tar.zst"
    exit 1
fi
echo ""

# ---------- 装 elan ----------
say "📦 安装 elan → ~/.elan"
mkdir -p "$HOME/.elan"
tar -xzf "$ELAN_TGZ" -C "$HOME/.elan" --strip-components=1 \
    || { say "❌ elan tar 解压失败,文件可能损坏"; exit 1; }
[ -x "$HOME/.elan/bin/elan" ] || { say "❌ 解压后 \$HOME/.elan/bin/elan 不存在"; exit 1; }
say "✅ elan: \$($HOME/.elan/bin/elan --version 2>&1 | head -1)"

# PATH
export PATH="$HOME/.elan/bin:$PATH"
if ! grep -q '\.elan/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
fi

# ---------- 装 lean 4 toolchain (直接放,跳过 elan 自带下载)----------
say ""
say "📦 安装 Lean 4 toolchain → ~/.elan/toolchains/lean-4.18.0/"
mkdir -p "$HOME/.elan/toolchains"
rm -rf "$HOME/.elan/toolchains/lean-4.18.0"
mkdir -p "$HOME/.elan/toolchains/lean-4.18.0"

# Lean tarball 顶层是 lean-4.18.0-linux/,先解到临时探测
EXTRACT=/tmp/lean_extract
rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
tar --use-compress-program=unzstd -xf "$LEAN_ZST" -C "$EXTRACT" \
    || tar -xzf "$LEAN_ZST" -C "$EXTRACT"
TOP=$(ls "$EXTRACT" | head -1)
say "  Lean tarball 顶层目录:$TOP"

if [ -x "$EXTRACT/$TOP/bin/lake" ]; then
    cp -r "$EXTRACT/$TOP/." "$HOME/.elan/toolchains/lean-4.18.0/"
elif [ -x "$EXTRACT/bin/lake" ]; then
    cp -r "$EXTRACT/." "$HOME/.elan/toolchains/lean-4.18.0/"
else
    say "❌ Lean tarball 解后找不到 bin/lake,实际结构:"
    find "$EXTRACT" -maxdepth 3 -type f | head -10
    exit 1
fi
rm -rf "$EXTRACT"

ln -sfn "$HOME/.elan/toolchains/lean-4.18.0" "$HOME/.elan/toolchains/stable"
[ -x "$HOME/.elan/toolchains/lean-4.18.0/bin/lake" ] \
    || { say "❌ 装完 lake binary 仍不存在"; exit 1; }
say "✅ lake: \$($HOME/.elan/toolchains/lean-4.18.0/bin/lake --version 2>&1 | head -1)"

# ---------- 装 Dafny ----------
say ""
say "📦 安装 Dafny 4.11.0 → /opt/dafny + 符号链 /usr/local/bin/dafny"
$SUDO rm -rf /opt/dafny
$SUDO mkdir -p /opt/dafny
$SUDO unzip -q "$DAFNY_ZIP" -d /opt/dafny

# Dafny zip 通常解出 /opt/dafny/dafny-4.11.0/ 或平铺
DAFNY_HOME=$(ls -d /opt/dafny/dafny-*/ 2>/dev/null | head -1)
[ -z "$DAFNY_HOME" ] && DAFNY_HOME=/opt/dafny
DAFNY_BIN=$(ls "$DAFNY_HOME"/dafny "$DAFNY_HOME"/bin/dafny 2>/dev/null | head -1)
if [ -z "$DAFNY_BIN" ]; then
    say "❌ Dafny zip 解后找不到 dafny 可执行,实际结构:"
    find /opt/dafny -maxdepth 3 -name 'dafny*' -type f | head -5
    exit 1
fi
$SUDO chmod +x "$DAFNY_BIN"
$SUDO ln -sf "$DAFNY_BIN" /usr/local/bin/dafny
say "✅ dafny: \$($DAFNY_BIN --version 2>&1 | head -1)"

# ---------- 验证 Dafny 可证一条小定理 ----------
say ""
say "🧪 Dafny verify 测试(Abs 定理):"
cat > /tmp/hello.dfy <<'EOF'
method Abs(x: int) returns (y: int)
  ensures y >= 0
  ensures y == x || y == -x
{ if x >= 0 { y := x; } else { y := -x; } }
EOF
dafny verify /tmp/hello.dfy 2>&1 | tail -3

# ---------- 装 mathlib 项目脚手架(非阻塞)----------
say ""
say "📚 Lean 项目脚手架 ~/verigis/lean4_proj(数学库首次构建 30–60 min)"
mkdir -p ~/verigis/lean4_proj
cd ~/verigis/lean4_proj
if [ ! -f lakefile.lean ]; then
    lake new verigis 2>&1 | tail -3
fi
if [ -f lakefile.lean ] && ! grep -q mathlib lakefile.lean; then
    cat >> lakefile.lean <<'EOF'

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"@"master"
EOF
    say "  mathlib 已挂上。手动构建:"
    say "    cd ~/verigis/lean4_proj && lake build"
else
    say "  Lean 项目已存在"
fi

# ---------- 收尾 ----------
say ""
say "===== ✅ 安装完成 ====="
printf "  %-22s %s\n" "gdalinfo :"  "$(gdalinfo --version 2>&1)"
printf "  %-22s %s\n" "lake     :"  "$(lake --version 2>&1 | head -1)"
printf "  %-22s %s\n" "dafny    :"  "$(dafny --version 2>&1 | head -1)"
# shellcheck disable=SC1091
source ~/verigis/venv/bin/activate 2>/dev/null
printf "  %-22s %s\n" "venv py  :"  "$(python -c 'import sys; print(sys.prefix)' 2>&1)"

say ""
say "下一步:"
say "  1. 新开 WSL 终端(或 source ~/.bashrc)让 PATH 生效"
say "  2. 测试 lake:demo Lean 项目 'cd ~/verigis/lean4_proj && lake build' 拉 mathlib(30–60 min)"
say "  3. 测试 dafny:dafny verify /tmp/hello.dfy 看上面输出"
say ""
say "手动安装日志已写入 ~/wsl_manual.log"
