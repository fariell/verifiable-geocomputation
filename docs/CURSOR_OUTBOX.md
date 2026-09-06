# CURSOR_OUTBOX — Cursor → 洛书 回报信箱

> Cursor 每次执行完 `docs/CURSOR_INBOX.md` 的指令后,把结果按下面格式写在这里,
> 并把 INBOX 的 STATUS 改为 DONE。洛书直接读本文件判定,不需要任何人复制粘贴。

---

## P-005 云端复核(BRIEF §五 / c829c44)

[task]      task6 / P-005 云端复核
[step]      云端 dafny
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:$PATH" && cd /root/verigis/repo && python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P005_d8.dfy'
[rc]        0
[key lines]
🚀  START @ 17:38:48   elapsed 0:00:00
   $  dafny verify formal/dafny/P005_d8.dfy
   log → /root/.workbuddy/jobs/20260906_173848.log
   17:38:50  +    0:01  Dafny program verifier finished with 18 verified, 0 errors   ✅ VERIFY:18 verified / 0 errors
✅  END @ 17:38:50  rc=0  elapsed=0:01  log=/root/.workbuddy/jobs/20260906_173848.log
[gates]     dafny verify P005_d8.dfy: PASS (18 verified / 0 errors)
[verdict]   PASS
[blocker]

---

[task]      task6 / P-005 云端复核
[step]      云端 lean
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:$PATH" && cd /root/verigis/repo/formal/lean4 && lake build
[rc]        0
[key lines]
⣽ [2756/2757] Running VeriGIS (+ 0 more)
Build completed successfully.
[gates]     lake build: PASS (Build completed successfully)
[verdict]   PASS
[blocker]

**P-005 结算:PASS。** c829c44 可从「待云端验」推进。17:38 CST 云端权威: dafny 18/0 + lake build OK。

---

## P-006 = GPB-015 本机

[task]      task6 / P-006
[step]      本地 numpy + wolfram
[cmd]       & "C:\ProgramData\anaconda3\python.exe" experiments/phase1/p006_watershed.py
[rc]        0
[key lines]
  interior n=25 term=25 outlets=[(1, 0), (2, 0), (3, 0), (4, 0), (5, 0)]
  pit flow=NoFlow others term=24/24 outlets=[(2, 2)]
  start=(0,0) terminated=False end=(0, 0) steps=8
  wolframscript rc=0
  wolfram pigeonhole: True
  wolfram ringFixed: False
  [PASS] slope interior 100% terminate + unique outlet per cell  (n=25 term=25 uniq_outlets=5)
  [PASS] pit centre NoFlow; other cells terminate with an outlet  (pit=NoFlow others_term=24/24)
  [PASS] flat 4-ring does not terminate (P-006b)  (ring_terminated=False)
  [PASS] wolfram pigeonhole + ring witness  (pigeon=True fixed=False)
GPB-015 ENTRY: PASS
[gates]     slope terminate+unique: PASS; pit NoFlow + others unique: PASS; P-006b ring no-term: PASS; wolfram 4^4 pigeonhole + ring: PASS
[verdict]   PASS
[blocker]

---

[task]      task6 / P-006
[step]      本地 manim
[cmd]       $env:P006_MANIM='1'; & "C:\ProgramData\anaconda3\python.exe" experiments/phase1/p006_watershed.py
[rc]        0
[key lines]
  manim rc=0
GPB-015 ENTRY: PASS
[gates]     manim WatershedStencil: PASS; copied to experiments/phase1/figures/WatershedStencil.mp4 (191640 bytes)
[verdict]   PASS
[blocker]

---

## P-006 云端复核(本机全绿后 overlay,非 git push)

[task]      task6 / P-006
[step]      云端 dafny
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:$PATH" && cd /root/verigis/repo && python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P006_watershed.dfy'
[rc]        0
[key lines]
🚀  START @ 17:46:26   elapsed 0:00:00
   $  dafny verify formal/dafny/P006_watershed.dfy
   log → /root/.workbuddy/jobs/20260906_174626.log
   17:46:28  +    0:02  Dafny program verifier finished with 20 verified, 0 errors   ✅ VERIFY:20 verified / 0 errors
✅  END @ 17:46:28  rc=0  elapsed=0:02  log=/root/.workbuddy/jobs/20260906_174626.log
[gates]     dafny verify P006_watershed.dfy: PASS (20 verified / 0 errors)
[verdict]   PASS
[blocker]

---

[task]      task6 / P-006
[step]      云端 lean
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:$PATH" && cd /root/verigis/repo/formal/lean4 && lake build
[rc]        0
[key lines]
⣻ [2756/2758] Running VeriGIS.Watershed (+ 0 more)
⣷ [2757/2758] Running VeriGIS (+ 0 more)
Build completed successfully.
[gates]     lake build VeriGIS.Watershed: PASS
[verdict]   PASS
[blocker]

---

[task]      task6 / P-006
[step]      云端 numpy
[cmd]       cd /root/verigis/repo && bash experiments/phase1/run_p006.sh
[rc]        0
[key lines]
  [PASS] slope interior 100% terminate + unique outlet per cell  (n=25 term=25 uniq_outlets=5)
  [PASS] pit centre NoFlow; other cells terminate with an outlet  (pit=NoFlow others_term=24/24)
  [PASS] flat 4-ring does not terminate (P-006b)  (ring_terminated=False)
  [SKIP] wolfram (not a fail; AutoDL has no wolframscript)
GPB-015 ENTRY: PASS
[gates]     三条数值门控 PASS; wolfram SKIP(云端无 wolframscript,本机已过)
[verdict]   PASS
[blocker]

---

## 改了什么(给洛书沉淀)

新文件:
- `formal/dafny/P006_watershed.dfy` — include P-005 核;stepN 对 n 归纳;`BasinUnique`;P-006b `RingSucc` 无不动点
- `formal/lean4/VeriGIS/Watershed.lean` — 独立重述(抽象 succ + Fin 4 环);第一次 `wlog` 参数对不上,改成 `Nat.le_total` 分情况
- `formal/dafny/P006_README.md` — P-002→P-006 链条 +「没证什么」(P-006b + 第 6 条 PENDING)
- `experiments/phase1/p006_watershed.py` — `from p005_d8 import`;三条门控
- `experiments/phase1/p006_watershed.wl` — 穷举 4^4 + Assuming m+1>m
- `experiments/phase1/p006_manim.py` + `figures/WatershedStencil.mp4`
- `experiments/phase1/run_p006.sh`

索引:
- `formal/lean4/VeriGIS.lean` 加 `import VeriGIS.Watershed`
- `scripts/autodl/verify_all.sh` 加 P-006 dafny + `run_p006.sh`
- `experiments/phase1/README.md` 文件表 + P-006 节
- `.gitignore` 加 `experiments/phase1/results/gpb006/`

第 6 条 `TerminatesUnderStrictDescent` 按 BRIEF 标 PENDING,未做。未 commit(等 PI/洛书拍板)。

**总 verdict: P-005 PASS; P-006 本地+云端 PASS(第 6 条 PENDING 已写入 README)。**

---

## P-COMP-1 + P-006 T6(task7)

A.1 自检:
1. 内部编号 = `task7 / P-COMP-1 + 第 6 条`(一致)
2. HEAD 当时是 `e0b0001`,不是 `8ce0ee6`(报 HEAD;import 链在,未 checkout formal/)
3. `P006_watershed.dfy:14` = `include "P005_d8.dfy"`(是)
4. 第 6 条原 PENDING;现已起草,本机无 dafny/lake,README 标 VERIFY PENDING

---

[task]      task7 / P-COMP-1 + 第 6 条
[step]      本地 numpy + wolfram
[cmd]       & "C:\ProgramData\anaconda3\python.exe" experiments/phase2/p_comp_1.py
[rc]        0
[key lines]
  fill min=5.000 max=5.000  checked=25 pits=0
  strict descent: n=9 min_drop=1.0000
  terminate: n=9 term=9 longest=3 uniq_out=3
  start=(0,0) terminated=False end=(0, 0) steps=8
  wolframscript rc=0
  wolfram pigeonhole: True
  wolfram descentAllFix: True
  wolfram ringFixed: False
  [PASS] NoPitImpliesDescent after W&L fill  (checked=25 pits=0)
  [PASS] StrictDescent plane A=1 each step drop>=1  (n=9 min_drop=1.0000)
  [PASS] TerminatesUnderStrictDescent 5x5 interior <=50  (n=9 term=9 longest=3 uniq_out=3)
  [PASS] unfilled flat 4-ring does not terminate (P-006b contrast)  (ring_terminated=False)
  [PASS] wolfram pigeon + descent-fix + ring  (pigeon=True descent=True fixed=False)
GPB-021 ENTRY: PASS
[gates]     (i) NoPitImpliesDescent: PASS; (ii) StrictDescent drop>=1: PASS; (iii) 5x5 terminate<=50: PASS; P-006b ring: PASS; wolfram 4^4 pigeon + descent-fix + ring: PASS
[verdict]   PASS
[blocker]

---

[task]      task7 / P-COMP-1 + 第 6 条
[step]      本地 manim
[cmd]       $env:PCOMP1_MANIM='1'; & "C:\ProgramData\anaconda3\python.exe" experiments/phase2/p_comp_1.py
[rc]        0
[key lines]
  manim rc=0
GPB-021 ENTRY: PASS
[gates]     manim FillThenWatershedStencil: PASS; copied to experiments/phase2/figures/FillThenWatershedStencil.mp4 (166513 bytes)
[verdict]   PASS
[blocker]

---

[task]      task7 / P-COMP-1 + 第 6 条
[step]      本地 dafny
[cmd]       dafny verify formal/dafny/P006_terminate_under_strict.dfy ; dafny verify formal/dafny/PCOMP_1.dfy
[rc]        n/a
[key lines]
  where.exe dafny → empty
  本机 Windows PATH 无 dafny(P-006 权威 verify 在 AutoDL)
[gates]     dafny P006 T6: SKIP; dafny PCOMP_1: SKIP
[verdict]   BLOCKED
[blocker]   本机无 dafny;未改种子核。请 AutoDL overlay 后跑 verify_all.sh 的 P-006 T6 + P-COMP-1 两闸

---

[task]      task7 / P-COMP-1 + 第 6 条
[step]      本地 lean
[cmd]       cd formal/lean4 && lake build
[rc]        n/a
[key lines]
  lake / elan 不在本机 PATH(按 LOOP,lake build 在 AutoDL)
[gates]     lake build VeriGIS.P006Terminate + VeriGIS.Composition: SKIP
[verdict]   BLOCKED
[blocker]   本机无 lake;VeriGIS.lean 已加 import。请云端 lake build

---

## 改了什么(给洛书沉淀)

新文件:
- `formal/dafny/P006_terminate_under_strict.dfy` — include P-006;`StrictDescent`/`Bound`/`decreases c`;`TerminatesUnderStrictDescent`;`HeightSucc` 实例
- `formal/lean4/VeriGIS/P006Terminate.lean` — `Nat.lt_wfRel.wf.induction`;`stepN_succ_head`;独立重述
- `formal/dafny/P006_terminate_under_strict_README.md` — 第 6 条台账 + 引用 P-COMP-1 §2.4 (iii)
- `formal/dafny/PCOMP_1.dfy` — include P-002-bis + T6;(i)~(v) 全是 import 引理,不复制 Fill/D8/stepN
- `formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean` — import 三模块 + T6;`pit_fill_then_watershed` = T6 终止 + `basin_unique`
- `formal/dafny/PCOMP_1_README.md` — 组合策略图 + 反向引用 P-006 README
- `experiments/phase2/p_comp_1.py` — `from p005_d8 / p006_watershed import`;W&L 4 连通 `pit_fill_2d`(P-002 Python 仍未公开,try-import 回退)
- `experiments/phase2/p_comp_1.wl` — 穷举 4^4 鸽笼 + `f[i]<=i` 子集全触不动点 + 4-环无不动点
- `experiments/phase2/p_comp_1_manim.py` — 左:不填洼 flat 环;右:平面唯一出口
- `experiments/phase2/run_p_comp_1.sh` — `GPB-021 ENTRY: PASS`
- `experiments/phase2/figures/FillThenWatershedStencil.mp4`

改文件:
- `formal/lean4/VeriGIS.lean` L12-13 加 `import VeriGIS.P006Terminate` 与 `import VeriGIS.Composition.PitFillingThenWatershed`
- `formal/lean4/VeriGIS/Watershed.lean` 头注释:第 6 条指向 `P006Terminate`(不改核)
- `formal/dafny/P006_watershed.dfy` 头注释:PENDING → 指向 T6 文件(不改核)
- `formal/dafny/P006_README.md` 证了什么表加 T6 行;没证什么第 6 条改 VERIFY PENDING;跑命令加 T6 verify
- `scripts/autodl/verify_all.sh` 加 P-006 T6 + PCOMP_1 dafny 闸,以及 `run_p_comp_1.sh`(9/9)
- `.gitignore` 加 `experiments/phase2/results/`

未改:`docs/phase2/PROP_CHAIN.md` / `this-week.md` / `MEMORY.md`。未复制 P-002/P-005/P-006 核。未 git push。

种子层没有整幅 `pitFill2D` / 格网 `basin`,P-COMP-1 主定理落在 Fill + RaiseNbr + FlowDescent + T6 Bound + BasinUnique 的接口面上(PROP_CHAIN §2.4)。

P-COMP-1 + T6 verdict = BLOCKED
(数值+符号化+manim 本机 PASS;形式化等 AutoDL dafny verify + lake build)

---

> 不要写"一切正常""跑通了"这类摘要 —— 洛书看不到你的终端,摘要等于没说。
> 改完回传时,额外说明:改动了哪个文件哪几行、为什么这么改。
