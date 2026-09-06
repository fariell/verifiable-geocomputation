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

## P-COMP-1 + T6 云端复核(task7.5)

云端当时没有 task7 文件(PCOMP_1.dfy / T6 均 No such file)。先 overlay 15 个已 commit 文件到 `/root/verigis/repo`,再跑 4 条复核命令。首次 dafny 因 T6 `forall x: nat` 不可编译失败,改 `ghost predicate` / `ghost function Bound` 后重跑。Lean `d8_preserves_descent_plane_west` 的 `simp` 已关目标,`norm_num` 报 no goals,删掉后 lake 过。

---

[task]      task7.5 / P-COMP-1 + T6 云端复核
[step]      overlay(SFTP,非 git push)
[cmd]       python ~/.autodl_run.py --upload-list ~/.autodl_pcomp1_upload.txt
[rc]        0
[key lines]
[autodl_run] uploaded 15 files
ls 初检: PCOMP_1.dfy / P006_terminate_under_strict.dfy 原先不在云端
[gates]     overlay P-COMP-1 + T6 源码: PASS
[verdict]   PASS
[blocker]

---

[task]      task7.5 / P-COMP-1 + T6 云端复核
[step]      云端 dafny T6
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH" && cd /root/verigis/repo && python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P006_terminate_under_strict.dfy'
[rc]        0
[key lines]
🚀  START @ 18:30:48   elapsed 0:00:00
   $  dafny verify formal/dafny/P006_terminate_under_strict.dfy
   log → /root/.workbuddy/jobs/20260906_183048.log
   18:30:50  +    0:01  Dafny program verifier finished with 12 verified, 0 errors   ✅ VERIFY:12 verified / 0 errors
✅  END @ 18:30:50  rc=0  elapsed=0:02  log=/root/.workbuddy/jobs/20260906_183048.log
[gates]     dafny verify P006_terminate_under_strict.dfy: PASS (12 verified / 0 errors)
[verdict]   PASS
[blocker]

---

[task]      task7.5 / P-COMP-1 + T6 云端复核
[step]      云端 dafny P-COMP-1
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH" && cd /root/verigis/repo && python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/PCOMP_1.dfy'
[rc]        0
[key lines]
🚀  START @ 18:31:09   elapsed 0:00:00
   $  dafny verify formal/dafny/PCOMP_1.dfy
   log → /root/.workbuddy/jobs/20260906_183109.log
   18:31:11  +    0:02  Dafny program verifier finished with 17 verified, 0 errors   ✅ VERIFY:17 verified / 0 errors
✅  END @ 18:31:11  rc=0  elapsed=0:02  log=/root/.workbuddy/jobs/20260906_183109.log
[gates]     dafny verify PCOMP_1.dfy: PASS (17 verified / 0 errors)
[verdict]   PASS
[blocker]

---

[task]      task7.5 / P-COMP-1 + T6 云端复核
[step]      云端 lean
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH" && cd /root/verigis/repo/formal/lean4 && lake build
[rc]        0
[key lines]
⣾ [2758/2760] Running VeriGIS.Composition.PitFillingThenWatershed (+ 0 more)
⣷ [2759/2760] Running VeriGIS (+ 0 more)
Build completed successfully.
[gates]     lake build VeriGIS.P006Terminate + VeriGIS.Composition.PitFillingThenWatershed: PASS
[verdict]   PASS
[blocker]

---

[task]      task7.5 / P-COMP-1 + T6 云端复核
[step]      云端 numpy
[cmd]       cd /root/verigis/repo && chmod +x experiments/phase2/run_p_comp_1.sh && bash experiments/phase2/run_p_comp_1.sh
[rc]        0
[key lines]
  [PASS] NoPitImpliesDescent after W&L fill  (checked=25 pits=0)
  [PASS] StrictDescent plane A=1 each step drop>=1  (n=9 min_drop=1.0000)
  [PASS] TerminatesUnderStrictDescent 5x5 interior <=50  (n=9 term=9 longest=3 uniq_out=3)
  [PASS] unfilled flat 4-ring does not terminate (P-006b contrast)  (ring_terminated=False)
  [SKIP] wolfram (not a fail; AutoDL has no wolframscript)
GPB-021 ENTRY: PASS
[gates]     四条数值门控 PASS; wolfram SKIP(云端无 wolframscript,本机 task7 已过)
[verdict]   PASS
[blocker]

P006_README「没证什么」第 6 条已从 VERIFY PENDING 改为云端 PASS(12/0 + lake OK)。

task7.5 verdict = PASS

---

## P-COMP-3 反例素材(task8A)

---

[task]      task8A / P-COMP-3
[step]      本地 numpy + wolfram
[cmd]       & "C:\ProgramData\anaconda3\python.exe" experiments/phase2/p_comp_3.py
[rc]        0
[key lines]
  ZT signedmax Hxx=1.41e-2  Horn |Dx|=0.2100
  ZT signedmax Hxx=6.97e-2  Horn |Dx|=0.0700
  wolframscript rc=0
  wolfram foundDiff: True
  wolfram nDiff: 251
  wolfram alongStreamZero: True
  [PASS] zt_curv_signedmax vs horn_d2_compress on grid-A  (ZT 1.41e-2, Horn 0.21)
  [PASS] zt_curv_signedmax vs horn_d2_compress on grid-B  (ZT 6.97e-2, Horn 0.07)
  [PASS] geometric_persistence:both-sides drop to 0 along stream direction  (zt_Hyy=0.000e+00 horn_Dy=0.000e+00)
GPB-023 ENTRY: NEGATIVE-RESULT PASS
[gates]     grid-A ZT≠Horn: PASS; grid-B ZT≠Horn: PASS; along-stream both 0: PASS; wolfram 4^4 nDiff=251: PASS
[verdict]   PASS
[blocker]

---

[task]      task8A / P-COMP-3
[step]      本地 manim
[cmd]       $env:PCOMP3_MANIM='1'; & "C:\ProgramData\anaconda3\python.exe" experiments/phase2/p_comp_3.py
[rc]        0
[key lines]
  manim rc=0
  manim copied -> experiments/phase2/figures/ZTNotHornStencil.mp4
GPB-023 ENTRY: NEGATIVE-RESULT PASS
[gates]     manim ZTNotHornStencil: PASS; copied 166888 bytes
[verdict]   PASS
[blocker]

---

[task]      task8A / P-COMP-3
[step]      本地 dafny
[cmd]       dafny verify formal/dafny/PCOMP_3.dfy
[rc]        n/a
[key lines]
  本机 Windows PATH 无 dafny;改走 AutoDL
[gates]     本机 dafny: SKIP
[verdict]   BLOCKED
[blocker]   本机无 dafny;云端闸见下一步

---

[task]      task8A / P-COMP-3
[step]      云端 dafny
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH" && cd /root/verigis/repo && python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/PCOMP_3.dfy'
[rc]        0
[key lines]
🚀  START @ 18:38:47   elapsed 0:00:00
   $  dafny verify formal/dafny/PCOMP_3.dfy
   log → /root/.workbuddy/jobs/20260906_183847.log
   18:38:49  +    0:01  Dafny program verifier finished with 5 verified, 0 errors   ✅ VERIFY:5 verified / 0 errors
✅  END @ 18:38:49  rc=0  elapsed=0:01  log=/root/.workbuddy/jobs/20260906_183847.log
[gates]     dafny verify PCOMP_3.dfy: PASS (5 verified / 0 errors)
[verdict]   PASS
[blocker]

---

[task]      task8A / P-COMP-3
[step]      云端 lean
[cmd]       source /etc/network_turbo && source ~/.elan/env && export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH" && cd /root/verigis/repo/formal/lean4 && lake build
[rc]        0
[key lines]
⣾ [2759/2761] Running VeriGIS.Composition.ZTNotImpliesHorn (+ 0 more)
⣷ [2760/2761] Running VeriGIS (+ 0 more)
Build completed successfully.
[gates]     lake build VeriGIS.Composition.ZTNotImpliesHorn: PASS
[verdict]   PASS
[blocker]

---

## 改了什么(给洛书沉淀)

task7.5 云端修补(本机无 dafny/lake,复核才暴露):
- `P006_terminate_under_strict.dfy` `StrictDescent`/`Bound` → ghost(unbounded `forall x: nat` 不可编译)
- `PitFillingThenWatershed.lean` `d8_preserves_descent_plane_west` 删掉多余 `norm_num`(simp 已关目标)
- `P006_README.md` 第 6 条 VERIFY PENDING → 云端 PASS 12/0

task8A 新文件:
- `experiments/phase2/p_comp_3.py` — import P-003 `numeric_zt` / P-004 `horn_dzdx`;grid-A/B + stream
- `experiments/phase2/p_comp_3.wl` — 4^4 穷举,nDiff=251;stream Hyy=Horn Dy=0
- `experiments/phase2/p_comp_3_manim.py` + `figures/ZTNotHornStencil.mp4`
- `experiments/phase2/run_p_comp_3.sh` — `GPB-023 ENTRY: NEGATIVE-RESULT PASS`
- `experiments/phase2/p_comp_3_README.md` — 「没证什么」开篇
- `formal/dafny/PCOMP_3.dfy` — include P-003+P-004;`Witness`/`ztNotHorn`/`negResult`(不 include P-001:文件级 `Main` 冲突)
- `formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean` — `plane_hessian_zero` + `quadratic_exact_dx`;`noncomputable section`
- `formal/dafny/PCOMP_3_README.md` — 「它不是 bug,是 feature」

改文件:
- `formal/lean4/VeriGIS.lean` 加 `import VeriGIS.Composition.ZTNotImpliesHorn`

未改:`docs/phase2/PROP_CHAIN.md` / `this-week.md` / `MEMORY.md` / 仓根 README。未复制 P-003/P-004 核。未 git push。凭据未下地。

task7.5 verdict = PASS
task8A verdict = PASS

---

> 不要写"一切正常""跑通了"这类摘要 —— 洛书看不到你的终端,摘要等于没说。
> 改完回传时,额外说明:改动了哪个文件哪几行、为什么这么改。
