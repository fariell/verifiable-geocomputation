# Verifiable Formal Specifications as an Underserved Autoformalization Target: An LLM Evaluation on Machine-Checkable Terrain Algorithms

> Draft for *Knowledge-Based Systems* (Elsevier). Internal tracking id: task16 / P3.  
> Geography enters only as a **testbed** for a class of specifications that existing autoformalization benchmarks systematically omit.

---

## 0. Metadata (submission tracking)

```
编号:        P3
工作名:      LLM autoformalization of verifiable formal specifications (GeoProofBench L1)
内部代号:    task16
目标期刊:    Knowledge-Based Systems (Elsevier)
投稿窗口:    arXiv mid-Oct 2026 → KBS Nov 2026
状态:        draft (W4/WRITING-S1)
KBS 格式核验 (Guide for Authors, ScienceDirect, 2026-09-12):
  - Article type: original research (preferably ≤ 20 double-line-spaced pages incl. tables/figures)
  - Abstract ≤ 250 words; Keywords 1–7; Highlights 3–5 bullets ≤ 85 chars each
  - Editable source (.docx or .tex / elsarticle); Highlights as separate file
  - Required: CRediT, competing interests, funding, generative-AI declaration, data statement
  - No hard word cap; target body ~12–16 pages excl. references/appendix (INBOX A.15.3)
arXiv:       (pending)
数据快照:    2026-09-12 ~12:59 CST · experiments/p2_llm/results/raw/l1_full_w3_live.jsonl
             口径: Dafny track only · deduplicated-per-cell (last-wins)
```

---

## 1. Title

**Verifiable Formal Specifications as an Underserved Autoformalization Target: An LLM Evaluation on Machine-Checkable Terrain Algorithms**

---

## 2. Authors and affiliations

```
Yinggang Guo ¹,*

¹ Northwest Institute of Nuclear Technology, Xi'an 710024, China;
  fariel_gyg@163.com

* Correspondence: fariel_gyg@163.com
  ORCID: https://orcid.org/0000-0002-8207-9941
```

(Canonical block from [`AUTHOR.md`](../../AUTHOR.md).)

---

## 3. Highlights

*(KBS requires a separate editable highlights file at submission; draft bullets ≤ 85 characters.)*

- Verifiable formal specs are an underserved autoformalization target.
- We evaluate LLMs with compile@1 and verify@1, analogous to pass@k.
- Semantic fidelity (verified ≠ correct proposition) is the headline metric.
- On Dafny L1, verify@1 ranges from 0% (32B) to ~20% (R1).
- Lean cells are generated but not scored as failures (verifier undeployed).

---

## 4. Abstract

Large language models (LLMs) are increasingly evaluated on autoformalization into interactive theorem provers, yet most benchmarks reward *mathematical* correctness of pure statements rather than *machine-checkable, executable* formal specifications of algorithms. We argue that **verifiable formal specifications**—artifacts that must both state a proposition and survive an automated verifier—are a systematically underserved target class. Using digital elevation model (DEM) terrain-analysis algorithms as a sampling domain (not as the primary scientific claim), we instantiate this class with single-operator lemmas from a previously released GeoProofBench suite and evaluate four open-weight LLMs under a fixed harness (temperature 0, *k*=5, three prompt regimes). On the **Dafny track** (deduplicated per cell, last-wins; snapshot 2026-09-12), verify@1 ranges from **19.7%** (DeepSeek-R1; 24/122 RAN cells) and **13.4%** (DeepSeek-V3.2; 18/134) down to **0.0%** for Qwen2.5-72B-Instruct and GLM-4-32B-0414 on cells with a real toolchain result. We treat **semantic fidelity**—whether a verified artifact still states the intended proposition—as the headline metric and reserve a dedicated analysis for *verified but drifted* cases; quantitative fidelity rates are withheld until human adjudication of ambiguous verifier-passed records completes. Lean-target cells are reported separately as *generated but unverified* (target verifier undeployed), never as 0% pass. The results position verify@* as a pass@* analogue for formalization and motivate fidelity-aware evaluation for any code-or-proof generation setting where test/verifier passage can be gamed.

**Word count:** ~230 (≤ 250).

---

## 5. Keywords

autoformalization; large language models; formal verification; semantic fidelity; specification gaming; pass@k; Dafny

---

## 6. Introduction

Autoformalization—translating informal mathematical content into a proof assistant—has become a central probe of LLM reasoning. Benchmarks such as miniF2F and ProofNet measure whether models can produce proofs that a kernel accepts. Parallel work on code generation (HumanEval, MBPP) measures whether models can produce programs that pass unit tests, typically summarized with pass@*k*.

These lines share a blind spot. Many industrially and scientifically important artifacts are neither pure mathematical olympiad statements nor unit-tested scripts: they are **verifiable formal specifications** of algorithms—contracts (`requires` / `ensures`, invariants, termination metrics) that must (i) express the intended property and (ii) be discharged by an automated verifier (SMT-backed or kernel-backed). Passing the verifier is necessary but not sufficient: a model can strengthen premises, weaken conclusions, or prove a *different* lemma that still type-checks. That failure mode is an instance of **specification gaming / reward hacking**, now well documented in RL and code evaluation, but rarely operationalized as a first-class metric in autoformalization suites.

We study this gap directly. The scientific claim is about **AI evaluation methodology**: verifiable formal specifications constitute a specification morphology that existing autoformalization benchmarks undersample. We use DEM terrain operators (slope, pit filling, curvature, flow routing, watershed termination) only as a **testbed**—a domain that naturally forces grid adjacency, floating-point tolerance, topological invariants, and termination metrics. The geographic algorithms are not marketed as the contribution; they instantiate hard cases of the specification class.

**Contributions.**

1. **Frame** verifiable formal specifications as an underserved autoformalization target and situate verify@1 / verify@3 as the formalization-side analogues of pass@*k*.
2. **Release-aligned evaluation protocol** on GeoProofBench L1 tasks with withheld gold formalizations, dual `target:` tracks (Dafny / Lean), and three prompt regimes (zero-shot, few-shot, iterative repair).
3. **Measured L1 Dafny results** for four SiliconFlow-hosted open models, reporting compile@1 and verify@1 under an honest toolchain rule (`TOOLCHAIN_MISSING` is never a pass).
4. **Semantic fidelity as headline metric**, with *verified but drifted* reserved for a dedicated section; no fidelity percentage is claimed before human verdicts on ambiguous cases.
5. **Failure taxonomy** F1–F8 plus a method-class for **automatic fidelity-judge failure**, separating model drift from evaluator incapacity.

---

## 7. Related Work

### 7.1 LLM autoformalization and proof assistants

LLM-assisted formalization into Lean, Coq, Isabelle, and related systems has been evaluated primarily on competition mathematics and textbook lemmas (miniF2F, ProofNet, and follow-ons). Parallel efforts study LLM-aided Dafny verification and repair of failing proofs. These benchmarks emphasize *kernel acceptance* of mathematical statements. They rarely require the model to emit a full algorithmic contract that must both compile and verify against an SMT or verifier backend while remaining faithful to an informal operator specification. Our setting inherits the autoformalization goal but changes the **specification morphology**: executable/verifiable contracts rather than olympiad theorems alone.

### 7.2 Code-generation benchmarks and pass@*k*

HumanEval, MBPP, and related suites popularized pass@*k*: the probability that at least one of *k* samples passes hidden tests. Our **compile@1** and **verify@1** (and, when repair is complete, **verify@3**) are deliberately positioned as the same methodological family applied to formal artifacts: “does the sample survive the toolchain gate?” Mapping the analogy explicitly matters for KBS readers who know code LLMs better than proof assistants—verify@* is not a bespoke GIS metric; it is pass@* on a verifier oracle.

### 7.3 Specification gaming, reward hacking, and test-passed-but-wrong

A large literature shows agents optimizing proxy rewards while violating the intended objective (reward hacking), and code models that pass tests while implementing the wrong behavior. Autoformalization inherits the same risk: **verifier passage is a proxy**. **Semantic fidelity**—agreement between the generated contract and the gold proposition—is our operationalization of that concern. We require a separate accounting of *verified but drifted* samples; treating verify@1 alone would reintroduce the proxy gap that fidelity is meant to close.

### 7.4 Prior GeoProofBench data release (third person)

Guo et al. released a machine-checkable terrain-algorithm proposition suite (GeoProofBench) with Dafny and Lean formalizations and reference implementations (ScienceDB DOI [10.57760/sciencedb.011r9](https://doi.org/10.57760/sciencedb.011r9)). The present paper does **not** claim that dataset as a new GIS product; it **uses** those gold specifications as a withheld baseline for LLM evaluation.

---

## 8. Benchmark design

### 8.1 Task definition

Each task YAML supplies:

- **Inputs to the model:** `natural_spec` (informal proposition) and a path to a `reference_impl` (behavior cue).
- **Hidden baseline:** `gold_formal` (already verified Dafny or Lean); never shown to the model.
- **Target language:** `target: dafny | lean`.
- **Expected verdict:** `PASS` (prove the property) or `NEG` (construct a counterexample / negative result).

W1 delivered 22 tasks (L1=14, L2=5, L3=3). This manuscript’s main table uses the **L1 subset** under active live evaluation.

### 8.2 Dual-track `target:` design

L1 splits naturally into two verifier tracks:

| Track | L1 tasks | Planned cells (4 models × 3 prompts × *k*=5) | Artifact | Verifier |
|------:|---------:|---------------------------------------------:|----------|----------|
| Dafny | 9 | 540 | `.dfy` | Dafny 4.11 (WSL) — **main table** |
| Lean  | 5 | 300 | `.lean` | lake/Lean — **not deployed on the evaluation host** |

**Methodological rule:** statistics that mix tracks without filtering on `target:` misread Lean absence as Dafny failure. All primary rates below are **Dafny-track only**. Lean cells that were generated successfully but lack a verifier are tabulated as *undeployed toolchain*, not as verify@1 = 0.

### 8.3 Difficulty layers (full suite)

| Layer | Content | Role |
|-------|---------|------|
| L1 | Single-operator lemmas (P-001…P-006 families) | Capability floor |
| L2 | Compositional propositions | Premise threading |
| L3 | Negative results / counterexamples | Anti-whitewash stress test |

S1 reports L1 Dafny measurements; L2/L3 remain for a later experimental stage.

### 8.4 Prompt regimes

| Id | Regime | Content |
|----|--------|---------|
| P0 | Zero-shot | `natural_spec` + output constraints |
| P1 | Few-shot | + one **non-homologous** verified example (no gold leak) |
| P2 | Iterative repair | Verifier stderr fed back, ≤ 3 rounds |

---

## 9. Experimental setup

### 9.1 Models and protocol

Four open-weight models hosted via SiliconFlow (OpenAI-compatible API), fixed temperature 0, *k*=5 samples per (model × task × prompt):

| Slot | Model string (API) | Role |
|------|--------------------|------|
| M1 | `deepseek-ai/DeepSeek-V3.2` | Strong general open model |
| M2 | `Qwen/Qwen2.5-72B-Instruct` | Cross-family large instruct |
| M3 | `THUDM/GLM-4-32B-0414` | Mid-scale (32B) |
| M4 | `deepseek-ai/DeepSeek-R1` | Reasoning / long chain-of-thought |

### 9.2 Harness and tooling

- Generation: `experiments/p2_llm/harness/run_l1_batch.py` / `run_l1_batch_pool.py` (resume-safe, append-only JSONL).
- Verification: Dafny 4.11.0 under WSL2 (`/usr/local/bin/dafny`); Windows host has no native `dafny`.
- Scoring: `score_semantic.py` assigns semantic labels; ambiguous verifier-passed cases become `VERIFIED_NEEDS_HUMAN` for PI adjudication.
- Raw outputs: `experiments/p2_llm/results/raw/`; ledger: `l1_full_w3_live.jsonl`.

### 9.3 Metric definitions

| Metric | Definition |
|--------|------------|
| compile@1 | Fraction of RAN cells with `compile_rc = 0` |
| verify@1 | Fraction of RAN cells with `verify_rc = 0` |
| verify@3 | verify after ≤ 3 repair rounds (reported when P2 repair campaign completes) |
| repair gain | verify@3 − verify@1 |
| semantic fidelity | Among verifier-passed cells, fraction faithful to gold (**headline**; % deferred) |

**RAN cell:** a deduplicated (model, task_id, prompt_id, sample_index) cell whose last-wins record has a non-null `compile_rc` (real toolchain evaluation).  
**Honesty:** `verify_status = TOOLCHAIN_MISSING` is never counted as success. Rates always state whether they are **deduplicated-per-cell (last-wins)** or **all-attempts**.

### 9.4 Snapshot provenance

Unless noted, every rate in §10 is computed from `l1_full_w3_live.jsonl` at **2026-09-12 ~12:59 CST**, filtering to the nine L1 Dafny task ids, last-wins deduplication. Live L1 generation may still append rows; later drafts will refresh the table from the same scripted definition (`_autorun/_w4_dafny_metrics.py`).

---

## 10. Main results (Dafny track)

### 10.1 Primary table (deduplicated-per-cell, last-wins)

**Table 1.** L1 Dafny-track compile@1 and verify@1. Denominator = RAN cells (`compile_rc` ≠ null). Snapshot 2026-09-12 ~12:59 CST.

| Model | Unique cells | RAN | compile@1 | verify@1 |
|-------|-------------:|----:|----------:|---------:|
| DeepSeek-R1 | 135 | 122 | **26.2%** (32/122) | **19.7%** (24/122) |
| DeepSeek-V3.2 | 135 | 134 | 17.9% (24/134) | 13.4% (18/134) |
| Qwen2.5-72B-Instruct | 135 | 132 | 0.8% (1/132) | 0.0% (0/132) |
| GLM-4-32B-0414 | 125 | 125 | 0.0% (0/125) | 0.0% (0/125) |

**Reading.** Reasoning-oriented R1 leads both compile and verify. V3.2 forms a middle band. Qwen-72B and GLM-32B essentially fail to produce verifying Dafny on this suite under the measured protocol; GLM’s 0/125 compile@1 is a **valid negative** with (near-)full L1 Dafny coverage (125/135 cells; 10 cells still outstanding at snapshot time), not an artifact of testing only easy tasks.

Aggregate Dafny unique cells at snapshot: 530 planned-scale partial; RAN total 513 across four models. Planned Dafny grid is 540 cells (9×4×3×5); remaining gaps are incomplete R1/GLM generation, not silent drops.

### 10.2 Lean track (limitation table — not a failure rate)

**Table 2.** L1 Lean track at the same snapshot (deduplicated-per-cell).

| Quantity | Value |
|----------|------:|
| Unique Lean cells | 298 |
| Status GENERATED or SKIP_EXISTING | 278 |
| `verify_status = TOOLCHAIN_MISSING` | 278 |

Artifacts exist on disk as `.lean` files. The evaluation host did not deploy `lake` / Lean, so these cells were **not machine-checked**. We **do not** report verify@1 = 0% for Lean. Undeployed verification ≠ verification failure.

### 10.3 Semantic labels (counts only; no fidelity %)

Among Dafny-track last-wins cells, automatic semantic labels include (counts, not rates):

| Label | Count (Dafny last-wins) |
|-------|------------------------:|
| `UNCOMPILED` | 331 |
| `LIKELY_ALIGNED` | 4 |
| `VERIFIED_NEEDS_HUMAN` | 10 |
| `COMPILE_ONLY` | 7 |
| `VERIFIED_BUT_DRIFT_SUSPECT` | 1 |
| (unset / other) | remainder |

**No semantic fidelity percentage is reported in this draft.** Ten `VERIFIED_NEEDS_HUMAN` records await PI adjudication (`_autorun/needs_human_review.md`, regenerated 2026-09-12 04:59 UTC, *N*=10). Until that verdict, abstract/conclusion mention fidelity only as a *metric definition*, not as a measured rate.

### 10.4 <<placeholder: Semantic fidelity section>>

```
<<placeholder: pending PI verdict on 10 VERIFIED_NEEDS_HUMAN records>>
Path: _autorun/needs_human_review.md
Rule (INBOX A.17.11 / A.18.4): no semantic fidelity percentage before PI ruling.
This section will report:
  - faithful vs verified-but-drifted among verifier-passed cells
  - a dedicated table for drifted cases
  - inter-rater note vs automatic judge after normalization (A.17.16)
```

---

## 11. Failure taxonomy

We retain the pre-registered F1–F8 codes and add an evaluator-side class required by measurement practice.

| Code | Class | Typical trigger in this testbed |
|------|-------|----------------------------------|
| F1 | Syntax / parse error | Ill-formed Dafny/Lean |
| F2 | Type / signature error | `real` vs `int`, grid arity |
| F3 | Missing or weakened precondition | Dropped `w > 0`, dropped pit-free assumption |
| F4 | Missing loop invariant | Fill scans, inductive `stepN` |
| F5 | Missing termination metric | No `decreases` / well-founded measure |
| F6 | Floating-point / numeric mismatch | Treating ε-tolerance as identity; wrong big-O |
| **F7** | **Semantic drift** | Verifies but proves the wrong proposition |
| F8 | Over-strengthened premise | Theorem only on constant DEMs |
| **F-J** | **Fidelity-judge failure** | Automatic scorer cannot decide ALIGNED vs DRIFT (e.g., multi-line specs, trailing comments); *not* a model error |

**F-J** (method class from INBOX A.17.16) must not be collapsed into F7. Confusing “our judge cannot parse the proof” with “the model drifted” is itself a validity threat. Empirically, several `VERIFIED_NEEDS_HUMAN` cases may later resolve to ALIGNED after specification normalization; that resolution updates F-J rates, not necessarily F7.

Qualitative pattern at snapshot (description only): mid-scale GLM produces near-total F1/F2 under Dafny; R1 accounts for almost all verifier passes and therefore almost all fidelity adjudication load.

---

## 12. Threats to validity

**Internal.** Gold formalizations may appear in pretraining corpora; we mitigate with API-isolated sessions, withheld gold in prompts, and few-shot examples from non-homologous families. Temperature 0 does not guarantee determinism across providers; we log model strings and dates and keep *k*=5.

**External.** Tasks are a laboratory subset of terrain operators, not all GIS algorithms. Only Dafny 4.11 is scored in the main table; Lean results are undeployed. Provider outages and balance limits truncate some R1 cells (RAN 122/135 at snapshot).

**Construct.** verify@* ≠ engineer usability. Semantic fidelity needs human adjudication; automatic labels are provisional. `TOOLCHAIN_MISSING` must not be narrated as model incompetence.

**Conclusion.** Multiple comparisons across models × prompts × tasks inflate Type I risk; we treat Table 1 as descriptive primary evidence and defer confirmatory tests to the full L1+L2+L3 freeze.

---

## 13. Discussion

### 13.1 So what for AI systems?

The practical message for knowledge-based and neurosymbolic systems is: **oracle passage is not task success** when the oracle checks a *formal artifact* rather than the *intended proposition*. Any pipeline that uses compilers, solvers, or verifiers as rewards needs an explicit fidelity layer—or it will overestimate capability exactly where models are most fluent at gaming the proxy.

### 13.2 Why a terrain testbed helps

Grid traversal, ε-comparisons, topological uniqueness, and termination metrics stress F3–F6 in ways that pure algebraic lemmas under-sample. That is a sampling argument, not a claim that the paper’s novelty is geographic.

### 13.3 Capability cliff

Table 1 shows a sharp cliff between reasoning-oriented / large DeepSeek models and Qwen-72B / GLM-32B on Dafny verify@1. The 32B zero-compile outcome, under broad task coverage, is evidence of a **capability threshold** for this specification class under zero-/few-shot prompting—not a claim that fine-tuning could not move the threshold.

---

## 14. Conclusion

We reframed autoformalization evaluation around **verifiable formal specifications** and measured four LLMs on a Dafny L1 slice of a machine-checkable terrain-algorithm suite used strictly as a testbed. Under deduplicated-per-cell scoring, verify@1 reaches at most **19.7%** (DeepSeek-R1) and collapses to **0%** for Qwen2.5-72B-Instruct and GLM-4-32B-0414 on RAN cells. **Semantic fidelity**—whether verifier passage still means the original proposition—is designated the headline metric; measured fidelity rates remain blocked on human verdicts for ten ambiguous records. Lean generations are disclosed as unverified due to undeployed tooling, not scored as failures. Together, the results argue that fidelity-aware verify@* reporting should become standard whenever LLMs emit machine-checkable artifacts.

---

## 15. Data / Code availability

Task YAMLs, prompts, harness, and raw model outputs for the L1 campaign live in the project repository under `experiments/p2_llm/`. Gold formalizations and the GeoProofBench proposition set are available via ScienceDB DOI [10.57760/sciencedb.011r9](https://doi.org/10.57760/sciencedb.011r9) and the companion code repository (MIT License). Snapshot ledger: `experiments/p2_llm/results/raw/l1_full_w3_live.jsonl`.

---

## 16. CRediT author contributions

Conceptualization, Y.G.; methodology, Y.G.; software, Y.G.; validation, Y.G.; formal analysis, Y.G.; investigation, Y.G.; data curation, Y.G.; writing—original draft, Y.G.; writing—review and editing, Y.G.; visualization, Y.G.; supervision, Y.G.; project administration, Y.G.

---

## 17. Declaration of generative AI use

Large language model APIs (DeepSeek-V3.2, DeepSeek-R1, Qwen2.5-72B-Instruct, GLM-4-32B-0414 via SiliconFlow) were the **objects of study** (experiment subjects), not ghostwriters of results. Interactive coding agents assisted with harness implementation, batch orchestration, and manuscript drafting. The author reviewed all scientific claims, tables, and limitations and accepts full responsibility for the content. No API key or credential appears in the manuscript or committed artifacts.

---

## 18. Funding

This research received no external funding.

---

## 19. Acknowledgments

Removed for review / to be completed at camera-ready.

---

## 20. Conflicts of interest

The author declares no conflict of interest.

---

## 21. References

*(Draft stubs — expand to full KBS numeric style before submission.)*

1. Cobbe et al. Training Verifiers to Solve Math Word Problems. arXiv:2110.14168, 2021.  
2. Chen et al. Evaluating Large Language Models Trained on Code. arXiv:2107.03374, 2021. (HumanEval / pass@k)  
3. Austin et al. Program Synthesis with Large Language Models. arXiv:2108.07732, 2021. (MBPP)  
4. Zheng et al. miniF2F: a cross-system benchmark for formal Olympiad-level mathematics. arXiv:2109.00110, 2021.  
5. Azerbayev et al. ProofNet: Autoformalizing and Formally Proving Undergraduate-Level Mathematics. arXiv:2302.12433, 2023.  
6. Skalse et al. Defining and Characterizing Reward Hacking. NeurIPS, 2022.  
7. Pan et al. Do the Rewards Justify the Means? Measuring Jailbreak vs Refusal Reward Hacking. ICML, 2024.  
8. Microsoft Research. Dafny: A Language and Program Verifier for Functional Correctness.  
9. Moura & Ullrich. The Lean 4 Theorem Prover and Programming Language. CADE, 2021.  
10. Guo et al. GeoProofBench data release. ScienceDB. DOI: 10.57760/sciencedb.011r9.

---

## Appendix A · Task id index (L1 used in Table 1)

**Dafny L1 (9):** GPB-001-flat, GPB-002-planar, GPB-007-hessian, GPB-010-pit, GPB-015-basin, GPB-019-quad, GPB-P002-idem, GPB-P002-mono, GPB-P002bis-raise.

**Lean L1 (5):** GPB-001-nonneg-lean, GPB-005-lap-lean, GPB-011-plane-lean, GPB-P002-nd-lean, GPB-T6-terminate-lean.

---

## Appendix B · Writing discipline / version sign

```
version: W4/WRITING-S1 draft
date: 2026-09-12
framing: KBS / A.15.2 (geography = testbed; semantic fidelity = headline; three Related Work lines)
numbers: measured Dafny-track last-wins from l1_full_w3_live.jsonl @ ~12:59 CST
fidelity %: intentionally absent (pending PI on 10× VERIFIED_NEEDS_HUMAN)
P2 manuscript: untouched (FORM LOCK / already submitted)
```
