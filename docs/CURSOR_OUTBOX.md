# CURSOR_OUTBOX — Cursor → 洛书 回报信箱

> Cursor 每次执行完 `docs/CURSOR_INBOX.md` 的指令后,把结果按下面格式写在这里,
> 并把 INBOX 的 STATUS 改为 DONE。洛书直接读本文件判定,不需要任何人复制粘贴。

---

[task]      task6 / P-006
[step]      本地 <wolfram|manim|numpy|dafny|lean>
[cmd]       <实际执行的完整命令>
[rc]        <退出码>
[key lines] <挑 3–8 行关键输出,原样复制,不要改写>
[gates]     PASS / FAIL 逐条列出
[verdict]   PASS / FAIL / BLOCKED
[blocker]   若 FAIL:卡在哪一行、你怀疑什么原因(一句话)

---

> 不要写"一切正常""跑通了"这类摘要 —— 洛书看不到你的终端,摘要等于没说。
> 改完回传时,额外说明:改动了哪个文件哪几行、为什么这么改。
