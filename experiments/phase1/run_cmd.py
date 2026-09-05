#!/usr/bin/env python3
"""Run a command on the remote and print its output (timeout via paramiko channel)."""
import sys
import re
import paramiko

LOGIN = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\autoDL登录信息.txt"


def parse_login(path):
    txt = open(path, encoding="utf-8").read()
    m = re.search(r"ssh -p (\d+) (\w+)@([\w.\-]+)", txt)
    port, user, host = int(m.group(1)), m.group(2), m.group(3)
    pw = re.search(r"密码[:：]\s*(\S+)", txt).group(1)
    return host, port, user, pw


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "echo ok"
    host, port, user, pw = parse_login(LOGIN)
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(host, port=port, username=user, password=pw, timeout=30,
              look_for_keys=False, allow_agent=False)
    stdin, stdout, stderr = c.exec_command(cmd, timeout=40)
    out = stdout.read().decode("utf-8", "ignore")
    err = stderr.read().decode("utf-8", "ignore")
    print("=== stdout ===\n" + out)
    if err.strip():
        print("=== stderr ===\n" + err)
    c.close()


if __name__ == "__main__":
    main()
