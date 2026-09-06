# CURSOR_INBOX — 洛书 → Cursor 指令信箱

> 这是洛书与 Cursor 的**直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),
> Cursor 读它执行,把结果写回 `docs/CURSOR_OUTBOX.md`,再把本文件 STATUS 改成 DONE。
> 任何人都不需要复制粘贴这段文字。

---

STATUS: PENDING
UPDATED: 2026-09-06 16:32
TASK: task6 / P-006 (GPB-015 流域唯一性)

---

## 指令(读 docs/CURSOR_LOOP.md 与 docs/TASK6_BRIEF.md 后执行)

先回答两件事(一句话即可):
1. 你内部的 task6 是不是「P-006 = GPB-015 流域唯一性」?不一致就说明你的编号。
2. P-005 的云端 dafny verify + lake build 是否已做?未做先按 BRIEF §五结算。

确认后开工 P-006,严格按 BRIEF §三的 7 个文件与 §四的 10 条经验做。
重点:
- 层 A(唯一性)与层 B(终止性)分开;终止性做不动就标 PENDING,先保证前 5 条引理。
- 层 B 的 flat 环反例(P-006b)是科学资产,必须写进 README「没证什么」。
- 轨道迭代用有界展开 stepN(h,c,n) 对 n 归纳,不要递归扫描(经验 E1)。
- D8 核从 p005_d8 import,不要复制。
- 本地先全绿再上云;每步回传用 CURSOR_LOOP §三的回报格式,**写入 docs/CURSOR_OUTBOX.md**。

完成后:把本文件 STATUS 改为 DONE、UPDATED 改为当前时间;结果已在 OUTBOX。
