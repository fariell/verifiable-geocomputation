# CURSOR_INBOX — 洛书 → Cursor 指令信箱

> 这是洛书与 Cursor 的**直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),
> Cursor 读它执行,把结果写回 `docs/CURSOR_OUTBOX.md`,再把本文件 STATUS 改成 DONE。
> 任何人都不需要复制粘贴这段文字。

---

STATUS: DONE
UPDATED: 2026-09-06 17:48
TASK: **P-005 云端复核(§五)→ P-006 = GPB-015 流域唯一性**

---

## 优先级与新情况

**今天 17:21 PI 已停 git 远端操作**,所有 commit 仅本地不 push;实验做完再一次性上传。

**今天 17:24 PI 已轮换 autoDL SSH 密码**。新真值存在 `autoDL登录信息.txt`(.gitignored,行 77),
**不要把新密码写进仓库、脚本、OUTBOX 回传** —— 真值只从那一个文件读,ssh 命令从那里拼。

---

## 第 1 步(先做!): 结算 P-005 云端复核

严格按 `docs/TASK6_BRIEF.md` §五 执行,**本机不动,直接登 AutoDL**。c829c44 仍写"待云端验",
结清后 OUTBOX 给 [verdict],洛书据此把 c829c44 状态推进。

命令模板:
```bash
# 拼 ssh 命令时从 autoDL登录信息.txt 读真值,只在本会话内存,不落地
source /etc/network_turbo && source ~/.elan/env
export PATH="/usr/local/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P005_d8.dfy'
cd formal/lean4 && lake build
```

判定:
- dafny verify 18/0 + lake build OK → P-005 标 PASS,立刻进入第 2 步
- dafny 报错或 lake 失败 → 报 [blocker],**P-006 不要开工,先修**

## 第 2 步: P-006 = GPB-015 流域唯一性(§三 的 7 个文件 + §四 的 10 条经验)

P-005 verdict = PASS 后才开始。提醒:
- 层 A(唯一性)与层 B(终止性)分开;终止性做不动就标 PENDING,先保证前 5 条引理
- 层 B 的 flat 环反例(P-006b)是科学资产,写进 P006_README.md「没证什么」
- 轨道迭代用有界展开 stepN(h,c,n) 对 n 归纳,不递归扫描(经验 E1)
- D8 核从 p005_d8 import,不复制
- 本地先全绿再上云
- 每步按 `docs/CURSOR_LOOP.md` §三 回报格式写 `docs/CURSOR_OUTBOX.md`,原输出不摘要

完成后把本文件 STATUS 改 DONE、UPDATED 改当前时间;结果已在 OUTBOX。
