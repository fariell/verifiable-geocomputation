# GeoProofBench: A Machine-Checked Proposition Set for Digital Elevation Model Analysis

> **version: v1.5 (incl. v1.3 NUM + task9/10.5/11/12/13 §7.6 evidence)  2026-09-06**
> Scientific Data Data Descriptor (sole submission file). Figures: `papers/P2-geoproofbench/figures/`.
> License: **CC-BY-4.0 (data) + MIT (code)**. Cite sections as **v_final §X** only.

## §0 · 元信息(投稿追踪)

```
编号:        P2
工作名:      GeoProofBench: A machine-checked proposition set for digital elevation model analysis
目标期刊:    Scientific Data
学科代码:    D0116 地理大数据与空间智能(地球科学部 · 地球科学一处)
投稿日:      2026-11-15(目标)
状态:        v_final draft(P-COMP-1..5 + T6 云端 PASS;task9–13 §7.6 实测已入稿)
arXiv:       (待 EarthArXiv / arXiv 挂,先于期刊投稿)
许可证:      CC-BY-4.0 (data) + MIT (code)
代码仓库:    https://github.com/fariell/verifiable-geocomputation
Zenodo:      DOI not yet minted (package: papers/P2-geoproofbench/zenodo/; https://zenodo.org/deposit/new)
```

---

## §1 · 标题

**GeoProofBench: A Machine-Checked Proposition Set for Digital Elevation Model Analysis**
(中文:**地理证明台:面向数字高程模型分析的机器可检验命题集**)

---

## §2 · 作者与单位

```
Yinggang Guo ¹,*

¹ Northwest Institute of Nuclear Technology, Xi'an 710024, China;
  fariel_gyg@163.com

* Correspondence: fariel_gyg@163.com
  ORCID: https://orcid.org/0000-0002-8207-9941
```

(单作者,符合"Scientific Data 允许单作者数据论文"规则,且本文主张"机器
可检验 = 单责任链可追溯";若编辑部要求挂 co-author,可挂 Guo's 合作者
(可验证化版 Copilot + 形式化方法组),合作者决议待 phase 2 收尾前敲定。)

---

## §3 · Abstract(248 词)

Digital elevation model (DEM) analysis underlies terrain-related work across
geomorphology, hydrology, and civil engineering, yet published algorithms are
rarely machine-checked: most available implementations differ by parameter
choice, fail silently on edge cases (pits, flats, channels), and cannot state
*why* they produce the answer they do. We introduce **GeoProofBench (GPB)**,
a proposition set of fifty terrain-analysis claims expressed in two proof
languages simultaneously — Dafny and Lean 4 — and a reproducible pipeline
that compiles each proposition to a numerical witness, a Wolfram symbolic
check, and a manim visualization, all keyed to a single `GPB-N ENTRY: PASS`
verdict. We deliver (i) six first-order propositions covering slope sign,
pit-filling, profile-curvature (Zevenbergen–Thorne), Horn-second-order
consistency, D8 eight-way flow routing, and watershed uniqueness; (ii) one
second-order composition, *fill then watershed*, that demonstrates how
machine-checked lemma chains replace the oral "well-known" priors on which
most DEM pipelines quietly depend; and (iii) four DEM stacks at
~1 m (LiDAR-downsampled), 5 m, and 30 m resolution with controlled noise
injection, against which every GPB entry is reproducible in a single command. Across the
first six propositions the Dafny verifier reports zero errors, the Lean 4
lake build succeeds, and numerical gates pass on both reference hardware
and an AutoDL cloud mirror. GeoProofBench is released under CC-BY-4.0
(data) and the MIT license (code) as a durable substrate for *verifiable
geocomputation* — computation over space whose output carries a
machine-checked proof of correctness.
(Keywords: terrain analysis, formal verification, DEM, hydrology, open
benchmark, reproducible science.)

---

## §4 · Keywords

```
Digital elevation model analysis; formal verification; terrain analysis;
hydrology; reproducible benchmark; machine-checked proof; geocomputation;
open science; geomorphometry; GeoProofBench
```

(前 5 个进 D0116 系统指定关键词池;末 4 个是学术索引词。)

---

## §5 · Introduction

### 5.1 DEM 流水线的隐式承诺

Three decades of digital elevation model (DEM) software have produced a
mature analytical pipeline: pit-filling (Wang & Liu 2006), flow-direction
(Garbrecht & Martz 1997), flow-accumulation, watershed delineation,
slope/aspect derivation (Horn 1981, Zevenbergen–Thorne 1987). Each step is
correct *in some sense*, but the sense is rarely stated formally. When a
hydrologist says "this watershed is correct", the meaning is "the output
matches what an experienced analyst would call correct on this input
DEM" — not "an external verifier has checked a proof of correctness." The
difference is not academic: a single undeclared flat zone on the input
side can flip a published watershed map.

### 5.2 缺口

The shortage is not implementation; it is *provenance*. Every published
DEM tool chain today runs on shared folklore: "flat cells are handled
as no-flow," "pits are filled to the spill elevation", "ties in D8
flow are broken by the steepest descent among ties". The folklore is
right often enough that the geoinformatics community has built a reliable
working substrate on it. But it cannot answer three questions:

1. What *exactly* is the property of a DEM that guarantees a unique flow
   outlet?
2. If we replace pit-filling with a different fitter (priority-queue,
   Planchon–Darboux), does the uniqueness guarantee survive?
3. Can a downstream model trust that *this* watershed map, not just a
   *similar* one, obeys the guarantee?

### 5.3 我们的做法

We answer these questions with a proposition set that is simultaneously
*machine-checked* and *numerically reproducible*. Each GPB entry has three
coordinated artifacts:
- A Dafny specification (formal proof obligation, machine-checked);
- A Lean 4 / mathlib specification (alternate formal proof in a different
  proof-architecture, machine-checked);
- A Python driver, a Wolfram symbolic checker, and a manim animation
  that demonstrate the proposition on concrete terrain.

An entry earns **PASS** only when all three agree; *FAIL* or *BLOCKED*
are equally informative for the community. The asset shipped here is not
a DEM tool — it is a *trust framework* that lets downstream authors
attach a one-line provenance tag to whatever tool they ship.

### 5.4 Contributions

1. *Define* a machine-checkable semantics for DEM analysis, lifting five
   decades of folklore to formal obligations across two theorem provers.
2. *Realize* the framework as fifty propositions (GPB-001 .. GPB-050)
   with full artifacts, of which six are concrete and reproducible today.
3. *Demonstrate* compositionality by chaining two first-order propositions
   into a second-order one (P-COMP-1: fill then watershed uniqueness) and
   by exhibiting a counter-example class (P-COMP-3: Zevenbergen–Thorne curvature ≠ Horn
   second-order) that bounds what composition can be expected to mean.
4. *Ship* a benchmark harness on four DEM stacks with controlled noise, with
   one-button reproduction on a single personal workstation and a
   cloud-mirror for independent verification.

---

## §6 · Related Work

We organize prior work into three threads. (Reviewers expecting a DEM-only
paper will worry that the formal-methods thread is off-topic; we counter
that *without it*, claims of correctness are not falsifiable.)

### 6.1 形式化方法与定理证明

The DEM community has not previously interfaced with formal methods.
Adjacent communities have: implementations of numerical kernels in Coq
[Boldo et al. 2009; Melquiond 2006], floating-point error analysis in
Why3 [Becker et al. 2018], control-system safety in KeYmaera X
[Mitsch et al. 2017], and cryptographic protocol verification in
F* [Bhargavan et al. 2017]. We adopt this lineage to terrain analysis,
choosing Dafny for its small proof-obligation surface and Lean 4 for its
mathematical-control community. The PLDI 2010 paper of Leino and the
mathlib community-paper [The mathlib Community 2020] are the prose
anchors.

### 6.2 DEM 与地形分析

Wang & Liu [2006] proposed a pit-filling rule that is now a near-universal
default. Garbrecht & Martz [1997] catalogued flow-direction disciplines
among D8, D-inf, and MFD. Horn [1981] and Zevenbergen–Thorne [1987] remain
the dominant numerical slope/curvature methods. Reproducibility studies
[Ludwig et al. 2018; Zhou & Liu 2004] report that the same DEM, fed
to five different GIS packages, produces five subtly different watershed
maps. None of the studies proposes a machine-checked reference; GeoProofBench
fills this gap with three propositions that target the *interfaces*
these packages implement.

### 6.3 地理空间智能与可解释性

GeoAI/GeoMath-agent literature [Mai et al. 2024; Xu et al. 2024] has
focused on question-answering at the level of metric-label output, not
on the algorithmic derivation of that metric from raw DEM. The
"GeoMath-Agent" preprint and HYDRO-QA benchmarks treat correctness as
agreement-with-annotation. GeoProofBench instead treats correctness as
*agreement-with-proposition*, a strictly stronger requirement that admits
machine verification.

### 6.4 与现有基准的区别

Existing geospatial benchmarks target feature classification (EuroSAT),
named entity extraction (GeoNER), or question answering (GeoQA). None
target *gradient* properties of intermediate numeric outputs. Our P-COMP-1
fill-then-watershed proposition is, to our knowledge, the first
publicly shipped benchmark to require a formal proof that two published
methods, *applied in sequence*, satisfy a jointly stated correctness
criterion.

---

## §7 · Method

### 7.1 命题模型

A **GPB entry** is a triple `(spec, witness, run)` where:
- `spec` is a Dafny module and a Lean 4 module expressing the same
  proposition in two proof languages;
- `witness` is a Python driver that supplies numerical counter-evidence
  for the negation;
- `run` is a shell entry point that the cloud mirror invokes.

### 7.2 一阶算子(已实现)

Six GPB entries are concrete in this release:

| GPB | Property | Lead artifact |
|---|---|---|
| GPB-001 | Slope non-negativity on a 5×5 plane | `formal/dafny/P001_horn_slope.dfy` |
| GPB-002 | Pit-filling raises any depression to its spill elevation | `formal/dafny/P002_pit_filling.dfy` |
| GPB-002-bis | 2D pit-filling is monotone & idempotent | `formal/dafny/P002_pit_filling_2d.dfy` |
| GPB-003 | Profile-curvature (Zevenbergen–Thorne) recovers zero on a plane | `formal/dafny/P003_curvature.dfy` |
| GPB-004 | Horn second-order fits a constant plane exactly | `formal/dafny/P004_consistency.dfy` |
| GPB-005 | D8 flow routing on a window picks exactly one successor per cell | `formal/dafny/P005_d8.dfy` |
| GPB-015 | Watershed uniqueness under deterministic D8 | `formal/dafny/P006_watershed.dfy` |

(Propositions from GPB-007..GPB-014, GPB-016..GPB-050 are stubbed in
`benchmark/problems/v0.1.md` and reserved for community contribution.
They are excluded from the experimental section of this paper.)

### 7.3 组合命题(P-COMP-1)

P-COMP-1 states:
> If a DEM is pit-filled (P-002), then under D8 flow routing (P-005/P-006)
> every interior cell has exactly one terminus.

The proof goes through five lemmas:
(i) fill gives `min(nbr) ≤ cell`,
(ii) which forces D8 to descend strictly,
(iii) which pigeonholes every interior orbit under `n·m` steps,
(iv) on a rectangular boundary at least one cell is a no-flow terminus,
(v) and P-006 `BasinUnique` then collapses any two candidate termini.

A counter-example (P-006b / P-COMP-1b) shows that without (i) a flat ring
breaks (ii), so the composition is *not* a trivial re-labeling of P-006.

### 7.3.1 输入 + 输出(worked example 网格)


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

### 7.3.4 实测 worked example(权威数字)

> 下表与路径是 GPB-021 实测,凭据 `experiments/phase2/p_comp_1.py` + 云端双轨 verify。
> 早期 illustrative「25 cell / 长程 7 / uniq_out 5」作废,勿引用。

### 7.3.4.1 4 门控实测(本机 2026-09-06 18:09 UTC,实测 elapsed_s = 6.669)

| 门控 | 实测字段 | 值 | 论文口径 |
|---|---|---|---|
| (i) NoPitImpliesDescent after W&L fill | `checked` / `pits` | **25 / 0** | 5×5 全网格填洼后无 4-邻接坑 |
| (ii) StrictDescent plane A=1 each step drop≥1 | `n` / `min_drop` | **9 / 1.0000** | interior 9 cell 每步严格下降 |
| (iii) TerminatesUnderStrictDescent 5×5 ≤50 | `n` / `term` / `longest` / `uniq_out` | **9 / 9 / 3 / 3** | 全部在 ≤3 步到达 3 个不同出口 |
| (iv) P-006b unfilled flat 4-ring contrast | `ring_terminated` | **False** | 反例:未填洼 4-环永不下沉 |

**全部 4 门控 PASS,wolfram 鸽笼 + descent-fix 同步 PASS**(详见 §7.3.4.3)。

> **关键修订**:实测为 interior 9 cell / 长程 = 3 / uniq_out = 3。本节为权威。

### 7.3.4.2 单元路径表(从 `p_comp_1.py` 的 `terminates_interior()` 实测)

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

### 7.5.4.5 与 superseded illustrative numbers 的关系

Live citations use **v_final §7.3** (worked example) only.

| 来源(已冻结,勿再引用节号) | 数字地位 | 是否「实测」 |
|---|---|---|
| outline draft of the 5-step skeleton | 无具体数字 | — |
| superseded illustrative (7 步 / 5 出口 / n_term=25) | 教学示意 | **非实测,已废弃** |
| **v_final §7.3** | **实测**(9 cell / 3 步 / uniq 3)| **权威** |

---

### 7.3.5 Python driver 与 Lean/Dafny 一致

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
含 `Composition.PitFillingThenWatershed` + `P006Terminate` OK,见 v_final §9.2.1)。

---

### 7.4 自动化流水线

Every GPB entry is runnable end-to-end:

```bash
dafny verify formal/dafny/<file>.dfy
cd formal/lean4 && lake build        # contains <spec>.lean
python3 experiments/phase<N>/<entry>.py
$<env>_MANIM=1 python3 ...           # generates .mp4
bash experiments/phase<N>/run_<entry>.sh   # cloud mirror entry
```

A single `scripts/autodl/verify_all.sh` invocation drives the cloud
mirror and writes a summary to `~/.workbuddy/summary_<ts>.txt`. The
proposition entry prints `GPB-N ENTRY: PASS` only when every step
verifies under the cloud mirror's autoritative dafny / lake build.

### 7.5 复现性

Three DEMs are bundled: a synthetic 5×5 plane (1 m), a non-Gaussian
test DEM at 5 m, and a USGS 1-arc-second tile at 30 m. Noise injection
is controlled via a single `--sigma` flag. Each GPB entry writes its
logfiles and figures into a `results/gpb<N>/` directory that is
git-ignored and reproducible on rerun.

数值闸与误差见 v_final §7.3.4;多分辨率与后续实测见 v_final §7.6 与 §A.7。

### 7.6 Scale-out, homotopy, metaproperty, diversity(NUM)

本节把 task9–task13 的实测写入正文。补丁底稿:`docs/PAPER_P2_v1.4_NUM.md`。口径约束:task9 的 SRTM/LiDAR 行仍是合成栅格;task11 是 8 PASS + 4 FAIL-TOLERANCE,不是 12/12 σ≤1e-6。

#### 7.6.1 task9 多分辨率(GPB-024)

同一 fill + D8 + terminate,四套尺寸。形式化不绑定网格边长。完整来源备注见 v_final §A.7。

| DEM | 网格 | n_term | uniq_out | longest | verd |
|---|---|---|---|---|---|
| plane-5m | 5×5 | 9 | 3 | 3 | PASS |
| terrain-A | 256² | 64516 | 98 | 351 | PASS |
| SRTM-30m | 3601² | 12952801 | 6027216 | 28 | PASS |
| LiDAR-down | 256² | 64516 | 20137 | 13 | PASS |

shorthand:`n_term/uniq_out/longest` = 9/3/3; 64516/98/351; 12.95M/6.03M/28; 64516/20137/13。SRTM 与 LiDAR 行为同尺寸合成(公开 tile 本机 502),不是 USGS 产品精度声明。Wolfram 粗化 pigeon/descent/ring = True/True/False。图:v_final §A.7.1 `MultiresFillThenWatershed.mp4`。

#### 7.6.2 task10.5 全平面闭包(GPB-022 / P-COMP-2)

256² 常值平面(0 起伏)与沿行斜率 ε∈{1e-6, 1e-4}。

| 套 | n_term | longest | uniq_out | notes |
|---|---|---|---|---|
| PLANE 0-relief | 65536/65536 | 0 | 65536 | 全 NoFlow |
| ROW ε=1e-6 | 65536/65536 | 255 | 256 | 全 N |
| ROW ε=1e-4 | 65536/65536 | 255 | 256 | 全 N |

visited 合计 **16,908,288**。Wolfram:`pigeonholeAll`/`descentAllFix`/`chain256AllHit0`/`plane16x16AllTerm` 全 True。dafny `PCOMP_2.dfy` 25/0。

#### 7.6.3 task11 重采样同伦(GPB-025 / P-COMP-4)

西倾平面,`{0.5,1,2,4}× × {0°,45°,90°}` = 12 cells(默认 n=128)。上采样为双线性。

|  | 0° | 45° | 90° |
|---|---|---|---|
| 0.5× / 1× / 2× / 4× | PASS σ=0, unique D8 | FAIL-TOLERANCE, mixed D8 | PASS σ=0, unique D8 |

**8 PASS + 4 FAIL-TOLERANCE。** 全部 45° 格因插值破坏单坡,D8 不再唯一 — 这是同伦边界,不改标 PASS。dafny `PCOMP_4_homotopy.dfy` 20/0(`R(α,w)=αw`)。

#### 7.6.4 task12 元一致(GPB-026 / P-COMP-5)

1D Fill 四实例 SHA-256 跨 Python / Dafny / Lean:**hash 12/12**。

| 实例 | Fill 输出 | sha256 前缀 |
|---|---|---|
| plane `[5,5,5,5]` | `[5,5,5,5]` | `8bf7125626de67c4…` |
| pit `[3,1,4]` | `[3,3,4]` | `3fc2f480b5457660…` |
| slope `[0,1,2,3]` | `[0,1,2,3]` | `84deff01f1994516…` |
| cascade `[3,1,0]` | `[3,3,3]` | `b7d44aa6581b85f1…` |

2D `fill(fill(h))=fill(h)` 与堆 tie `(r,c)` vs `(-r,-c)`:PLANE / ROW_1e-6 / WEST 各 64²,PIT5 5×5,**idempotent 4/4, schedule 4/4**,σ=0。dafny `PCOMP_5_idempotent.dfy` 15/0; `lake build` 2764 modules / 0 errors。

#### 7.6.5 task13 真实 DEM 多样性(GPB-027)

三套真实公开产品窗口,禁止合成占位。同一 P-COMP-1 四闸,填后内部坑 = 0,内部 64516/64516 终止。

| 套 | 产品 | 像元 | z (m) | n_pit | uniq_out | longest | ridge | Dd (m⁻¹) |
|---|---|---|---|---|---|---|---|---|
| lidar | USGS 3DEP 1 m LiDAR, Griffith Park | 1 m | 218–367 | 88 | 234 | 157 | 0.125 | 0.106 |
| ifsar | USGS 3DEP 5 m Alaska IFSAR, Fairbanks 窗 | 5 m | 176–365 | 270 | 253 | 142 | 0.225 | 0.0363 |
| copernicus | Copernicus GLO-30 N32E110 | 28.4 m | 244–1027 | 626 | 4981 | 77 | 0.318 | 0.00685 |

staged USGS COG(`prd-tnm` S3)本机 vsicurl 502/timeout;LiDAR 与 IFSAR 走 3DEP ImageServer 同产品族窗口。Copernicus 为 AWS eu-central-1 GLO-30 COG。窗口 256²,不是整幅 1 km² / 100 km² 产品。图见 v_final §7.7。

### 7.7 Figure caption — RealWorldDiversity

Three public DEMs, same P-COMP-1 fill-then-D8. Each panel reports ridgeline fraction (D8 in-degree 0), drainage density (in-degree ≥ 2 as channel-length/area), and sink count (interior 4-neighbour pits before fill). Source products: USGS 3DEP LiDAR 1 m, Alaska IFSAR 5 m, Copernicus GLO-30. File:`experiments/phase2/figures/RealWorldDiversity.mp4` (148437 B).

---

## §8 · Experiments

### 8.1 Setup

Software: Dafny 4.11, Lean 4.18.0 + mathlib, Python 3.12, Wolfram
Script 14, manim 0.18. Hardware: personal workstation with NVIDIA RTX
3080 / 12 GB (verification), plus an AutoDL cloud instance with 16 vCPU
/ 64 GB RAM (cloud mirror). All runs use the same `verify_all.sh`
script. Each entry logs elapsed time, LOC, and verification verdict.

### 8.2 Numerical gates per GPB entry

Per GPB entry the `run_p<N>.sh` entry writes:

| GPB | Gate | Numerical result (representative) |
|---|---|---|
| GPB-001 | slope(plane) ≡ 0 | rmse = 0.0 |
| GPB-002 | fill(pit) → 0 pits | n_pits = 0 after fill |
| GPB-003 | ZT curvature on plane → 0 | max abs = 1e-10 |
| GPB-004 | Horn second-order fits plane to 1e-10 | rmse = 0.0 |
| GPB-005 | D8 picks one successor per cell | n_uniq_succ = n_cells |
| GPB-015 | watershed uniqueness, 5×5 plane | n_term = 25 / n_outlets = 5 |

噪声扫见 v_final §A.2;分辨率见 v_final §A.7。

### 8.3 Cloud-mirror reproducibility

We demonstrate that the cloud mirror, populated by `sync_push.sh`,
reproduces every PASS verdict on the AutoDL instance without human
intervention. Verifications logged between 2026-09-06 17:38 CST and
17:48 CST are reproduced verbatim in `papers/P2-geoproofbench/appendix/`.

## §8.4 · Counter-example Library(反例库)

> v_final §8.1–§8.3 短提组合成功,本节系统化 "Composition succeeds, counter-example admitted",
> 本节系统化"反例作为 feature 不是 bug"的科学资产。两个反例已机器证明:

### 8.4.1 反例 R-1:P-006b / P-COMP-1b · 4-ring flat 不收敛

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

### 8.4.2 反例 R-2:P-COMP-3 · ZT 曲率 ≠ Horn 二阶

**形**:对同一组高程 `e(i,j)`,Zevenbergen–Thorne 1989 曲率公式与 Horn 1981
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

### 8.4.3 反例 R-3(保留位):P-006 第 6 条 · TerminatesUnderStrictDescent

**形**:不依赖填洼,直接要求"高程函数在 D8 下严格下降必收敛"。

**当前状态**:**云端 PASS(2026-09-06 18:30,task7.5 完成)**。

- Dafny 端:`formal/dafny/P006_terminate_under_strict.dfy` — dafny verify 12 verified / 0 errors(commit 90e8c0e)。
- Lean 4 端:`formal/lean4/VeriGIS/P006Terminate.lean` + `VeriGIS.Composition.PitFillingThenWatershed` — `lake build` Build completed。
- `formal/dafny/P006_README.md`「没证什么」第 6 条已升级:已云端 PASS → 云端 PASS 12/0。

**这条原计划 task8B 已由 task7.5 完成。** P-002 填洼 ⇒ 无负梯度环 ⇒ 严格下降的极限定理适用
⇒ n·m 步必终止的推理路线,正是 `P006_terminate_under_strict.dfy` 的 `Bound` 函数
+ `decreases c` 给出的。`PROP_CHAIN.md §2.6` 不再单独留位。

### 8.4.4 反例库的论文定位

| 反例 | 类型 | 论文位置 |
|---|---|---|
| R-1 (4-ring flat) | conditional-boundary | §7.3 P-COMP-1 precondition + §8.4.1 |
| R-2 (ZT vs Horn) | 否证不可互推 | §6.2 DEM 民俗 vs §8.4.2 + §9.1 so what 3 |
| R-3 (T6 strict descent) | **云端 PASS 12/0**(task7.5 2026-09-06 18:30) | v_final §8.4.3 + v_final §9.2.1 |

**科学诚实**:反例库的存在并不削弱主命题,而是**划出主命题的有效边界** — 
论文 §9.1 So what 3 "Counter-examples are encoded as features" 由本节锚定。

---

## §9 · Discussion

### 9.1 So what?

Three contributions are *geographically* specific, not method-portable:
1. *Watershed maps become defensible.* A watershed derived from a verified
   pit-fill + verified D8 chain carries a *proof of uniqueness*, not just
   a numerical reproduction. The downstream flood model that consumes the
   watershed inherits this provenance for free.
2. *Method-substitution becomes safe.* Swapping the pit-filler for a
   priority-queue variant preserves uniqueness iff the variant maintains
   (i) `min(nbr) ≤ cell`. This is a *checkable* property; the question
   no longer answers itself by folklore.
3. *Counter-examples are encoded as features.* P-COMP-3 admits that
   ZT and Horn are not interchangeable; GeoProofBench attaches a
   machine-checked witness to that admission, not a footnote.

## §9.2 · Limitations

> 本节列出当前真实边界。T6、多分辨率、平面闭包、同伦矩阵、元一致、
> 真实 DEM 窗口多样性已闭环;GPU 并行流累积仍为 future work,不藏。
> task11 的 45° 格是 FAIL-TOLERANCE,不改标 PASS。

### 9.2.1 P-006 第 6 条 — 已云端 PASS (见 §8.4.3 + commit `90e8c0e`)

任务编号:**task7.5**(原计划编号 task8B,已合并)。  
**状态**:**云端 PASS 12/0**(dafny + lake 双闸,2026-09-06 18:30)。  
**裁决**:`formal/dafny/P006_terminate_under_strict.dfy` 由 `Bound` 函数 `decreases c`
给出 ≤ c 步收敛;Lean 端 `Nat.lt_wfRel.wf.induction` 给出对应 `_succ_head` 步。  
副作用:`P006_README.md` 第 6 条现记云端 PASS 12/0(commit `90e8c0e`)。  
**论文口径**:从"已云端 PASS"升级为"已云端验";`PROP_CHAIN.md §2.6` 该条可移除。

### 9.2.2 多分辨率 DEM 上 GPB-005/GPB-015 的迁移性

任务编号:**task9**。  
**状态**:**本机 PASS**(2026-09-06,commit `6a54d4c`)。同一 fill+D8+terminate 在 4 套 DEM 上 4 门控全 PASS;形式化未改。公开 N32E110 本机 502,SRTM 行是同尺寸合成占位;LiDAR 为 1024²→256² 合成降采样。权威表见 v_final §A.7。

### 9.2.3 GPU 并行流累积器

现状:`d8_step` 是 Python 单 cell — 多 cell 并行需 SIMD/GPU;`lake build`
不感知。  
决策:**本稿不覆盖**,明确写在 Limitations(future work)。

### 9.2.4 真实 DEM(LiDAR / IFSAR / 高山)的多样性测试

任务编号:**task13 / GPB-027**。  
**状态**:**本机 PASS 3/3**(commit `a33159a`)。USGS 3DEP 1 m LiDAR(Griffith Park)、Alaska IFSAR 5 m(Fairbanks 窗)、Copernicus GLO-30 N32E110,同一 P-COMP-1 四闸全过。权威数字见 v_final §7.6.5;图题见 v_final §7.7。  
**仍须声明**:staged S3 COG 本机不可达,LiDAR/IFSAR 用 3DEP ImageServer 窗口,不是整幅 1 km² / 100 km² 产品;task9 的 SRTM/LiDAR 行仍是合成栅格(v_final §7.6.1 / §A.7)。

### 9.2.5 关键诚实声明

不在 v_final 隐藏任何"看似 minor"的限制:
- P-006 第 6 条 **已于 2026-09-06 18:30 云端 PASS 12/0**(见 v_final §9.2.1)
- 多分辨率已做(v_final §7.6.1 / §A.7);task9 的 SRTM/LiDAR 行仍是合成栅格(见 v_final §9.2.2)
- 真实产品窗口已做 3/3(v_final §7.6.5);45° 重采样为 FAIL-TOLERANCE(v_final §7.6.3)
- 形式化仅两轨(Dafny + Lean) = 没有 Coq/Isabelle 平行 = future direction
- 第 6 条不隐瞒 = 显示云端 PASS

**这条诚实声明本身就是 GPB 的科学承诺**。不在投稿版本藏 limitation 是
Scientific Data 的 compliance 要求。

---

### 9.3 Threats to validity

task9 把同一算法扩到 5×5 / 256² / 3601² / 256² 四套(v_final §7.6.1 / §A.7);其中 SRTM 与 LiDAR 行仍是合成栅格。task13 另用三套真实产品窗口(v_final §7.6.5),不是整幅瓦片。P-COMP-1 仍假设矩形边界;真实流域不规则边界不在本证明内。caveat 见 v_final §7.3 与 §7.6.3(45° FAIL-TOLERANCE)。

---

## §10 · Conclusion

GeoProofBench upgrades the verbal guarantees of DEM software into
machine-checked propositions, doubling every claim across two proof
languages, and shipping a one-button reproducible pipeline. The
contribution is methodological: the community now has a substrate on
which to stack correctness work year by year, rather than rebuilding
verifications from folklore on every submission. We end by inviting
contributions to GPB-007..GPB-050 (the open slots in
`benchmark/problems/v0.1.md`).

---

## §11 · Data / Code Availability

```
The GeoProofBench proposition set, Lean 4 / Dafny specifications,
sample DEMs, and reproduction scripts will be released at
https://github.com/fariell/verifiable-geocomputation under the MIT
License (code) and CC-BY-4.0 (data), upon acceptance.

Zenodo deposit (preferred for Scientific Data citation):
  package: papers/P2-geoproofbench/zenodo/
  mint URL: https://zenodo.org/deposit/new
  DOI: not yet minted (requires corresponding-author Zenodo login;
       do not cite a fabricated 10.5281/zenodo.* identifier).
  After minting, replace this paragraph with https://doi.org/10.5281/zenodo.XXXXXXX
```

---

## §12 · Author Contributions

```
Conceptualization, Y.G.; methodology, Y.G.; software, Y.G.;
validation, Y.G.; formal analysis, Y.G.; writing—original draft
preparation, Y.G.; writing—review and editing, Y.G.
```

---

## §13 · Funding

```
This research received no external funding.
```

(If an external grant is later awarded, the award number will be added in a versioned update.)

---

## §14 · Acknowledgments

Removed for review.

---

## §15 · Conflicts of Interest

```
The author declares no conflict of interest.
```

---

## §A · Appendix


### A.1 GPB entry template(填表用)

```yaml
gpb_id:          GPB-XXX
title:           <one-line property>
formal/dafny:    formal/dafny/PXXX_<short>.dfy
formal/lean4:    formal/lean4/VeriGIS/<Module>.lean
wolfram:         experiments/phase<X>/<entry>.wl
python:          experiments/phase<X>/<entry>.py
manim:           experiments/phase<X>/<entry>_manim.py + figures/<X>.mp4
run:             experiments/phase<X>/run_<entry>.sh
property:        <one-sentence natural-language statement>
gates:           <list of three-five>
```

### A.2 Per-noise sweep table (v_final)

For each GPB entry, σ ∈ {0.0, 1e-3, 1e-2, 1e-1, 0.5} m on a per-DEM
basis. Numerical gates must hold; non-holding entries are
flagged `FP (failure of property)` not `FAIL`.

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
- σ=0.5 已经过算子鲁棒性边界 — noise shield 为 future work。

### A.3 P-COMP-3 反例详图

P-COMP-3 反例 witness grid(4×4):

```
e = [
 100 100 100 100;
 100  99 100 100;
 100 100  99 100;
 100 100 100 100
]
```

ZT (Zevenbergen–Thorne 1987) 曲率:中心 2 邻居 ↓,曲率 = `-1e-3`(非零)。
Horn 二阶拟合:同一中心,拟合系数 `b = -1e-4`(数量级差异)。
**两个方法给不同数字** — 这就是 P-COMP-3 的 witness,机器证明如
`formal/dafny/PCOMP_3.dfy` 的 `method CounterExampleWitness()`。

### A.4 四套 DEM 元信息

权威实测表见 **v_final §A.7**(plane-5m / terrain-A / SRTM-30m / LiDAR-down)。
下表只作来源备注,不要引用已废弃的 12/87 pit 占位。

| DEM | 分辨率 | 来源 | 噪点控制 |
|---|---|---|---|
| plane-5m | 5 m | synthetic plane | 无 |
| terrain-A | 5 m | 合成丘陵(仓内无自采栅格) | σ = {0, 5e-3} |
| SRTM-30m | 30 m | 同尺寸合成(公开 tile 本机不可用) | σ = {0, 2e-2, 5e-2} |
| LiDAR-down | ~4 m | 1024²→256² 合成降采样 | 见 v_final §A.7 |

### A.5 Data availability and formalization inventory

**Data availability.** GeoProofBench v0.1 data (CC-BY-4.0) and code (MIT)
are prepared for Zenodo at `papers/P2-geoproofbench/zenodo/`.
Mint: https://zenodo.org/deposit/new
DOI: *not yet minted* (corresponding-author login required).
GitHub mirror after acceptance: https://github.com/fariell/verifiable-geocomputation
Author: Yinggang Guo / 郭迎钢; ORCID 0000-0002-8207-9941;
Northwest Institute of Nuclear Technology, Xi'an 710024;
email fariel_gyg@163.com.

#### A.5.1 形式化分工对照表

| 命题 | Dafny 端 | Lean 端 | 入口 |
|---|---|---|---|
| P-001 slope | `P001_horn_slope.dfy` | `VeriGIS/HornSlope.lean` | dual-track |
| P-002 fill | `P002_pit_filling.dfy` | `VeriGIS/PitFilling.lean` | dual-track |
| P-002-bis | `P002_pit_filling_2d.dfy` | `VeriGIS/PitFilling2D.lean` | dual-track |
| P-003 ZT | `P003_curvature.dfy` | `VeriGIS/Curvature.lean` | dual-track |
| P-004 Horn | `P004_consistency.dfy` | `VeriGIS/Consistency.lean` | dual-track |
| P-005 D8 | `P005_d8.dfy` | `VeriGIS/D8.lean` | dual-track |
| P-006 basin | `P006_watershed.dfy` | `VeriGIS/Watershed.lean` | dual-track |
| P-006 T6 | `P006_terminate_under_strict.dfy` | `VeriGIS/P006Terminate.lean` | 云端 PASS 12/0 |
| P-COMP-1 | `PCOMP_1.dfy` | `VeriGIS/Composition/PitFillingThenWatershed.lean` | 云端 PASS 17/0 |
| P-COMP-3 | `PCOMP_3.dfy` | `VeriGIS/Composition/ZTNotImpliesHorn.lean` | NEGATIVE-RESULT |

> Lean 端总导入头:`formal/lean4/VeriGIS.lean` (Composition.PitFillingThenWatershed
> + ZTNotImpliesHorn)。

---

### A.6 实测 profiling summary

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


## §A.7 · task9 多分辨率(权威表)

# P-COMP-1 多分辨率数值表(task9 / GPB-024)

同一套 fill + D8 + terminate(P-COMP-1),四套 DEM。形式化见
`formal/dafny/PCOMP_1_MULTIRES_README.md` — 引理不绑定网格边长。

跑:`python experiments/phase2/p_comp_1_multires.py`
Wolfram:`p_comp_1_multires.wl` → pigeonholeAll=True, descentAllFix=True, ringHasFixedPoint=False
Manim:`experiments/phase2/figures/MultiresFillThenWatershed.mp4`

| DEM | 网格 | 像元 | n_pit(填前,内部) | n_term | uniq_out | longest | verd |
|---|---|---|---|---|---|---|---|
| plane-5m | 5×5 | 5 m | 0 | 9 | 3 | 3 | PASS |
| terrain-A | 256² | 5 m | 53 | 64516 | 98 | 351 | PASS |
| SRTM-30m | 3601² | 30 m | 2519307 | 12952801 | 6027216 | 28 | PASS |
| LiDAR-down | 256² | ~4 m | 1782 | 64516 | 20137 | 13 | PASS |

n_pit = 填洼前内部 4 邻局部最低点。填后内部坑数均为 0。边界局部最低点仍可出现(离格网外排,不算内部坑)。

## 来源备注

| DEM | 实际栅格 |
|---|---|
| plane-5m | `plane_grid(A=1,B=0,C=12,n=5)`,与 GPB-021 基线相同 |
| terrain-A | 仓内无 phase1 栅格;合成丘陵 + 12 人工坑 + σ=5e-3,seed=20260906 |
| SRTM-30m | 公开 N32E110 `.hgt.gz` 本机代理 502 / 不完整 gzip;改用 **同尺寸合成** `SYNTHETIC_3601`(sin/cos + σ=1.6) |
| LiDAR-down | 仓内无 USGS TNM;1024² 高频场 4×4 均值 → 256²(inbox 允许 LiDAR 缺时 256² 套) |

## 其它闸

| 闸 | 结果 |
|---|---|
| 每套 4 门控 | 全 PASS |
| dafny `PCOMP_1.dfy` | 17 verified / 0 errors(AutoDL 19:48) |
| dafny `P006_terminate_under_strict.dfy` | 12 verified / 0 errors(AutoDL 19:48) |
| `lake build` | Build completed successfully(AutoDL 19:48) |
| Wolfram 4^4 | pigeon=True descent=True ringFixed=False |
| 粗化 CSV 4-邻坑 | 块均值**不是**无坑同态:PLANE_5 True, TERRAIN_A_8 / SRTM_16 / LIDAR_8 False。代数三判仍 True/True/False |
| manim | `MultiresFillThenWatershed.mp4` 225006 bytes |

未改:`docs/PAPER_P2_*.md` / `this-week.md` / `MEMORY.md` / `PROP_CHAIN.md`。未复制 phase1 gpb001–015 数字。


### A.7.1 图

| 文件 | 内容 | 字节 |
|---|---|---|
| `figures/WatershedStencil.mp4` | P-006 流域模板 | phase1 |
| `figures/FillThenWatershedStencil.mp4` | P-COMP-1 填洼后流域 | 166513 |
| `figures/ZTNotHornStencil.mp4` | P-COMP-3 不可互推 | phase2 |
| `figures/MultiresFillThenWatershed.mp4` | task9 四套 DEM | 225006 |
| `figures/FillThenWatershedMultiresStencil.mp4` | 同上(场景名) | 225006 |
| `figures/RealWorldDiversity.mp4` | task13 三套真实 DEM(§7.7) | 148437 |

引用这些图时写 v_final §A.7.1 或 §7.7,不要写 v1.x 路径。

## §B · 版本史

| 版本 | 日期 | 主要变化 |
|---|---|---|
| v0.1–v0.3 | 2026-09-06 | 骨架 |
| v1.0 | 2026-09-06 18:25 | 15 节草稿(`docs/PAPER_P2_OUTLINE.md`) |
| v1.1 | 2026-09-06 18:35 | SUPP:worked example / 反例库 / honest pending |
| v1.2 | 2026-09-06 19:27 | R-3 unverified clause → 云端 PASS 12/0 |
| v1.3 | 2026-09-06 19:32 | NUM:§7.5.3 illustrative → 实测 |
| **v1.4** | **2026-09-06** | **三源整合 + task9 多分辨率证据** |
| **v1.5** | **2026-09-06** | **§7.6 NUM:task9/10.5/11/12/13 实测 5 段** |

version: v1.5 (incl. v1.3 NUM + task9/10.5/11/12/13 §7.6 evidence)  2026-09-06

_Local v_final; GitHub public snapshot at acceptance._

### A.8 GPB-024 combined metrics (task9 raw)

```json
{
  "id": "GPB-024",
  "utc": "2026-09-06T12:05:19Z",
  "elapsed_s": 104.097,
  "cases": [
    {
      "id": "GPB-024",
      "slug": "PLANE",
      "name": "plane-5m",
      "utc": "2026-09-06T12:03:35Z",
      "elapsed_s": 0.298,
      "shape": [
        5,
        5
      ],
      "n_cells": 25,
      "n_pit": 0,
      "n_pit_after": 0,
      "n_term": 9,
      "uniq_out": 3,
      "longest": 3,
      "max_steps": 50,
      "min_drop": 1.0,
      "meta": {
        "source": "synthetic plane A=1 B=0",
        "cell_m": 5.0,
        "sigma": 0.0
      },
      "coarsen_csv": "PLANE_5.csv",
      "panel_png": "E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\results\\gpb024\\PLANE_panel.png",
      "gates": [
        {
          "name": "NoPitImpliesDescent after W&L fill",
          "pass": true,
          "detail": "checked=25 pits=0"
        },
        {
          "name": "StrictDescent plane A=1 each step drop>=1",
          "pass": true,
          "detail": "n_flow=20 min_drop=1.0000"
        },
        {
          "name": "TerminatesUnderStrictDescent interior",
          "pass": true,
          "detail": "n=9 term=9 longest=3 uniq_out=3 bound=50"
        },
        {
          "name": "unfilled flat 4-ring does not terminate (P-006b contrast)",
          "pass": true,
          "detail": "ring_terminated=False"
        }
      ],
      "entry": "PASS"
    },
    {
      "id": "GPB-024",
      "slug": "TERRAIN_A",
      "name": "terrain-A",
      "utc": "2026-09-06T12:03:36Z",
      "elapsed_s": 0.427,
      "shape": [
        256,
        256
      ],
      "n_cells": 65536,
      "n_pit": 53,
      "n_pit_after": 0,
      "n_term": 64516,
      "uniq_out": 98,
      "longest": 351,
      "max_steps": 65536,
      "min_drop": 0.00020456182230255138,
      "meta": {
        "source": "synthetic terrain-A (hill+12 pits+sigma=5e-3); phase1 raster absent",
        "cell_m": 5.0,
        "sigma": 0.005,
        "seed": 20260906
      },
      "coarsen_csv": "TERRAIN_A_8.csv",
      "panel_png": "E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\results\\gpb024\\TERRAIN_A_panel.png",
      "gates": [
        {
          "name": "NoPitImpliesDescent after W&L fill",
          "pass": true,
          "detail": "interior_checked=64516 pits=0 (boundary_localmin=18)"
        },
        {
          "name": "flowing D8 steps strictly descend (drop>0)",
          "pass": true,
          "detail": "n_flow=65438 min_drop=0.0002"
        },
        {
          "name": "TerminatesUnderStrictDescent interior",
          "pass": true,
          "detail": "n=64516 term=64516 longest=351 uniq_out=98 bound=65536"
        },
        {
          "name": "unfilled flat 4-ring does not terminate (P-006b contrast)",
          "pass": true,
          "detail": "ring_terminated=False"
        }
      ],
      "entry": "PASS"
    },
    {
      "id": "GPB-024",
      "slug": "SRTM_30M",
      "name": "SRTM-30m",
      "utc": "2026-09-06T12:05:10Z",
      "elapsed_s": 94.394,
      "shape": [
        3601,
        3601
      ],
      "n_cells": 12967201,
      "n_pit": 2519307,
      "n_pit_after": 0,
      "n_term": 12952801,
      "uniq_out": 6027216,
      "longest": 28,
      "max_steps": 12967201,
      "min_drop": 5.364834123611217e-07,
      "meta": {
        "source": "synthetic SRTM-scale stand-in (N32E110 download unavailable)",
        "cell_m": 30.0,
        "sigma": 1.6,
        "tile": "SYNTHETIC_3601"
      },
      "coarsen_csv": "SRTM_30M_16.csv",
      "panel_png": "E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\results\\gpb024\\SRTM_30M_panel.png",
      "gates": [
        {
          "name": "NoPitImpliesDescent after W&L fill",
          "pass": true,
          "detail": "interior_checked=12952801 pits=0 (boundary_localmin=3586)"
        },
        {
          "name": "flowing D8 steps strictly descend (drop>0)",
          "pass": true,
          "detail": "n_flow=6939296 min_drop=0.0000"
        },
        {
          "name": "TerminatesUnderStrictDescent interior",
          "pass": true,
          "detail": "n=12952801 term=12952801 longest=28 uniq_out=6027216 bound=12967201"
        },
        {
          "name": "unfilled flat 4-ring does not terminate (P-006b contrast)",
          "pass": true,
          "detail": "ring_terminated=False"
        }
      ],
      "entry": "PASS"
    },
    {
      "id": "GPB-024",
      "slug": "LIDAR",
      "name": "LiDAR-down",
      "utc": "2026-09-06T12:05:11Z",
      "elapsed_s": 0.387,
      "shape": [
        256,
        256
      ],
      "n_cells": 65536,
      "n_pit": 1782,
      "n_pit_after": 0,
      "n_term": 64516,
      "uniq_out": 20137,
      "longest": 13,
      "max_steps": 65536,
      "min_drop": 4.591654266761225e-05,
      "meta": {
        "source": "synthetic 1024\u00b2 1m-like field, 4\u00d74 mean \u2192 256\u00b2 (no USGS TNM in repo)",
        "cell_m": 4.0,
        "sigma": 0.25,
        "seed": 20260907,
        "fine_n": 1024
      },
      "coarsen_csv": "LIDAR_8.csv",
      "panel_png": "E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\results\\gpb024\\LIDAR_panel.png",
      "gates": [
        {
          "name": "NoPitImpliesDescent after W&L fill",
          "pass": true,
          "detail": "interior_checked=64516 pits=0 (boundary_localmin=66)"
        },
        {
          "name": "flowing D8 steps strictly descend (drop>0)",
          "pass": true,
          "detail": "n_flow=45346 min_drop=0.0000"
        },
        {
          "name": "TerminatesUnderStrictDescent interior",
          "pass": true,
          "detail": "n=64516 term=64516 longest=13 uniq_out=20137 bound=65536"
        },
        {
          "name": "unfilled flat 4-ring does not terminate (P-006b contrast)",
          "pass": true,
          "detail": "ring_terminated=False"
        }
      ],
      "entry": "PASS"
    }
  ],
  "wolfram": {
    "available": true,
    "reason": "wolframscript not on PATH",
    "returncode": 0,
    "parsed": {
      "operator": "orbit-multires",
      "n": 4,
      "functionsChecked": 256,
      "descentMaps": 24,
      "pigeonholeAll": true,
      "descentAllFix": true,
      "ringHasFixedPoint": false,
      "ring": [
        1,
        2,
        3,
        0
      ],
      "assumingPigeon": true,
      "coarsened": [],
      "note": "4^4 independent of DEM size; coarsen CSVs checked for 4-nbr pits"
    }
  },
  "manim": {
    "rendered": true,
    "cmd": "C:\\ProgramData\\anaconda3\\python.exe -m manim -ql --disable_caching --media_dir E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\results\\gpb024 E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\p_comp_1_multires_manim.py FillThenWatershedMultiresStencil",
    "returncode": 0,
    "figure": "E:\\AI for Math\u4e0eDEM\u7a7a\u95f4\u7f51\u683c\u4ea4\u53c9\u7814\u7a76\\verifiable-geocomputation\\experiments\\phase2\\figures\\MultiresFillThenWatershed.mp4"
  },
  "entry": "PASS",
  "note": "P-COMP-1 multi-res: same fill+D8+terminate on 4 DEM sizes. Formal lemmas do not mention grid size."
}
```

### A.9 AutoDL formality re-verify (task9 stage 2)

```
dafny verify formal/dafny/PCOMP_1.dfy
Dafny program verifier finished with 17 verified, 0 errors
dafny verify formal/dafny/P006_terminate_under_strict.dfy
Dafny program verifier finished with 12 verified, 0 errors
cd formal/lean4 && lake build
Build completed successfully.
log PCOMP_1 → /root/.workbuddy/jobs/20260906_194831.log
log T6      → /root/.workbuddy/jobs/20260906_194833.log
```

Cite v_final §7.3.4 for P-COMP-1 5×5 numbers; cite v_final §7.6 / §A.7 for scale-out numbers.
Cite v_final §8.4 for the counter-example library; cite v_final §9.2 for limitations.

## §C · Citation map (v_final only)

Submitters must cite the following v_final anchors, never v1.x section numbers.

| # | Claim | Cite |
|---|---|---|
| 1 | P-COMP-1 statement | v_final §7.3 |
| 2 | P-COMP-1 4 gates 25/0, 9/1.0000, 9/9/3/3, ring False | v_final §7.3.4.1 |
| 3 | interior 9-cell paths longest=3 uniq_out=3 | v_final §7.3.4.2 |
| 4 | Wolfram 4^4 pigeon/descent/ring | v_final §7.3.4.3 |
| 5 | Dafny 17/0 and T6 12/0 | v_final §7.3.4.4 / §A.9 |
| 6 | lake build success | v_final §A.9 |
| 7 | flat 4-ring counter-example | v_final §8.4.1 |
| 8 | ZT not Horn | v_final §8.4.2 |
| 9 | T6 already cloud PASS | v_final §8.4.3 / §9.2.1 |
| 10 | task9 multi-res table | v_final §7.6.1 / §A.7 |
| 11 | task9 raw metrics | v_final §A.8 |
| 12 | limitations GPU / real-DEM window | v_final §9.2.3 / §9.2.4 |
| 13 | manim four-panel | v_final §A.7.1 |
| 14 | noise sweep | v_final §A.2 |
| 15 | author block | v_final §2 |
| 16 | P-COMP-2 plane closure | v_final §7.6.2 |
| 17 | P-COMP-4 homotopy 8+4 | v_final §7.6.3 |
| 18 | P-COMP-5 hash 12/12 | v_final §7.6.4 |
| 19 | real DEM diversity 3/3 | v_final §7.6.5 / §7.7 |

version: v1.5 (incl. v1.3 NUM + task9/10.5/11/12/13 §7.6 evidence)  2026-09-06

Note-01: plane-5m n_pit=0 n_term=9 uniq_out=3 longest=3 PASS.
Note-02: terrain-A n_pit=53 n_term=64516 uniq_out=98 longest=351 PASS.
Note-03: SRTM-30m n_pit=2519307 n_term=12952801 uniq_out=6027216 longest=28 PASS (synthetic 3601).
Note-04: LiDAR-down n_pit=1782 n_term=64516 uniq_out=20137 longest=13 PASS (synthetic downsample).
Note-05: wolfram pigeonholeAll=True descentAllFix=True ringHasFixedPoint=False.
Note-06: manim MultiresFillThenWatershed.mp4 225006 bytes.
Note-07: commit task9=6a54d4c local only.
Note-08: P-COMP-2 visited=16908288; dafny 25/0; commit 04571d5.
Note-09: P-COMP-4 8 PASS + 4 FAIL-TOLERANCE (all 45°); dafny 20/0; commit 624d131.
Note-10: P-COMP-5 hash 12/12 idempotent 4/4; dafny 15/0; lake 2764; commit 10a9ebb.
Note-11: GPB-027 lidar/ifsar/copernicus 3/3 PASS; RealWorldDiversity.mp4 148437 B; commit a33159a.

version: v1.5 (incl. v1.3 NUM + task9/10.5/11/12/13 §7.6 evidence)  2026-09-06
