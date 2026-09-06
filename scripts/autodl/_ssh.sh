# scripts/autodl/_ssh.sh
# 由 sync_push.sh / results_pull.sh source。提供 autodl_ssh / autodl_scp。
# 优先 sshpass;没有则用 OpenSSH 的 SSH_ASKPASS_REQUIRE=force(WSL 无需再装 sshpass)。

_ad_ssh_opts=(-o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no)

_ad_make_askpass() {
    _AD_ASKPASS="/tmp/autodl_askpass_$$.sh"
    umask 077
    printf '#!/bin/sh\ncat %q\n' "$PWD_FILE" > "$_AD_ASKPASS"
    chmod 700 "$_AD_ASKPASS"
}

_ad_cleanup_askpass() {
    [ -n "${_AD_ASKPASS:-}" ] && rm -f "$_AD_ASKPASS"
}
trap _ad_cleanup_askpass EXIT

_ad_ssh_env() {
    _ad_make_askpass
    export SSH_ASKPASS="$_AD_ASKPASS"
    export SSH_ASKPASS_REQUIRE=force
    export DISPLAY="${DISPLAY:-dummy}"
}

autodl_ssh() {
    if command -v sshpass >/dev/null 2>&1; then
        sshpass -f "$PWD_FILE" ssh -p "$PORT" "${_ad_ssh_opts[@]}" "$@"
        return
    fi
    _ad_ssh_env
    if command -v setsid >/dev/null 2>&1; then
        setsid -w ssh -p "$PORT" "${_ad_ssh_opts[@]}" "$@"
    else
        ssh -p "$PORT" "${_ad_ssh_opts[@]}" "$@" < /dev/null
    fi
}

autodl_scp() {
    if command -v sshpass >/dev/null 2>&1; then
        sshpass -f "$PWD_FILE" scp -P "$PORT" "${_ad_ssh_opts[@]}" "$@"
        return
    fi
    _ad_ssh_env
    if command -v setsid >/dev/null 2>&1; then
        setsid -w scp -P "$PORT" "${_ad_ssh_opts[@]}" "$@"
    else
        scp -P "$PORT" "${_ad_ssh_opts[@]}" "$@" < /dev/null
    fi
}

if ! command -v ssh >/dev/null 2>&1 || ! command -v scp >/dev/null 2>&1; then
    echo "❌ 需要 ssh 与 scp(OpenSSH 客户端)"
    exit 1
fi
if ! command -v sshpass >/dev/null 2>&1; then
    echo "[autodl ssh] 未安装 sshpass,改用 SSH_ASKPASS(可选: sudo apt-get install -y sshpass)"
fi
