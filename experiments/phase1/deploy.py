#!/usr/bin/env python3
"""Deploy VeriGIS Phase 1 to the remote SeetaCloud instance and launch it.

Reads connection info from the local login file (password never hardcoded),
uploads the experiment package via SFTP, then launches bootstrap.sh detached
so it survives the session. Prints the initial bootstrap log.
"""
import os
import re
import time
import paramiko

LOGIN = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\autoDL登录信息.txt"
LOCAL_PHASE1 = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\experiments\phase1"
REMOTE_HOME = "/root/verigis"


def parse_login(path):
    txt = open(path, encoding="utf-8").read()
    m = re.search(r"ssh -p (\d+) (\w+)@([\w.\-]+)", txt)
    port, user, host = int(m.group(1)), m.group(2), m.group(3)
    mp = re.search(r"密码[:：]\s*(\S+)", txt)
    pw = mp.group(1)
    return host, port, user, pw


def connect(host, port, user, pw):
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(host, port=port, username=user, password=pw, timeout=30,
              look_for_keys=False, allow_agent=False)
    return c


def upload_dir(sftp, local, remote):
    try:
        sftp.mkdir(remote)
    except IOError:
        pass
    for root, _dirs, files in os.walk(local):
        rel = os.path.relpath(root, local)
        rdir = remote if rel == "." else os.path.join(remote, rel).replace("\\", "/")
        try:
            sftp.mkdir(rdir)
        except IOError:
            pass
        for f in files:
            sftp.put(os.path.join(root, f), rdir + "/" + f)


def main():
    host, port, user, pw = parse_login(LOGIN)
    print("connect -> %s:%d %s" % (host, port, user))
    c = connect(host, port, user, pw)
    sftp = c.open_sftp()
    try:
        sftp.mkdir(REMOTE_HOME)
    except IOError:
        pass
    for d in ["logs", "results", "experiments", "lean4_proj", "venv"]:
        try:
            sftp.mkdir(REMOTE_HOME + "/" + d)
        except IOError:
            pass
    print("upload experiments/phase1 ...")
    upload_dir(sftp, LOCAL_PHASE1, REMOTE_HOME + "/experiments/phase1")
    print("upload lean4_proj ...")
    upload_dir(sftp, os.path.join(LOCAL_PHASE1, "lean4_proj"), REMOTE_HOME + "/lean4_proj")
    sftp.close()

    cmd = ("nohup setsid bash %s/experiments/phase1/bootstrap.sh "
           "> %s/logs/bootstrap.log 2>&1 &" % (REMOTE_HOME, REMOTE_HOME))
    c.exec_command(cmd)
    time.sleep(4)

    sftp = c.open_sftp()
    try:
        with sftp.open(REMOTE_HOME + "/logs/bootstrap.log") as f:
            data = f.read().decode("utf-8", "ignore")
        print("=== bootstrap.log (initial) ===")
        print(data[-2500:])
    except Exception as e:
        print("log read err:", e)
    sftp.close()
    c.close()
    print("\nLaunched. Monitor with:")
    print('  ssh -p %d %s@%s "tail -f %s/logs/progress.log"' % (port, user, host, REMOTE_HOME))


if __name__ == "__main__":
    main()
