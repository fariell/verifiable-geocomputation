# scripts/autodl/_load_env.sh
# 由 sync_push.sh / results_pull.sh source,不要直接执行。
# 目的:Windows 上 PowerShell 的 $env: 进不了 WSL/Git Bash,
#      所以改从本机 gitignore 文件读 host/port。
#
# 查找顺序:
#   1. 仓库根 autodl.env          (推荐,gitignore)
#   2. $HOME/.autodl_env
# 已 export 的 AUTODL_SSH_* 不会被空值覆盖(set -a 后后写覆盖先写;
# 因此若文件存在,文件优先。要临时覆盖就改文件或删掉文件再用环境变量)。

_ad_self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ad_root="$(cd "$_ad_self/../.." && pwd)"
_ad_loaded=""
for _ad_f in "$_ad_root/autodl.env" "$HOME/.autodl_env"; do
    if [ -r "$_ad_f" ]; then
        set -a
        # shellcheck disable=SC1090
        . "$_ad_f"
        set +a
        _ad_loaded="$_ad_f"
        break
    fi
done
if [ -n "$_ad_loaded" ]; then
    echo "[autodl env] loaded $_ad_loaded"
fi
unset _ad_self _ad_root _ad_f _ad_loaded
