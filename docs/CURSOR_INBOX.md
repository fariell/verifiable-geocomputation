# CURSOR_INBOX — 洛书 → Cursor 指令信箱

> 这是洛书与 Cursor 的**直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),
> Cursor 读它执行,把结果写回 `docs/CURSOR_OUTBOX.md`,再把本文件 STATUS 改成 DONE。
> 任何人都不需要复制粘贴这段文字。

---

## §A · 当前活跃任务(读这个)

STATUS: PENDING
UPDATED: 2026-09-06 17:55
TASK: **task7 · P-COMP-1 = P-002 ∘ P-006 组合证明 + P-006 第 6 条 `TerminatesUnderStrictDescent`**

### A.1 一次性自检(开始前回答,一行一句)
1. 你的内部任务编号是不是 `task7 / P-COMP-1 + 第 6 条`?不一致就报你自己的。
2. 当前 working tree 头部是不是 `8ce0ee6`?不对就报 HEAD。
3. `formal/dafny/P006_watershed.dfy:14` 是不是 `include "P005_d8.dfy"`?import 链不在就先 `git checkout 8ce0ee6 -- formal/`。
4. `P006_README.md` 是否已在"没证什么"写明第 6 条 PENDING?这是本任务的动机,不是漏。

### A.2 任务范围(scope)

**任务 A · P-COMP-1 = P-002 ∘ P-006**(七件套)
- 命题:**填洼 ⇒ 流域唯一**;层 A 沿用 P-006 `BasinUnique` 不重写,只证 (i)~(iv)
- 骨架已在 `docs/phase2/PROP_CHAIN.md` §2.2(五步)
- **可执行 import 接口面见 `PROP_CHAIN.md` §2.4**(洛书 17:55 补)

**任务 B · 第 6 条 `TerminatesUnderStrictDescent`**(独立 8 件套,可与 A 同 session)
- 即"严格下降 ⇒ 终止",走 `Nat.lt_wfRel` / `WellFounded`
- 完成后回头升级 `P006_README.md` 的 "PENDING" 为"PASS" +
  同步升 `scripts/autodl/verify_all.sh` 加此闸

### A.3 七件套 + 第 6 条增量

| # | 路径 | 类型 | 要点 |
|---|---|---|---|
| 1 | `experiments/phase2/p_comp_1.py` | driver | `from p005_d8 / p006_watershed / p002_pit_filling_2d import …` |
| 2 | `experiments/phase2/p_comp_1.wl` | Wolfram | 鸽笼 4^k 穷举 |
| 3 | `experiments/phase2/p_comp_1_manim.py` | manim | 左:不填洼→flat 环;右:填洼→唯一出口 |
| 4 | `experiments/phase2/run_p_comp_1.sh` | shell | 云端驱动,`GPB-021 ENTRY: PASS` 收尾 |
| 5 | `formal/dafny/PCOMP_1.dfy` | Dafny | include 三模块;(i)~(v) |
| 6 | `formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean` | Lean | import 三模块,**不翻译 Dafny** |
| 7 | `formal/dafny/PCOMP_1_README.md` | README | 组合策略图 + 反向引用 P-006 README |
| 8 | `formal/dafny/P006_terminate_under_strict.dfy` | Dafny | 第 6 条:严格下降⇒终止 |
| 9 | `formal/lean4/VeriGIS/P006Terminate.lean` | Lean | 同上,mathlib |
| 10 | `formal/dafny/P006_terminate_under_strict_README.md` | README | 第 6 条台账 |

### A.4 强制约束
1. **不复制 P-002/P-005/P-006 核**:`include` / `import` 不写,只引用。
2. **轨道不递归扫描**:`stepN` 仍是归纳,绝不让 solver 找不动点。
3. **第 6 条是科学资产**:即便 P-COMP-1 走通,第 6 条仍独立证明并升级 README。
4. **第 6 条失败标 FAIL,但不阻断 P-COMP-1**(P-COMP-1 §2.4 仍可走鸽笼)。
5. **本机先全绿再上云**:`bash scripts/autodl/verify_all.sh` 本机 0 error 后才上 AutoDL。
6. **OUTBOX 路径**:`docs/CURSOR_OUTBOX.md` 续写在 P-006 段之后,**不要新建文件**。
7. **别改 `this-week.md` / `MEMORY.md` / `docs/phase2/PROP_CHAIN.md`(除非追加)**:洛书自管。
8. **本机 git commit 不 push**:完成后 `git commit -m "feat(phase2): P-COMP-1 + P-006 T6 terminate PASS"`,洛书上传。

### A.5 完成回报格式(继承 CURSOR_LOOP §三)

```
[task]      task7 / P-COMP-1 + 第 6 条
[step]      <本步名>
[cmd]       <实际命令>
[rc]        <退出码>
[key lines] <7 行以内关键输出>
[gates]     <本步验证门>
[verdict]   PASS / FAIL / BLOCKED
[blocker]   <仅 FAIL/BLOCKED 时填>
```

**增量报告必须写**:哪文件新 / 哪文件改 / 哪文件第几行加了什么 / 失败时附整段 Dafny/Lean 输出。

### A.6 完成后自终止

最后把本文件 §A 顶部 STATUS 改为 `DONE`,UPDATED 改为提交时间。OUTBOX 末尾写一句
`P-COMP-1 + T6 verdict = PASS / FAIL / BLOCKED`,洛书一眼判定。

---

## §B · 协议与档案(只读)

### B.1 优先级与新情况(2026-09-06 17:21 PI 决定)
- 17:21 PI 停 git 远端操作 → 本地 commit 仅本地不 push,实验完一次性上传
- 17:24 PI 轮换 autoDL SSH 密码 → 新真值存在 `autoDL登录信息.txt`(.gitignored,行 77)
- 17:48 PI 说"phase1 phase2 草稿可以开始做" → 洛书已落 5 份草稿
- **不要把新密码写进仓库、脚本、OUTBOX 回传** —— 真值只从那一个文件读,ssh 命令从那里拼

### B.2 任务历史(只读,以后每完成一段归档到这里)
- **task6(2026-09-06 17:38-17:48,STATUS=CLOSED)** = P-005 云端复核 + P-006 流域唯一性
  - P-005: dafny 18/0 + lake build OK(17:38 CST)
  - P-006 本机: 4 门控 PASS + manim OK
  - P-006 云端: dafny 20/0 + lake OK + run_p006 3 门控 PASS + wolfram SKIP
  - 第 6 条 PENDING(README 内,P-COMP-1 合并填)
  - 见 `docs/CURSOR_OUTBOX.md` P-005/P-006 段全报告

### B.3 触发器(`.cursorrules` `[mailbox]` 规则契约)
- Cursor session 启动时自动 `Read` 本文件
- STATUS=PENDING → 执行 §A
- STATUS=DONE/CLOSED → 不动
- 改本文件只能由洛书(Cursor 不改 INBOX 优先级/约束/直终态)
