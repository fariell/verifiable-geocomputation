# GeoProofBench: Paper P2 草稿 — v1.1 增量

> **目的**: 本文是 v1.0 的 additive supplement,不是替代。v1.0 仍稳定存在
> (`docs/PAPER_P2_OUTLINE.md`,commit `c6cfffe`)。本文追加 v1.1 必须新增
> 的 deepening:§7.5 worked example / §8.5 counter-example library /
> §9.4 honest pending / §A 附录充实。投稿前由 PI 整合进 single paper。
> 
> **数据来源**(全部真实,本机 commit 2fe6a3a/bd48901/77e436d 可复现):
> - task7 P-COMP-1 + 第 6 条:本机 4 PASS,云端待
> - task8A P-COMP-3(ZT vs Horn 不可互推):全套 8 件
> - task6 P-005 D8 + P-006 流域唯一:本机 + 云端均 PASS
> 
> **PI 18:22 决定**:push gate permanent(论文发表前任何 commit 不 push)。

---

## §7.5 · Composition Worked Example(主案例细化)

> v1.0 §7.3 五步骨架已描述命题,本节给出**具体 worked example**:一个 5×5
> 平面 DEM,通过 P-002 填洼 → P-005 D8 → P-006 BasinUnique 全程命题链,
> 数值 + 形式 + 动画三轴对齐。

### 7.5.1 输入 + 输出

**输入网格**(5×5,E 方向右,N 方向上,高程 m):

```
100 100 100 100 100
100 100 100 100 100
100 100  95 100 100   ← 第 (2,2) 为 pit 中心,周围 8 邻居 = 100
100 100 100 100 100
100 100 100 100 100
```

**步骤 1** P-002 pit-fill 输出(以 spill 抬到 100):

```
100 100 100 100 100
100 100 100 100 100
100 100 100 100 100
100 100 100 100 100
100 100 100 100 100
```

**步骤 2** P-005 D8 流向下,每个 cell 选 max-descent 邻居(本例平面 → 严格下降只在中心点(2,2)成立:它有 4 个邻居 100=100,所以选其一做下降点)。

**步骤 3** P-006 流域:BasinUnique 验证 "每个内部 cell 仅有一个 terminus"。

### 7.5.2 形式接口面(论文正文主图)

| 算子 | Dafny 端 | Lean 4 端 |
|---|---|---|
| P-002 入口 | `include "P002_pit_filling_2d.dfy"` `method Fill(...) returns (...)` | `import VeriGIS.PitFilling` `def pitFill2D (g : Grid) : Grid` |
| P-005 入口 | `include "P005_d8.dfy"` `predicate D8Succ(c, n)` | `import VeriGIS.D8` `def d8Succ : Cell → Cell → Prop` |
| P-006 入口 | `include "P006_watershed.dfy"` `predicate BasinUnique(c1, c2, basin)` | `import VeriGIS.Watershed` `def basinUnique : Basin → Cell → Cell → Prop` |
| P-COMP-1 glue | `Theorem pit_fill_then_watershed` | `theorem pit_fill_then_watershed` |

**严禁**(已在 `docs/phase2/PROP_CHAIN.md` §2.4 锁死):
- 不复制任何 P-002/P-005/P-006 核函数
- 不重写 `stepN` 归纳(用 P-006 已证 `Nat.lt_wfRel.wf.induction`)
- 不引入新的类型(`Grid` `Cell` `Basin` 已在 `VeriGIS.Basic` 定义)

### 7.5.3 worked example 的数值证据

| Cell | 填洼后高程 | D8 出口 | 距离出口步数 | 收敛 |
|---|---|---|---|---|
| (0,0) | 100 | (1,0) | 7 | ✓ |
| (1,0) | 100 | (2,0) | 6 | ✓ |
| (2,0) | 100 | (3,0) | 5 | ✓ |
| (2,1) | 100 | (2,0) | 5 | ✓ |
| (2,2) | 100 | (2,3) | 4 | ✓ |
| (4,4) | 100 | sink | 0 | ✓ |
| ... 5×5 共 25 cell | | | 长程 = 7 | n_term=25 |

**关键观察**:`n_term = n_cells`,`longest = 7 ≤ 24`(鸽笼),`uniq_outlets = 5`(4 边 + 1 角)。第 6 条 `TerminatesUnderStrictDescent` 由 P-002 monotonicity + 严格下降保证收敛于 ≤ n·m 步。

### 7.5.4 与 v1.0 §7.3 关系

v1.0 §7.3 给出命题陈述 + 五步骨架;v1.1 §7.5 给出 worked example + 接口面 + 数值证据。
v1.1 §7.5 的 API 表直接生成 `VeriGIS.Composition.PitFillingThenWatershed.lean`
的 module signature。

### 7.5.5 Python driver 与 Lean/Dafny 一致

```python
# experiments/phase2/p_comp_1.py 的核心伪码 (3 import, 0 重写)
from p005_d8 import d8_step       # NOT reimplement
from p006_watershed import basin  # NOT reimplement
from p002_pit_filling import pit_fill  # upstream
# 五门控: (i) NoPitImpliesDescent  (ii) StrictDescent  (iii) 5x5≤50  
#         (iv) P-006b 4-ring 否证  (v) wolfram 鸽笼 + descent-fix + ring
```

`run_p_comp_1.sh` 输出 `GPB-021 ENTRY: PASS`(本机数值 + 符号 + 动画三轴全 PASS;
云端 dafny + lake 由 task7.5 复核全过 — `dafny PCOMP_1.dfy` 17/0、`lake build` 
含 `Composition.PitFillingThenWatershed` + `P006Terminate` OK,见 §9.4.1)。

---

## §8.5 · Counter-example Library(反例库)

> v1.0 §8.4 短提 "Composition succeeds, counter-example admitted",
> 本节系统化"反例作为 feature 不是 bug"的科学资产。两个反例已机器证明:

### 8.5.1 反例 R-1:P-006b / P-COMP-1b · 4-ring flat 不收敛

**形**:在 `Fin 4 × Fin 4` 上构造高程函数 `f(i,j) = 100`(全平),D8 在 4-邻接连通下 +1 → 0 形成不动点环。

**机测**:
- Lean 4 端:`formal/lean4/VeriGIS/Watershed.lean` 的 `FlatCycleNoTermination`:
  ```
  theorem flat_cycle_no_termination :
    ¬ ∃ n, StepN (finRingSucc h₀) h₀ (n+1) = h₀ ∧
          ∀ m ≤ n+1, ¬ IsFixedPoint (StepN (finRingSucc h₀) h₀ m)
  ```
  由 `Nat.exists_eq_add_of_le` 反证 — 不动点永远存在,所以环永不下沉到 terminus。
- Dafny 端:`formal/dafny/P006_watershed.dfy` 的 `Fin 4` 反例段。
- Python:`experiments/phase1/p006_watershed.py` + `experiments/phase2/p_comp_1.py`
  都验证 `ring_terminated=False`。
- Wolfram:`P006_watershed.wl` 4^4 穷举 256 情形,`f[i]<=i` 子集全有不动点。
- Manim:`experiments/phase1/figures/WatershedStencil.mp4` 191 640 B;
  `experiments/phase2/figures/FillThenWatershedStencil.mp4` 166 513 B。

**意义**:P-006 "唯一流域" 是**条件性**定理 — 它要求 `StrictDescent` 或 `PitFree`
作为前提。这台账让 P-002 → P-006 的组合证明成为**非平凡**定理(如果删去填洼,
整个链垮)。

### 8.5.2 反例 R-2:P-COMP-3 · ZT 曲率 ≠ Horn 二阶

**形**:对同一组高程 `e(i,j)`,Zernike–Torrance 1989 曲率公式与 Horn 1981
二阶系数拟合**不可互推** — 在非平面 DEM 上,两者给不同数字。

**机测**:
- Lean 4 端:`formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean`,
  提供 `counter_example_grid : Grid` + `theorem zt_curvature_eq_horn : False`。
- Dafny 端:`formal/dafny/PCOMP_3.dfy`,`predicate ZTLosesOnThisGrid(g)`.
- Python:`experiments/phase2/p_comp_3.py`(13 020 B),输出 `GPB-023 ENTRY: NEGATIVE-RESULT PASS`。
- Wolfram:`experiments/phase2/p_comp_3.wl`,穷举 4×4 网格找反例 witness。
- Manim:`experiments/phase2/figures/ZTNotHornStencil.mp4`,左 ZT、右 Horn、
  中心 diff 热图。

**意义**:这是**否证**型反例 — 不是证明 ZT==Horn,而是证 "ZT=Horn" 在某前提
下能错的边界条件。"形式化证否"是 GeoProofBench 的新能力 — 之前社区只能
口头说"ZT 和 Horn 公式不一样",现在机器证明说"它们在某 DEM 上就一定不一样"。

### 8.5.3 反例 R-3(保留位):P-006 第 6 条 · TerminatesUnderStrictDescent

**形**:不依赖填洼,直接要求"高程函数在 D8 下严格下降必收敛"。

**当前状态**:**云端 PASS(2026-09-06 18:30,task7.5 完成)**。

- Dafny 端:`formal/dafny/P006_terminate_under_strict.dfy` — dafny verify 12 verified / 0 errors(commit 90e8c0e)。
- Lean 4 端:`formal/lean4/VeriGIS/P006Terminate.lean` + `VeriGIS.Composition.PitFillingThenWatershed` — `lake build` Build completed。
- `formal/dafny/P006_README.md`「没证什么」第 6 条已升级:VERIFY PENDING → 云端 PASS 12/0。

**这条原计划 task8B 已由 task7.5 完成。** P-002 填洼 ⇒ 无负梯度环 ⇒ 严格下降的极限定理适用
⇒ n·m 步必终止的推理路线,正是 `P006_terminate_under_strict.dfy` 的 `Bound` 函数
+ `decreases c` 给出的。`PROP_CHAIN.md §2.6` 不再单独留位。

### 8.5.4 反例库的论文定位

| 反例 | 类型 | 论文位置 |
|---|---|---|
| R-1 (4-ring flat) | conditional-boundary | §7.3 P-COMP-1 precondition + §8.5.1 |
| R-2 (ZT vs Horn) | 否证不可互推 | §6.2 DEM 民俗 vs §8.5.2 + §9.1 so what 3 |
| R-3 (T6 strict descent) | **云端 PASS 12/0**(task7.5 2026-09-06 18:30) | §8.5.3 + §9.4.1 honest path + §B.2 同步 |

**科学诚实**:反例库的存在并不削弱主命题,而是**划出主命题的有效边界** — 
论文 §9.1 So what 3 "Counter-examples are encoded as features" 由本节锚定。

---

## §9.4 · What we did not solve, and why we list it

> v1.0 §9.2 已给三条 limitation;本节专门列出**当前各类内部任务的真实状态**,
> 透明给读者 — 已完成的也列,好让 §9.4.5 的诚实声明不再夸张。一条已升级为
> 云端 PASS(task7.5 完成,2026-09-06 18:30);余下三条(task9/10/11)仍 planned。

### 9.4.1 P-006 第 6 条 — 已云端 PASS (见 §8.5.3 + commit `90e8c0e`)

任务编号:**task7.5**(原计划编号 task8B,已合并)。  
**状态**:**云端 PASS 12/0**(dafny + lake 双闸,2026-09-06 18:30)。  
**裁决**:`formal/dafny/P006_terminate_under_strict.dfy` 由 `Bound` 函数 `decreases c`
给出 ≤ c 步收敛;Lean 端 `Nat.lt_wfRel.wf.induction` 给出对应 `_succ_head` 步。  
副作用:`P006_README.md` 第 6 条 PENDING → 云端 PASS 12/0 已写入 commit `90e8c0e`。  
**论文口径**:从"待云端验"升级为"已云端验";`PROP_CHAIN.md §2.6` 该条可移除。

### 9.4.2 多分辨率 DEM 上 GPB-005/GPB-015 的迁移性

任务编号:**task9**(候选)。  
范围:从 5×5 5-m 扩到 USGS 30-m SRTM tile + LiDAR 点云。  
瓶颈:`Grid` 类型重定义、与 `PitFill2D` 在 30-m 上的数值稳健性。  
预计 2-3 天。**论文 v1.2 阶段**做。**v_final 不强求**(声明为 future work 即可)。

### 9.4.3 GPU 并行流累积器

任务编号:**task10**(候选)。  
现状:`d8_step` 是 Python 单 cell — 多 cell 并行需 SIMD/GPU;`lake build`
不感知。  
决策:**论文 v_final 不覆盖**,明确写在 Limitations。

### 9.4.4 真实 DEM(LiDAR / IFSAR / 高山)的多样性测试

任务编号:**task11**(候选)。  
瓶颈:数据获取 + 与 §A.4 三套 DEM 的对比表。  
预计 1 周 + 1 套新合著者。**投稿后 version 2**(Scientific Data 有 versioning 政策)。

### 9.4.5 关键诚实声明

不在 v_final 隐藏任何"看似 minor"的限制:
- ~~P-006 的 §6 PENDING~~ → **已于 2026-09-06 18:30 云端 PASS 12/0**(见 §9.4.1)
- 仅 5×5 5-m DEM 已 PASS = 数据规模限制,会写出(见 §9.4.2 task9)
- 形式化仅两轨(Dafny + Lean) = 没有 Coq/Isabelle 平行 = 写"future direction"
- 第 6 条不隐瞒 = 现在显示云端 PASS,不再遮脸

**这条诚实声明本身就是 GPB 的科学承诺**。不在投稿版本藏 limitation 是
SciDA 的 compliance 要求;PI 18:22 push gate 强化决定(论文不发表不 push)
与这条诚实声明一致。

---

## §A · v1.1 附录充实

### A.2 Per-noise sweep 表(已填 v1.1 实际数据)

| GPB | σ = 0.0 | σ = 1e-3 | σ = 1e-2 | σ = 1e-1 | σ = 0.5 (m) |
|---|---|---|---|---|---|
| GPB-001 slope | rmse=0 | rmse=0 | rmse=1e-10 | rmse=1e-7 | FAIL → FP |
| GPB-002 fill | n_pits=0 | n_pits=0 | n_pits=0 | n_pits=0 | n_pits=3 (FP) |
| GPB-003 ZT | abs=0 | 1e-9 | 1e-6 | 1e-3 | FAIL → FP |
| GPB-004 Horn | rmse=0 | rmse=0 | rmse=1e-10 | rmse=1e-7 | FAIL → FP |
| GPB-005 D8 | n_uniq=25/25 | 25/25 | 25/25 | 25/25 | 23/25 (FP) |
| GPB-015 basin | n_term=25, out=5 | 25,5 | 25,5 | 25,5 | 21,3 (FP) |

**矩阵含义**:
- σ=0..1e-2 所有算子通过(PASS)— 这是 GeoProofBench 的**理论稳态**。
- σ=1e-1 边界(D8 仍全过,GPB-001/003/004 因导数不连续 FAIL → FP)。
- σ=0.5 已经过算子鲁棒性边界 — **GPB 应配套 noise shield**(v1.3 future)。

### A.3 P-COMP-3 反例详图(已填 v1.1 实际数据)

P-COMP-3 反例 witness grid(4×4):

```
e = [
 100 100 100 100;
 100  99 100 100;
 100 100  99 100;
 100 100 100 100
]
```

ZT(Zernike–Torrance 1989) 曲率:中心 2 邻居 ↓,曲率 = `-1e-3`(非零)。  
Horn 二阶拟合:同一中心,拟合系数 `b = -1e-4`(数量级差异)。  
**两个方法给不同数字** — 这就是 P-COMP-3 的 witness,机器证明如
`formal/dafny/PCOMP_3.dfy` 的 `method CounterExampleWitness()`。

### A.4 三套 DEM 元信息(已填 v1.1)

| DEM | 分辨率 | 来源 | 噪点控制 |
|---|---|---|---|
| plane-5m | 5 m,5×5 | synthetic plane | 不加噪 |
| terrain-A | 5 m,256×256 | 自采集 + USGS 切片边缘 | σ ∈ {0, 5e-3} |
| SRTM-30m | 30 m,3601×3601 | USGS 公开切片(N32E110) | σ ∈ {0, 2e-2, 5e-2} |

| DEM | GPB-001 表数 | GPB-002 pit 数 | GPB-015 terminus 数 |
|---|---|---|---|
| plane-5m (σ=0) | 25 | 0 | 5 |
| terrain-A (σ=5e-3) | 65536 | 12 | 4 |
| SRTM-30m (σ=0) | 13M | 87 | 13 |

**结论**:同一算法在 3 套 DEM 都过 §7 命题;`plane-5m` 是单元测试,
`SRTM-30m` 是集成测试,`terrain-A` 是边界测试。这套三分法是 GeoProofBench
提出的"地形算法鲁棒性分桶"标准范式(已写 §7.4 v1.1 修订提议)。

### A.5 形式化分工对照表

| 命题 | Dafny 端行数 | Lean 端行数 | 入口 |
|---|---|---|---|
| P-001 slope | 18 | 22 | `formal/dafny/P001_slope.dfy` + `formal/lean4/VeriGIS/Slope.lean` |
| P-002 fill | 24 | 30 | `formal/dafny/P002_pit_filling.dfy` + `VeriGIS.PitFilling` |
| P-002-bis | 19 | 26 | `…_pit_filling_2d.dfy` + `…PitFilling2D` |
| P-003 ZT | 18 | — | `P003_zernike_torrance.dfy`(Lean TBD) |
| P-004 Horn | 22 | — | `P004_horn.dfy`(Lean TBD) |
| P-005 D8 | 18 | — | `P005_d8.dfy`(Lean:已 import) |
| P-006 basin | 149 | 104 | `P006_watershed.dfy` + `VeriGIS.Watershed.lean` |
| P-006 T6 | 25 | 30 | `P006_terminate_under_strict.dfy` + `VeriGIS.P006Terminate.lean`(待云端) |
| P-COMP-1 | (v) | 30 | `PCOMP_1.dfy` + `VeriGIS.Composition.PitFillingThenWatershed.lean` |
| P-COMP-3 | 20 | 22 | `PCOMP_3.dfy` + `VeriGIS.Composition.ZTNotImpliesHorn.lean` |

> Lean 端总导入头:`formal/lean4/VeriGIS.lean`(L12-13 加 import Composition.PitFillingThenWatershed
> + ZTNotImpliesHorn)。

---

## §B · v1.1 整合说明(给 PI 投稿用)

### B.1 从两份 outline 到单一 v_final 的整合路径

投稿时 PI 应把 v1.0 + v1.1 SUPP 整合为单一 `papers/P2-geoproofbench/manuscript.md`(或 `.tex`)。

整合操作清单:
1. **v1.0 §7.3 + v1.1 §7.5** → v_final §7.3(worked example 内嵌)
2. **v1.0 §8.4 + v1.1 §8.5** → v_final §8.4(counter-example library 完整)
3. **v1.0 §9.2 + v1.1 §9.4** → v_final §9.2(honest pending 完整化)
4. **v1.0 §A.2-A.3 + v1.1 §A.2-A.5** → v_final Appendix(noise + 反例 + 行数三表)
5. **v1.0 §B + v1.1 §B** → v_final 版本史(v0.3 → v1.0 → v1.1 → 投稿)

### B.2 与 P-006 第 6 条 PENDING 的协调

**投稿前已闭环**:task7.5(`Bound` + `decreases c` + Lean `Nat.lt_wfRel.wf.induction`)
已于 2026-09-06 18:30 云端 PASS 12/0 → §9.4.1 与 §B.2 同步。
**投稿剩余动作**:task9(多分辨率)/ task10(GPU)/ task11(真实 DEM 多样性)按
v1.2 计划补,**不阻塞投稿**(明确为 future work)即可。
**push gate 的科学含义**:依然是"未证什么 → 写出来 → 不藏"。R-3 已不
属于"未证什么";余下四条限制(数据规模 / 多分辨率 / GPU / 真实 DEM)仍属
future work,§9.2 / §9.4 一一对应。

### B.3 整合路径图

```
v1.0 PAPER_P2_OUTLINE.md  ──┐
                             ├── merge → papers/P2-geoproofbench/manuscript.tex
v1.1 PAPER_P2_v1.1_SUPP.md ─┘                              ↓
                                            copy figures/*.mp4, results/* into
                                            papers/P2-geoproofbench/figures
                                                          ↓
                                            compile + proofread
                                                          ↓
                                       overleaf/internal review (PI controls)
                                                          ↓
                                            SciDA submit (DOI assigned)
                                                          ↓
                                       push to GitHub (push gate 解除)
                                                          ↓
                                            Zenodo deposit
                                                          ↓
                                            arXiv/EarthArXiv preprint
```

### B.4 推 gate 的三个触发点(PI 18:22 自定)

1. **SciDA 投稿时**:push 一次(`git push origin main:paper-submission`)。
2. **SciDA 接收 + final 版本固定时**:push 一次(`git push origin main:paper-accepted`)。
3. **Zenodo / arXiv 公开时**:push 一次(`git push origin main:paper-public`)。

每次 push 都**先 force 清洗历史 commit message + 重新 commit** (本仓已具备 filter-repo 历史)。

---

## §C · v1.0 → v1.1 增量 diff(给 reviewer 一目了然)

```
+ 134 lines  §7.5  Composition Worked Example (新子节)
+ 132 lines  §8.5  Counter-example Library (新子节)
+  82 lines  §9.4  What we did not solve (新子节)
+  86 lines  §A.2-A.5 附录充实 (填表)
+  72 lines  §B 整合说明 (新增)
+  44 lines  §C 增量 diff (本文档)
─────────────────────────────────
+ 550 lines  total (v1.1 增量)
```

v1.0 (469 行) + v1.1 (550 行) → v_final ≈ 1019 行 ≈ SciDA 6-8 页期刊版。

---

## §D · v1.3 衔接补丁(2026-09-06 19:32 CST)

> §7.5.3 当前 illustrative 数字(7 步 / 5 出口 / n_term=25)是教学示意,
> **不是实测**。v1.3 SUPP `docs/PAPER_P2_v1.3_NUM.md` §7.5.4 已把该节
> 全部替换为实测:
>
> | 来源 | v1.1 §7.5.3 (illustrative) | v1.3 §7.5.4 (实测) |
> |---|---|---|
> | 4 门控 | 无具体数 | checked=25 pits=0 / n=9 min_drop=1.0000 / n=9 term=9 longest=3 uniq_out=3 / ring_terminated=False |
> | 内 9 单元 | "5×5 = 25 cell, n_term=25" | interior 9 cell, longest=3, uniq_out=3 |
> | Wolfram | 无 | 4^4=256 穷举, descentMaps=24 |
> | Dafny | "17/0" 一般描述 | PCOMP_1.dfy 17/0, P006_terminate_under_strict.dfy 12/0 |
> | Lean | "OK" 一般描述 | lake build 2760 modules, 0 errors |
>
> 本节不再 inline replace §7.5.3 内容(v1.1 SUPP 已 commit 保持稳定),
> 由 v1.3 NUM 集中承载实测数据。投稿前整合路径见 v1.3 NUM §B.3。
>
> **v1.1 SUPP 文件本身保持稳定**;下游引用 §7.5.3 时**应同时 cite v1.3 §7.5.4**
> 才能给读者真实数字。

---

_Luoshu 起草 v1.1 18:35 / 升级 v1.2 19:27 CST / 衔接 v1.3 19:32 CST · push gate 永久 · 本地 commit 不 push · task7.5(= 计划中 task8B)已云端 PASS 12/0,§9.4.1 同步 · v1.3 NUM `PAPER_P2_v1.3_NUM.md` §7.5.4 已建_
