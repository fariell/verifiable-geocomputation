#!/usr/bin/env bash
#
# resume_lean.sh — 断点续传下载 Lean 4 toolchain(针对大文件反复中断的场景)
#
# 背景:lean-4.18.0-linux.tar.zst 约 318 MB,在受限网络里浏览器下载常在
#       270 MB 处中断,且浏览器不支持续传 → 每次重头下,白费流量。
#
# 本脚本做的事:
#   1. 找到浏览器留下的 .crdownload 片段(那不是垃圾,是真实的已下载部分)
#   2. 搬到 WSL 本地 ~/ 目录(ext4 比 /mnt/c 跨文件系统快得多)
#   3. 用 curl -C - 从断点续传剩余部分,失败自动重试(最多 30 次)
#   4. 下完校验:文件大小 == 远程 Content-Length,magic bytes == 28b52ffd
#   5. 解压到 ~/.elan/toolchains/lean-4.18.0/ 并 symlink 到 stable
#
# 用法(在 WSL bash 里):
#   bash scripts/wsl/resume_lean.sh
#
# 想换其它 URL / 版本:改下面 URL 和 VER 即可。
#
set -uo pipefail

say() { printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }

VER="4.18.0"
URL="https://github.com/leanprover/lean4/releases/download/v${VER}/lean-${VER}-linux.tar.zst"
WIN_DL="/mnt/c/Users/Administrator/Downloads"
PARTIAL="$WIN_DL/lean-${VER}-linux.tar.zst.crdownload"
TARGET="$HOME/lean-${VER}-linux.tar.zst"

say "=== resume_lean.sh 开始 $(date '+%Y-%m-%d %H:%M:%S') ==="
say "目标:$URL"
echo ""

# ---------- 1. 找已下载片段 ----------
BASE=""
# 优先:WSL 本地已有的目标文件
if [ -f "$TARGET" ] && [ -s "$TARGET" ]; then
    BASE="$TARGET"
    say "✅ 发现 WSL 本地已有片段:$TARGET"
# 其次:Windows 下载目录里的 .crdownload
elif [ -f "$PARTIAL" ] && [ -s "$PARTIAL" ]; then
    say "✅ 发现浏览器残留片段:$PARTIAL"
    say "   搬到 WSL 本地(ext4 更快)..."
    cp "$PARTIAL" "$TARGET" || { say "❌ 复制失败"; exit 1; }
    BASE="$TARGET"
fi

# ---------- 2. 拿远程文件大小 ----------
# 注意:受限网络里 curl -I 可能拿不到 header(HTTP 000)。拿不到不要紧,
# 完成判断最终靠 unzstd -t 的 CRC 校验,比 Content-Length 更可靠。
say ""
say "查询远程文件大小..."
SIZE_REMOTE=$(curl -sIL --max-time 60 "$URL" 2>/dev/null \
    | grep -i '^content-length' | tail -1 | tr -d '\r' | awk '{print $2}')
if [ -z "$SIZE_REMOTE" ] || [ "$SIZE_REMOTE" = "0" ]; then
    say "⚠️  拿不到远程 Content-Length(网络受限),完成判断将依赖 unzstd -t"
    SIZE_REMOTE=-1
else
    say "远程大小: $SIZE_REMOTE bytes ($((SIZE_REMOTE/1048576)) MiB)"
fi

# ---------- 3. 循环续传 ----------
# zstd 完整性测试:能过 CRC 才算真下载完整(比 Content-Length 可靠)
zstd_ok() {
    [ -f "$TARGET" ] || return 1
    [ "$(head -c4 "$TARGET" | od -An -tx1 | tr -d ' \n')" = "28b52ffd" ] || return 1
    command -v unzstd >/dev/null 2>&1 || return 1
    unzstd -t "$TARGET" >/dev/null 2>&1
}

say ""
if [ -n "$BASE" ]; then
    SIZE_LOCAL=$(stat -c%s "$TARGET")
    if [ "$SIZE_REMOTE" -gt 0 ]; then
        say "本地已有: $SIZE_LOCAL bytes ($((SIZE_LOCAL/1048576)) MiB) → 续传剩余 $(( (SIZE_REMOTE-SIZE_LOCAL)/1048576 )) MiB"
    else
        say "本地已有: $SIZE_LOCAL bytes ($((SIZE_LOCAL/1048576)) MiB),续传剩余未知"
    fi
else
    say "没有已有片段,从头下载(建议:遇到中断不要删文件,重跑本脚本即可续传)"
fi
echo ""

MAX_TRIES=30
try=0
while [ "$try" -lt "$MAX_TRIES" ]; do
    try=$((try+1))
    SIZE_LOCAL=0
    [ -f "$TARGET" ] && SIZE_LOCAL=$(stat -c%s "$TARGET")

    # 完成条件 1:大小达标
    if [ "$SIZE_REMOTE" -gt 0 ] && [ "$SIZE_LOCAL" -ge "$SIZE_REMOTE" ]; then
        say "✅ 大小已达标 ($SIZE_LOCAL >= $SIZE_REMOTE)"
        break
    fi
    # 完成条件 2:zstd CRC 通过(拿不到 Content-Length 时的裁判)
    if zstd_ok; then
        say "✅ zstd 完整性测试通过,文件已完整"
        break
    fi

    say "── 第 $try/$MAX_TRIES 次续传(从 $((SIZE_LOCAL/1048576)) MiB 处继续,超时 900s)──"
    # -C - : 自动从本地已有的偏移继续;--max-time 900 单次最多 15 min
    curl -C - -sSLfL --max-time 900 -o "$TARGET" "$URL" 2>&1 | tail -2

    SIZE_AFTER=0
    [ -f "$TARGET" ] && SIZE_AFTER=$(stat -c%s "$TARGET")
    DELTA=$((SIZE_AFTER - SIZE_LOCAL))
    if [ "$SIZE_REMOTE" -gt 0 ]; then
        say "   本次增加 $((DELTA/1024)) KiB,累计 $((SIZE_AFTER/1048576)) / $((SIZE_REMOTE/1048576)) MiB"
    else
        say "   本次增加 $((DELTA/1024)) KiB,累计 $((SIZE_AFTER/1048576)) MiB"
    fi

    if [ "$DELTA" -le 0 ]; then
        say "   ⚠️  本次没有进展(服务器不支持 Range?网络断了?),等 5s 重试"
        sleep 5
    fi
done

# ---------- 4. 校验 ----------
say ""
say "===== 校验 ====="
if [ ! -f "$TARGET" ]; then
    say "❌ 文件不存在,下载彻底失败"
    exit 1
fi

SIZE_FINAL=$(stat -c%s "$TARGET")
if [ "$SIZE_REMOTE" -gt 0 ]; then
    say "最终大小: $SIZE_FINAL / $SIZE_REMOTE bytes"
    if [ "$SIZE_FINAL" -lt "$SIZE_REMOTE" ]; then
        say "⚠️  文件不完整(差 $(( (SIZE_REMOTE-SIZE_FINAL)/1048576 )) MiB)。"
        say "   不要删文件——重跑本脚本会从 $((SIZE_FINAL/1048576)) MiB 处继续:"
        say "     bash scripts/wsl/resume_lean.sh"
        exit 1
    fi
else
    say "最终大小: $SIZE_FINAL bytes(远程大小未知,靠 CRC 校验)"
fi

MAGIC=$(head -c4 "$TARGET" | od -An -tx1 | tr -d ' \n')
say "magic bytes: $MAGIC"
if [ "${MAGIC:0:6}" != "28b52f" ]; then
    say "❌ 不是 zstd 文件(期望 28b52ffd),下载被污染"
    rm -f "$TARGET"
    exit 1
fi
say "✅ zstd 头部正确"

# zstd 完整性测试(CRC 校验,最可靠的完整判断)
if command -v unzstd >/dev/null 2>&1; then
    say "测试 zstd 完整性(unzstd -t)..."
    if unzstd -t "$TARGET" 2>&1 | tail -2; then
        say "✅ zstd CRC 校验通过,文件完整"
    else
        say "❌ zstd CRC 校验失败,文件仍不完整"
        say "   不要删文件——重跑本脚本续传:"
        say "     bash scripts/wsl/resume_lean.sh"
        exit 1
    fi
else
    say "⚠️  系统没有 unzstd,跳过 CRC 校验(装:sudo apt install zstd)"
fi

# ---------- 5. 解压到 toolchains ----------
say ""
say "===== 安装到 ~/.elan/toolchains/lean-${VER}/ ====="
export PATH="$HOME/.elan/bin:$PATH"

rm -rf "$HOME/.elan/toolchains/lean-${VER}"
mkdir -p "$HOME/.elan/toolchains"

EXTRACT=/tmp/lean_extract
rm -rf "$EXTRACT" && mkdir -p "$EXTRACT"
if ! tar --use-compress-program=unzstd -xf "$TARGET" -C "$EXTRACT" 2>&1 | tail -3; then
    say "❌ 解压失败(文件可能仍损坏),保留 $TARGET 供重试"
    exit 1
fi

TOP=$(ls "$EXTRACT" | head -1)
say "tarball 顶层目录:$TOP"
mkdir -p "$HOME/.elan/toolchains/lean-${VER}"
if [ -x "$EXTRACT/$TOP/bin/lake" ]; then
    cp -r "$EXTRACT/$TOP/." "$HOME/.elan/toolchains/lean-${VER}/"
elif [ -x "$EXTRACT/bin/lake" ]; then
    cp -r "$EXTRACT/." "$HOME/.elan/toolchains/lean-${VER}/"
else
    say "❌ 解后找不到 bin/lake,实际结构:"
    find "$EXTRACT" -maxdepth 3 -type f | head -10
    exit 1
fi
rm -rf "$EXTRACT"

ln -sfn "$HOME/.elan/toolchains/lean-${VER}" "$HOME/.elan/toolchains/stable"

# ---------- 6. 强校验:lake 必须真能跑 ----------
if [ ! -x "$HOME/.elan/toolchains/lean-${VER}/bin/lake" ]; then
    say "❌ lake binary 不存在"
    exit 1
fi
say "✅ lake: $($HOME/.elan/toolchains/lean-${VER}/bin/lake --version 2>&1 | head -1)"

# 写 PATH 到 bashrc
if ! grep -q '\.elan/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.elan/bin:$PATH"' >> "$HOME/.bashrc"
    say "已把 elan 写进 ~/.bashrc"
fi

# 用 elan 注册(若 elan 在)
if command -v elan >/dev/null 2>&1; then
    elan toolchain link "${VER}" "$HOME/.elan/toolchains/lean-${VER}" 2>&1 | tail -2
    elan default "${VER}" 2>&1 | tail -2
fi

say ""
say "===== ✅ Lean 4 toolchain 安装完成 ====="
printf "  %-18s %s\n" "lake  :" "$(lake --version 2>&1 | head -1)"
printf "  %-18s %s\n" "lean  :" "$(lean --version 2>&1 | head -1)"
say ""
say "下一步(可选):删掉 318 MB 的 tarball 释放空间"
say "  rm -f $TARGET"
say ""
say "再跑 manual_install.sh 把 dafny 装完(它只有 65 MB,已下载好):"
say "  bash scripts/wsl/manual_install.sh"
