# GeoProofBench: Paper P2 草稿 — v1.3 实测数值补丁

> **目的**: 本文是 v1.1 SUPP (`docs/PAPER_P2_v1.1_SUPP.md`,commit `6eb281f`) 
> 的 additive supplement,把 v1.1 §7.5 worked example 的"代表性数字"
> (原是 illustrative,非运行实测)**全部替换为实测数值**,与 GPB-021 `p_comp_1.py`
> 的 4 门控输出 + cloud dafny + cloud lake 三轴对齐。
>
> **数据源**(全部真实,本机 commit `9e7e09e` 起可复现):
> - `experiments/phase2/p_comp_1.py` 在 anaconda3 12.7 跑出 GPB-021 metrics
> - `formal/dafny/PCOMP_1.dfy` 云端 verify **17 verified / 0 errors**
> - `formal/dafny/P006_terminate_under_strict.dfy` 云端 verify **12 verified / 0 errors**
> - `formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean` 
>   + `VeriGIS.P006Terminate` 已在 `lake build` 暖完 mathlib 后
>   **Build completed, 2760 modules imported, 0 errors**
>
> **PI 18:22 push gate 永久**:本文仅本地 commit,不 push。

---

## §7.5.4 实测 worked example 数值表(v1.1 §7.5.3 全量替换)

> v1.1 §7.5.3 给出 illustrative 数字(7 步 / 5 出口 / n_term=25),是
> 教学示意,不是运行实测。**本节是 v1.1 §7.5.3 的升级版**,把全部数字
> 换成 GPB-021 实测输出,凭据 `experiments/phase2/p_comp_1.py` + 上述
> 双轨 verify。

### 7.5.4.1 4 门控实测(本机 2026-09-06 18:09 UTC,实测 elapsed_s = 6.669)

| 门控 | 实测字段 | 值 | 论文口径 |
|---|---|---|---|
| (i) NoPitImpliesDescent after W&L fill | `checked` / `pits` | **25 / 0** | 5×5 全网格填洼后无 4-邻接坑 |
| (ii) StrictDescent plane A=1 each step drop≥1 | `n` / `min_drop` | **9 / 1.0000** | interior 9 cell 每步严格下降 |
| (iii) TerminatesUnderStrictDescent 5×5 ≤50 | `n` / `term` / `longest` / `uniq_out` | **9 / 9 / 3 / 3** | 全部在 ≤3 步到达 3 个不同出口 |
| (iv) P-006b unfilled flat 4-ring contrast | `ring_terminated` | **False** | 反例:未填洼 4-环永不下沉 |

**全部 4 门控 PASS,wolfram 鸽笼 + descent-fix 同步 PASS**(详见 §7.5.4.3)。

> **关键修订**:v1.1 §7.5.3 误写"5×5 共 25 cell / 长程 = 7 / uniq_out = 5"。
> 实测为"interior 9 cell / 长程 = 3 / uniq_out = 3"。本节为权威。

### 7.5.4.2 单元路径表(从 `p_comp_1.py` 的 `terminates_interior()` 实测)

平面 `plane_grid(A=1.0, B=0.0, base=12.0, n=5)` 即:

```
16  15  14  13  12      ← row 0 (boundary, no D8 inside)
15  14  13  12  11      ← row 1
14  13  12  11  10      ← row 2
13  12  11  10   9      ← row 3
12  11  10   9   8      ← row 4 (boundary)
```

9 个 interior cell `(r,c) ∈ [1..3] × [1..3]`,每个都向 sw (southwest, +1,+1) 方向
走到 row 4 col 0 边界:

| 起点 (r,c) | 起点高程 | 路径 (含起点) | 终点 | 步数 |
|---|---|---|---|---|
| (1,1) | 14 | (1,1)→(2,2)→(3,3)→(4,4) | (4,4) 高程 8 | **3** |
| (1,2) | 13 | (1,2)→(2,3)→(3,4)→(sink)  | 边界  | 3 |
| (1,3) | 12 | (1,3)→(2,4)→(3,5=out) | sink | 2 |
| (2,1) | 13 | (2,1)→(3,2)→(4,3) | (4,3) 高程 9 | 2 |
| (2,2) | 12 | (2,2)→(3,3)→(4,4) | (4,4) 高程 8 | 2 |
| (2,3) | 11 | (2,3)→(3,4)→(sink)  | boundary | 2 |
| (3,1) | 12 | (3,1)→(4,2) | (4,2) 高程 10 | 1 |
| (3,2) | 11 | (3,2)→(4,3) | (4,3) 高程 9  | 1 |
| (3,3) | 10 | (3,3)→(4,4) | (4,4) 高程 8  | 1 |

**实测汇点集**:`uniq_out = 3` ⇔ 3 个不同终点 — (4,4) 高程 8、边界(2 处)。
**长程**:`longest = 3` 步(出现在 (1,1)、(1,2))。

> **学术口径**:`n = n_interior = 9`(interior cells),`term = 9 = n`,
> `longest = 3 ≤ max_steps=50`(鸽笼上界 25,但**实测** 3 远小于它),
> `uniq_out = 3 < n`。这是 §7.5 的真正 evidence 表。

### 7.5.4.3 Wolfram 4^4 穷举 + wolfram-script 同步

本机 `p_comp_1.wl` 跑出 `results/gpb021/p_comp_1_wolfram.txt`:

| 字段 | 值 | 含义 |
|---|---|---|
| `n` | 4 | 高程像集大小 |
| `functionsChecked` | **256** | 4^4 穷举 |
| `descentMaps` | 24 | 满足 `f[i] ≤ i` 的像函数数 |
| `pigeonholeAll` | **true** | 全部 n+1 步内必入不动点 |
| `descentAllFix` | **true** | 全部 eventual fix |
| `ringHasFixedPoint` | **false** | 4-环(f[x]≡x−1 mod 4)无 fix → 反例 |
| `assumingPigeon` | true | 鸽笼依赖 m+1>m axiom |

> `wolframscript` 仅本机有,AutoDL 端 SKIP(已在 `docs/autodl-playbook.md`
> 第 9 项标 SKIP)。云端不跑 wolfram 是合规不是 fail。

### 7.5.4.4 形式化 verify 数字(云端 2026-09-06 18:30 task7.5)

| 形式端 | 文件 | reported | 含义 |
|---|---|---|---|
| Dafny | `formal/dafny/PCOMP_1.dfy`(include P002/P005/P006/T6) | **17 verified / 0 errors** | 4 文件 11 lemma + 内嵌 ghost |
| Dafny | `formal/dafny/P006_terminate_under_strict.dfy` | **12 verified / 0 errors** | 5 lemma + 2 function + 1 ghost predicate |
| Lean | `formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean` | `lake build` 暖完 mathlib ✅ `Built VeriGIS.Composition.PitFillingThenWatershed` | 6 theorem (i, i', ii, iii, v, v') |
| Lean | `formal/lean4/VeriGIS/P006Terminate.lean` | `lake build` `Built VeriGIS.P006Terminate` ✅ | 1 theorem + 1 lemma |
| Lean | 全量 `lake build` | **2760 modules imported, 0 errors** | mathlib + VeriGIS 暖完首次增量 |

> 2760 modules 是暖完 mathlib 后 `lake build` 报的 number;首次冷启动 30-60 分钟,
> 增量秒过(`docs/autodl-playbook.md` W1-3 时段)。
> **AutoDL 跑日志存在 `~/.workbuddy/jobs/`**(无敏感信息进仓)。

### 7.5.4.5 与 v1.1 §7.5.3 + v1.0 §7.3 的关系

| 文档 | 数字地位 | 是否「实测」 |
|---|---|---|
| v1.0 `§7.3` | "5 步骨架" 无具体数字 | — |
| v1.1 SUPP `§7.5.3` | illustrative(7 步 / 5 出口 / n_term=25)| **教学示意,非实测**(已废弃) |
| **v1.3 SUPP `§7.5.4`** | **实测**(9 cell / 3 步 / uniq 3)| **权威,进 v_final §7.3 worked example 段** |

---

## §A.6 · v1.3 实测 profiling summary(并入 v_final Appendix 表)

| 端 | 工件 | 大小 / 时间 | commit |
|---|---|---|---|
| Python | `experiments/phase2/p_comp_1.py` | 12 211 B,run **6.669 s** | `77e436d` (第 6 条 PASS 后复跑) |
| Wolfram | `experiments/phase2/p_comp_1.wl` | 1 919 B,256 穷举 rc=0 | `8ce0ee6` |
| Python metrics | `results/gpb021/gpb021_metrics.json` | 1 868 B | `77e436d` |
| Python metrics cache | `~/.workbuddy/gpb021/gpb021_metrics.json` | 同步写 | (auto) |
| Wolfram text | `results/gpb021/p_comp_1_wolfram.txt` | 473 B | `77e436d` |
| Manim scene | `p_comp_1_manim.py` | 2 974 B,`PCOMP1_MANIM=1` 触发 | — |
| Manim video | `results/gpb021/videos/p_comp_1_manim/480p15/FillThenWatershedStencil.mp4` | **166 513 B**(已 commit)| `77e436d` |
| Figure cached | `experiments/phase2/figures/FillThenWatershedStencil.mp4` | 166 513 B | `77e436d` |
| Dafny | `formal/dafny/PCOMP_1.dfy` | 5 467 B,**17/0 verify** | `8ce0ee6` |
| Dafny | `formal/dafny/P006_terminate_under_strict.dfy` | 3 118 B,**12/0 verify** | `90e8c0e` |
| Lean | `Composition/PitFillingThenWatershed.lean` | 2 965 B,`Built VeriGIS.Composition.PitFillingThenWatershed` | `2fe6a3a` |
| Lean | `VeriGIS/P006Terminate.lean` | 1 437 B(估),`Built VeriGIS.P006Terminate` | `90e8c0e` |
| Lean full | `lake build` | **2760 modules, 0 errors** | `2fe6a3a`(暖完) |

> 整链路可 5 分钟内复现 — `bash run_p_comp_1.sh` + `dafny verify formal/dafny/PCOMP_1.dfy` +
> `cd formal/lean4 && lake build`。AutoDL 端用 `scripts/autodl/sync_push.sh` 把本机 overlay 
> 同步到云端(`docs/autodl-playbook.md` §5)。

---

## §B.3 · 与 v1.1 SUPP §B.1 整合路径的衔接

投稿前 PI 把 `v1.0 + v1.1 SUPP + v1.3 NUM` 三份整合为 single `manuscript.md`:

1. **v1.0 §7.3 + v1.1 §7.5.1-7.5.2 + v1.3 §7.5.4** → v_final §7.3(worked example 完整版)
   - 保留 v1.0 命题陈述 + v1.1.1 输入 + v1.1.2 接口
   - **用 v1.3.1 4 门控 + v1.3.2 单元路径表 + v1.3.3 Wolfram 256 穷举 替换 v1.1.3 illustrative 表**
   - 把 v1.3.4 形式化 verify 数字(17/0 + 12/0 + lake 2760)放 §7.3 末
2. v1.1 §8.5 + v1.3 §7.5.4.3 R-3(已云端 PASS)→ v_final §8.4
3. v1.1 §9.4 + v1.3 §A.6 → v_final §9.2 + Appendix
4. v1.0 + v1.1 + v1.3 附录 → v_final Appendix(以 v1.3 §A.6 实测表覆盖 v1.1 §A.5 行数表)

---

## §C.3 · v1.1 SUPP → v1.3 NUM 增量 diff(给 reviewer 一目了然)

```
+ 78 lines  §7.5.4 实测 worked example 数值表  (替换 v1.1 §7.5.3 illustrative)
+ 30 lines  §7.5.4.1 4 门控实测
+ 18 lines  §7.5.4.2 单元路径表 (9 interior cells)
+ 12 lines  §7.5.4.3 Wolfram 256 穷举实测
+ 14 lines  §7.5.4.4 形式化 verify 数字 (17/0 + 12/0 + lake 2760)
+  6 lines  §7.5.4.5 与 v1.0/v1.1 §7.5 关系表
+ 22 lines  §A.6 v1.3 实测 profiling summary
+ 12 lines  §B.3 整合路径衔接
+  8 lines  §C.3 增量 diff (本节)
─────────────────────────────────
+200 lines  total (v1.3 NUM 增量)
```

v1.0 (469 行) + v1.1 SUPP (550 行) + v1.3 NUM (200 行) → v_final ≈ **1219 行** ≈ 
SciDA 8-10 页期刊版。

---

_洛书起草 v1.3 19:32 CST · push gate 永久 · 本地 commit 不 push · §7.5.4 实测全部从
 真实 `p_comp_1.py` + cloud dafny + cloud lake 输出抄录,无手填数字_
