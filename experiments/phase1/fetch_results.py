#!/usr/bin/env python3
"""Download Phase 1 outputs from the remote instance into the local repo for archival."""
import os
import re
import paramiko

LOGIN = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\autoDL登录信息.txt"
REMOTE_HOME = "/root/verigis"
LOCAL = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\experiments\phase1\results"

RESULT_FILES = [
    "phase1_metrics.json", "phase1_slope_compare.png",
    "geoproofbench_v0.1_batch1.json", "geoproofbench_v0.1_batch1.csv",
    "geoproofbench_v0.1_batch1.md",
]
LOG_FILES = ["logs/progress.log", "logs/bootstrap.log"]


def parse_login(path):
    txt = open(path, encoding="utf-8").read()
    m = re.search(r"ssh -p (\d+) (\w+)@([\w.\-]+)", txt)
    port, user, host = int(m.group(1)), m.group(2), m.group(3)
    pw = re.search(r"密码[:：]\s*(\S+)", txt).group(1)
    return host, port, user, pw


def main():
    host, port, user, pw = parse_login(LOGIN)
    os.makedirs(LOCAL, exist_ok=True)
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(host, port=port, username=user, password=pw, timeout=30,
              look_for_keys=False, allow_agent=False)
    sftp = c.open_sftp()
    for fn in RESULT_FILES:
        try:
            sftp.get(REMOTE_HOME + "/results/" + fn, os.path.join(LOCAL, fn))
            print("fetched results/" + fn)
        except Exception as e:
            print("skip results/" + fn, "->", e)
    for fn in LOG_FILES:
        try:
            sftp.get(REMOTE_HOME + "/" + fn, os.path.join(LOCAL, os.path.basename(fn)))
            print("fetched " + fn)
        except Exception as e:
            print("skip " + fn, "->", e)
    sftp.close()
    c.close()
    print("local dir:", LOCAL)


if __name__ == "__main__":
    main()
