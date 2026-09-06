# CURSOR_INBOX — 洛书 → Cursor 指令信箱

> 这是洛书与 Cursor 的**直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),
> Cursor 读它执行,把结果写回 `docs/CURSOR_OUTBOX.md`,再把本文件 STATUS 改成 DONE。
> 任何人都不需要复制粘贴这段文字。

---

## §A · 当前活跃任务(读这个)

STATUS: PENDING
UPDATED: 2026-09-06 18:15
TASK: **task7.5 · AutoDL 云端复核 task7 产物(P-COMP-1 dafny + T6 dafny + P-COMP-1 lake + T6 lake + run_p_comp_1.sh)**

### A.0 前置 read(否则开跑)
1. 读 `docs/CURSOR_OUTBOX.md` 的"task7 = P-COMP-1 + 第 6 条"段(自检 + 4 step 报告)
2. 读 `git log -1 --format='%h %s' → 2fe6a3a feat(phase2): P-COMP-1 + P-006 T6 (numpy/wolfram/manim PASS; formal VERIFY PENDING) Co-authored-by: Cursor`

### A.1 命令模板(5 闸,任意错/漏必须 BLOCKED 报)

```bash
source /etc/network_turbo
source ~/.elan/env
export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/PCOMP_1.dfy'
python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P006_terminate_under_strict.dfy'
cd formal/lean4 && lake build
cd /root/verigis/repo
bash experiments/phase2/run_p_comp_1.sh
```

### A.2 严格不动项
- **不重写代码**(task7 已 commit,本次只复核)
- **不更新 README/PROP_CHAIN**(洛书自管)
- **不 git push**(PI 17:21 stop 还在)
- 报告写到 `docs/CURSOR_OUTBOX.md`,**续在 task7 段之后**,改名"## P-COMP-1 + T6 云端复核(task7.5)"
- 真值仍从 `autoDL登录信息.txt` 读,绝不下地

### A.3 闸门(全部 PASS 才算 task7.5 PASS)

| # | 闸门 | 命令 | 期望 |
|---|---|---|---|
| 1 | P-COMP-1 dafny | `dafny verify PCOMP_1.dfy` | VERIFY > 0 error 0 |
| 2 | T6 dafny | `dafny verify P006_terminate_under_strict.dfy` | VERIFY > 0 error 0 |
| 3 | P-COMP-1 lake | `lake build` 包含 `VeriGIS.Composition.PitFillingThenWatershed` | built |
| 4 | T6 lake | `lake build` 包含 `VeriGIS.P006Terminate` | built |
| 5 | `run_p_comp_1.sh` | `bash experiments/phase2/run_p_comp_1.sh` | 3 门控 PASS + wolfram SKIP |

### A.4 完成后

- INBOX `STATUS: DONE`,UPDATED 改 current ts
- OUTBOX 新增"task7.5"段,5 闸每闸按 CURSOR_LOOP §三 格式
- 末尾总结一句:`task7.5 verdict = PASS / FAIL / BLOCKED`
- **本 commit 内**:把 P006_README.md「没证什么」段第 6 条 `VERIFY PENDING → PASS(已被 task7.5 云端 dafny verify)`
- 不动 `PROP_CHAIN.md` / `this-week.md` / `MEMORY.md` / `*.pdf / *.mp4`(洛书自管)
- git commit `feat(phase2): P-COMP-1 + T6 cloud settle PASS` **或** `feat(phase2): P-COMP-1 + T6 cloud settle FAIL<原因>`(**不 push**)

---

## §B · 协议与档案(只读)

### B.1 优先级与新情况
- 17:21 PI 停 git 远端操作 → 本地 commit 仅本地不 push,实验完一次性上传
- 17:24 PI 轮换 autoDL SSH 密码 → 新真值存 `autoDL登录信息.txt`(.gitignored,行 77)
- 18:13 PI 提醒 Cursor 完工失声 → 已装 `.workbuddy/skills/cursor-done-sentinel.md`
- **不要把新密码写进仓库、脚本、OUTBOX 回传**

### B.2 任务历史(只读,以后每完成一段归档到这里)
- **task6(2026-09-06 17:38-17:48,STATUS=CLOSED)** = P-005 云端复核 + P-006 流域唯一性
  - P-005: dafny 18/0 + lake OK(17:38 CST);P-006 本机+云端 5 闸全绿
  - 第 6 条 PENDING(README 内)
- **task7(2026-09-06 18:08-18:10,STATUS=CLOSED LOCAL)** = P-COMP-1 + 第 6 条 本机段
  - 本机 numpy + wolfram: 4 门控全 PASS(填洼 + 严格下降 + 终止 + P-006b 反例对比)
  - 本机 manim: rc=0, `experiments/phase2/figures/FillThenWatershedStencil.mp4` 166513 B
  - 本机 dafny + 本机 lake: **SKIP / BLOCKED**(本机无 dafny / lake,设计云端跑)
  - commit `2fe6a3a`,19 文件 +1124/-8,`Co-authored-by: Cursor <cursoragent@cursor.com>`
  - 详见 `docs/CURSOR_OUTBOX.md` task7 段

### B.3 触发器(`.cursorrules` `[mailbox]` 规则契约)
- Cursor session 启动时自动 `Read` 本文件
- STATUS=PENDING → 执行 §A
- STATUS=DONE/CLOSED → 不动
- 改本文件只能由洛书(Cursor 不改 INBOX 优先级/约束/直终态)
