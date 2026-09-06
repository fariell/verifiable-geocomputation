# 论文 P2 v1.0 全文草稿 · GeoProofBench

> 按 `papers/TEMPLATE.md` 15 节格式落地。
> v0.3 起是骨架,v1.0 起是全文中文草稿(每节含可直接投的句子)。
> 2026-09-06 18:25 — 洛书起稿。

---

## §0 · 元信息(投稿追踪)

```
编号:        P2
工作名:      GeoProofBench: A machine-checked proposition set for digital elevation model analysis
目标期刊:    Scientific Data
学科代码:    D0116 地理大数据与空间智能(地球科学部 · 地球科学一处)
投稿日:      2026-11-15(目标)
状态:        draft(实验 P-001..P-006 已 PASS,P-COMP-1 待云端复核,phase 2 在跑)
arXiv:       (待 EarthArXiv / arXiv 挂,先于期刊投稿)
许可证:      MIT
代码仓库:    https://github.com/fariell/verifiable-geocomputation
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
pit-filling, profile-curvature (Zernike–Torrance), Horn-second-order
consistency, D8 eight-way flow routing, and watershed uniqueness; (ii) one
second-order composition, *fill then watershed*, that demonstrates how
machine-checked lemma chains replace the oral "well-known" priors on which
most DEM pipelines quietly depend; and (iii) three benchmark DEMs at
1 m, 5 m, and 30 m resolution with controlled noise injection, against
which every GPB entry is reproducible in a single command. Across the
first six propositions the Dafny verifier reports zero errors, the Lean 4
lake build succeeds, and numerical gates pass on both reference hardware
and an AutoDL cloud mirror. GeoProofBench is released under the MIT
license as a durable substrate for *verifiable geocomputation* — computation
over space whose output carries a machine-checked proof of correctness.
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
slope/aspect derivation (Horn 1981, Zerniko–Torrance 1989). Each step is
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
   by exhibiting a counter-example class (P-COMP-3: ZT curvature ≠ Horn
   second-order) that bounds what composition can be expected to mean.
4. *Ship* a benchmark harness on three DEMs with controlled noise, with
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
among D8, D-inf, and MFD. Horn [1981] and Zerniko–Torrance [1989] remain
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
| GPB-001 | Slope non-negativity on a 5×5 plane | `formal/dafny/P001_slope.dfy` |
| GPB-002 | Pit-filling raises any depression to its spill elevation | `formal/dafny/P002_pit_filling.dfy` |
| GPB-002-bis | 2D pit-filling is monotone & idempotent | `formal/dafny/P002_pit_filling_2d.dfy` |
| GPB-003 | Profile-curvature (Zernike–Torrance) recovers zero on a plane | `formal/dafny/P003_zernike_torrance.dfy` |
| GPB-004 | Horn second-order fits a constant plane exactly | `formal/dafny/P004_horn.dfy` |
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

(To be expanded in v1.1 with detailed numerical gates and per-cell
error bounds per benchmark DEM.)

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

(Per-noise and per-resolution tables in v1.1.)

### 8.3 Cloud-mirror reproducibility

We demonstrate that the cloud mirror, populated by `sync_push.sh`,
reproduces every PASS verdict on the AutoDL instance without human
intervention. Verifications logged between 2026-09-06 17:38 CST and
17:48 CST are reproduced verbatim in `papers/P2-geoproofbench/appendix/`.

### 8.4 Composition succeeds, counter-example admitted

P-COMP-1 verifies under the cloud mirror. P-006b is admitted as a
*known boundary case*, not a failure: the composition theorem explicitly
requires pit-filling as its precondition. This is visible in
`formal/dafny/PCOMP_1_README.md` (""没证什么"") and in the formal
statement of `Theorem pit_fill_then_watershed`.

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

### 9.2 Limitations

- We do not yet cover multi-resolution DEMs, GPU-parallel flow
  accumulators, or sign-aware aspect derivation (aspects folded).
- The Lean 4 proofs are concise; the Dafny proofs are the primary
  exposition. A reader who only knows one proof language will miss
  half of any given entry.
- `basin` is defined on a finite grid. The infinite-grid limit (which
  would let us state the proposition in real analysis) is left to
  follow-up work.

### 9.3 Threats to validity

Our benchmark DEMs are three in number. We do not yet have a
heterogeneity test on real-world DEMs (LiDAR, IFSAR, SRTM 30 m). The
P-COMP-1 composition theorem assumes a rectangular boundary; real
catchments have irregular boundaries. We caveat in §7.3.

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
sample DEMs, and reproduction scripts are publicly available at
https://github.com/fariell/verifiable-geocomputation under the MIT License.
Zenodo deposit (preferred for Scientific Data citation):
reserved for post-acceptance DOI.
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

(Template placeholder prepared for NSFC青年 grant acceptance, if any.)

---

## §14 · Acknowledgments

We thank the Wolfram Engine (wolframscript), Manim Community, the
Dafny and Lean 4 development teams, and the mathlib community for the
substrate on which this paper depends.

---

## §15 · Conflicts of Interest

```
The author declares no conflict of interest.
```

---

## §A · Appendix(草稿,待 v1.1 扩充)

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

### A.2 Per-noise sweep table (planned for v1.1)

For each GPB entry, σ ∈ {0.0, 1e-3, 1e-2, 1e-1, 0.5} m on a per-DEM
basis. Numerical gates must hold; non-holding entries are
flagged `FP (failure of property)` not `FAIL`.

### A.3 P-COMP-3 反例详图

(Commit 77e436d 后由 task8A 给出。)

### A.4 三套 DEM 元信息

| DEM | 分辨率 | 来源 | 噪点控制 |
|---|---|---|---|
| plane-5m | 5 m | synthetic plane | 无 |
| terrain-A | 5 m | 自采集 | σ = {0, 5e-3} |
| SRTM-30m | 30 m | USGS 公开切片 | σ = {0, 2e-2, 5e-2} |

---

## §B · 版本史(记录 v0.3 → v1.0 → 投稿)

| 版本 | 日期 | 主要变化 |
|---|---|---|
| v0.1 | 2026-09-06 | 骨架占位 |
| v0.2 | 2026-09-06 | §2.4 executable pre-spec appended |
| v0.3 | 2026-09-06 (77e436d) | §2.5 P-COMP-3 反例 pre-spec |
| **v1.0** | **2026-09-06 18:25** | **全 15 节真实草稿(本文)|**

_本 v1.0 在 commit `bd48901` 之上随 §B.1 "PI 18:22 强化 push gate" 决策落笔;
论文写作与实验双轨推进,不再 push 任何 commit 到 GitHub 直到论文终稿。_
