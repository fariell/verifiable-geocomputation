#!/usr/bin/env python3
"""Tail the remote VeriGIS progress / bootstrap logs via SSH (password from login file)."""
import sys
import time
import re
import paramiko

LOGIN = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\autoDL登录信息.txt"
REMOTE_HOME = "/root/verigis"


def parse_login(path):
    txt = open(path, encoding="utf-8").read()
    m = re.search(r"ssh -p (\d+) (\w+)@([\w.\-]+)", txt)
    port, user, host = int(m.group(1)), m.group(2), m.group(3)
    pw = re.search(r"密码[:：]\s*(\S+)", txt).group(1)
    return host, port, user, pw


def connect(host, port, user, pw):
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(host, port=port, username=user, password=pw, timeout=30,
              look_for_keys=False, allow_agent=False)
    return c


def read_log(sftp, path, n=4000):
    try:
        with sftp.open(path) as f:
            return f.read().decode("utf-8", "ignore")[-n:]
    except Exception as e:
        return "(log not ready: %s)" % e


def main():
    host, port, user, pw = parse_login(LOGIN)
    c = connect(host, port, user, pw)
    sftp = c.open_sftp()
    print("===== progress.log =====")
    print(read_log(sftp, REMOTE_HOME + "/logs/progress.log"))
    print("\n===== bootstrap.log (tail) =====")
    print(read_log(sftp, REMOTE_HOME + "/logs/bootstrap.log", 2500))
    sftp.close()
    c.close()


if __name__ == "__main__":
    # optional: monitor.py <seconds> to poll
    wait = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    if wait:
        time.sleep(wait)
    main()
