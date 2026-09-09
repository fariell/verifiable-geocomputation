from pathlib import Path
import textwrap

out = Path("experiments/p2_llm/tasks")
out.mkdir(parents=True, exist_ok=True)

tasks = [
  dict(id="GPB-001-flat", difficulty="L1", target="dafny", prop_family="P-001", expected_verdict="PASS",
       reference_impl="experiments/phase1/gpb019_consistency.py",
       gold_formal="formal/dafny/P001_horn_slope.dfy",
       lemma_hint="FlatSlopeZero",
       natural_spec="On any 3x3 elevation window with finite values, if all nine cells share the same elevation, the Horn (1981) slope magnitude (equivalently its square SlopeSq) is identically zero. Grid spacing w must be positive."),
  dict(id="GPB-001-nonneg-lean", difficulty="L1", target="lean", prop_family="P-001", expected_verdict="PASS",
       reference_impl="experiments/phase1/gpb019_consistency.py",
       gold_formal="formal/lean4/VeriGIS/HornSlope.lean",
       lemma_hint="slope_sq_nonneg",
       natural_spec="For any finite 3x3 elevation window and positive grid spacing w, the Horn slope-square SlopeSq is nonnegative. This must hold for arbitrary elevations, not only planar surfaces."),
  dict(id="GPB-002-planar", difficulty="L1", target="dafny", prop_family="P-001", expected_verdict="PASS",
       reference_impl="experiments/phase1/gpb019_consistency.py",
       gold_formal="formal/dafny/P001_horn_slope.dfy",
       lemma_hint="PlanarExact",
       natural_spec="On a planar surface z = A*x + B*y + C sampled on a regular grid with spacing w>0, the Horn finite-difference estimates DzDx and DzDy recover A and B exactly (identity, not merely asymptotically)."),
  dict(id="GPB-P002-mono", difficulty="L1", target="dafny", prop_family="P-002", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_1.py",
       gold_formal="formal/dafny/P002_pit_filling.dfy",
       lemma_hint="Monotone / FillCorrect",
       notes="Historical seed IDs GPB-021/022/023 for fill; disambiguated as GPB-P002-*.",
       natural_spec="Consider the 1D Wang-Liu pit-filling specialization Fill with left outlet: Fill[0]=orig[0], Fill[i]=max(orig[i], Fill[i-1]). Each raise is monotone: no cell elevation decreases. After a full scan the profile is nondecreasing."),
  dict(id="GPB-P002-nd-lean", difficulty="L1", target="lean", prop_family="P-002", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_1.py",
       gold_formal="formal/lean4/VeriGIS/PitFilling.lean",
       lemma_hint="fill_nondecreasing",
       natural_spec="Formalize in Lean that the 1D left-outlet Fill operator yields a nondecreasing sequence: for all i, Fill(a)[i] <= Fill(a)[i+1] when defined."),
  dict(id="GPB-P002-idem", difficulty="L1", target="dafny", prop_family="P-002", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_5.py",
       gold_formal="formal/dafny/P002_pit_filling.dfy",
       lemma_hint="FillIdempotent",
       natural_spec="Pit filling is idempotent on the 1D left-outlet specialization: Fill(Fill(a)) = Fill(a). Cells that already do not spill to the left are fixed points of Raise."),
  dict(id="GPB-P002bis-raise", difficulty="L1", target="dafny", prop_family="P-002-bis", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_1.py",
       gold_formal="formal/dafny/P002_pit_filling_2d.dfy",
       lemma_hint="RaiseNbrMonotone",
       natural_spec="In the 2D local raise step RaiseNbr, raising a 4-neighbor from an already-processed cell never decreases any cell elevation, and the neighbor is lifted at least to max(original neighbor, processed cell fill)."),
  dict(id="GPB-007-hessian", difficulty="L1", target="dafny", prop_family="P-003", expected_verdict="PASS",
       reference_impl="experiments/phase1/p003_curvature.py",
       gold_formal="formal/dafny/P003_curvature.dfy",
       lemma_hint="QuadraticExact",
       natural_spec="On a quadratic surface z = A x^2 + B y^2 + C xy + Dx + Ey + F sampled on a 3x3 window with spacing w>0, the Zevenbergen-Thorne discrete Hessian recovers (2A, 2B, C) exactly."),
  dict(id="GPB-005-lap-lean", difficulty="L1", target="lean", prop_family="P-003", expected_verdict="PASS",
       reference_impl="experiments/phase1/p003_curvature.py",
       gold_formal="formal/lean4/VeriGIS/Curvature.lean",
       lemma_hint="laplacian_at_discrete_max",
       natural_spec="If the center cell of a 3x3 window is a discrete local maximum (center elevation >= each of the four orthogonal neighbors), then the discrete Laplacian at the center is <= 0."),
  dict(id="GPB-019-quad", difficulty="L1", target="dafny", prop_family="P-004", expected_verdict="PASS",
       reference_impl="experiments/phase1/p004_consistency.py",
       gold_formal="formal/dafny/P004_consistency.dfy",
       lemma_hint="QuadraticExact",
       natural_spec="Horn slope is exact on quadratic surfaces: DzDx and DzDy recover the true planar gradient coefficients (A,B) identically. Separately, on z = G x^3 the DzDx remainder at the origin equals G w^2 (order O(w^2))."),
  dict(id="GPB-010-pit", difficulty="L1", target="dafny", prop_family="P-005", expected_verdict="PASS",
       reference_impl="experiments/phase1/p005_d8.py",
       gold_formal="formal/dafny/P005_d8.dfy",
       lemma_hint="PitNoFlow",
       natural_spec="Under D8 steepest-descent routing, if none of the eight neighbors is strictly lower than the center, the flow direction is NoFlow (undefined / pit)."),
  dict(id="GPB-011-plane-lean", difficulty="L1", target="lean", prop_family="P-005", expected_verdict="PASS",
       reference_impl="experiments/phase1/p005_d8.py",
       gold_formal="formal/lean4/VeriGIS/D8.lean",
       lemma_hint="plane_constant",
       natural_spec="On a planar DEM z = A x + B y + C with positive slope, D8 flow direction is constant across interior cells that share the same (A,B,w); translating the elevation datum C does not change the direction."),
  dict(id="GPB-015-basin", difficulty="L1", target="dafny", prop_family="P-006", expected_verdict="PASS",
       reference_impl="experiments/phase1/p006_watershed.py",
       gold_formal="formal/dafny/P006_watershed.dfy",
       lemma_hint="BasinUnique",
       natural_spec="Layer A watershed uniqueness: if a deterministic successor function reaches an outlet (fixed point) from the same start cell in any two finite step counts, those outlets are equal. Formalize via bounded iterate stepN without searching for fixed points by SMT recursion."),
  dict(id="GPB-T6-terminate-lean", difficulty="L1", target="lean", prop_family="P-006", expected_verdict="PASS",
       reference_impl="experiments/phase1/p006_watershed.py",
       gold_formal="formal/lean4/VeriGIS/P006Terminate.lean",
       lemma_hint="terminates_under_strict_descent",
       natural_spec="Under a strict descent successor on a finite cell set, every orbit terminates at a fixed point; give a well-founded / decreases-style argument (Nat measure)."),
  dict(id="GPB-021-pcomp1", difficulty="L2", target="dafny", prop_family="P-COMP-1", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_1.py",
       gold_formal="formal/dafny/PCOMP_1.dfy",
       lemma_hint="FillThenWatershed / NoPitImpliesDescent",
       notes="Phase2 GPB-021 composition id; not P-002 seed GPB-021.",
       natural_spec="Composition P-COMP-1: after pit filling (P-002), D8 routing yields unique basin outlets (reuse P-006 BasinUnique). Prove the bridge lemmas: filled DEM has a non-ascent neighbor relation; under strict descent orbits are length-bounded; do not re-copy Fill/D8 kernels—include existing modules."),
  dict(id="GPB-022-pcomp2-lean", difficulty="L2", target="lean", prop_family="P-COMP-2", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_2.py",
       gold_formal="formal/lean4/VeriGIS/Composition/PitFillingThenWatershedPlane.lean",
       lemma_hint="plane_closure",
       natural_spec="P-COMP-2 full-plane closure: on a constant (zero-relief) plane and on a plane with tiny row-wise epsilon noise, fill-then-watershed still terminates with unique outlets. The formal statement should be size-parameterized (not hard-coding one grid dimension in the theorem statement)."),
  dict(id="GPB-025-pcomp4", difficulty="L2", target="dafny", prop_family="P-COMP-4", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_4.py",
       gold_formal="formal/dafny/PCOMP_4_homotopy.dfy",
       lemma_hint="HomotopyPlanarDx / Resample R_alpha",
       natural_spec="P-COMP-4 resampling homotopy: define R_alpha(w)=alpha*w with alpha>0,w>0. On planar/quadratic samples, Horn DzDx/DzDy and axis-aligned D8 direction are invariant in the appropriate sense under positive rescaling of grid spacing. Do not claim 45-degree rotation invariance in this task."),
  dict(id="GPB-026-pcomp5", difficulty="L2", target="dafny", prop_family="P-COMP-5", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_5.py",
       gold_formal="formal/dafny/PCOMP_5_idempotent.dfy",
       lemma_hint="FillIdempotent metaproperty",
       natural_spec="P-COMP-5 metaproperty: Fill is idempotent (Fill(Fill(a))=Fill(a)) and schedule/order variants that implement the same 1D left-outlet scan agree on outputs for the recorded hash instances. Prefer importing P-002 rather than redefining Fill."),
  dict(id="GPB-021-pcomp1-lean", difficulty="L2", target="lean", prop_family="P-COMP-1", expected_verdict="PASS",
       reference_impl="experiments/phase2/p_comp_1.py",
       gold_formal="formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean",
       lemma_hint="pit_fill_then_watershed",
       natural_spec="Lean restatement of P-COMP-1: for a DEM h and cell c, the basin outlet after pitFill2D is unique. Import VeriGIS.PitFilling2D / D8 / Watershed; do not translate Dafny proof text verbatim as untyped comments."),
  dict(id="GPB-023-pcomp3-neg", difficulty="L3", target="dafny", prop_family="P-COMP-3", expected_verdict="NEG",
       reference_impl="experiments/phase2/p_comp_3.py",
       gold_formal="formal/dafny/PCOMP_3.dfy",
       lemma_hint="ztNotHorn / ZT2HornWitness",
       natural_spec="NEGATIVE RESULT (feature, not bug): Zernike-Torrance / ZT profile curvature and Horn quadratic slope are not the same function family; there is no formal entailment either way on all DEMs. Construct an explicit witness DEM where the two operators disagree, and prove they are not equal on that witness. Do not wash this into a positive universal equivalence."),
  dict(id="GPB-015b-ring-neg", difficulty="L3", target="dafny", prop_family="P-006", expected_verdict="NEG",
       reference_impl="experiments/phase1/p006_watershed.py",
       gold_formal="formal/dafny/P006_watershed.dfy",
       lemma_hint="RingSucc / no fixed point (P-006b)",
       natural_spec="P-006b counterexample: on a flat 4-cycle successor RingSucc (0->1->2->3->0), every state moves and there is no fixed point; therefore orbits never terminate. Prove absence of a fixed point / non-termination for this ring. Do not claim global watershed uniqueness without the no-flat-loop precondition."),
  dict(id="GPB-025-rot45-neg", difficulty="L3", target="dafny", prop_family="P-COMP-4", expected_verdict="NEG",
       reference_impl="experiments/phase2/p_comp_4.py",
       gold_formal="formal/dafny/PCOMP_4_homotopy.dfy",
       lemma_hint="45-degree FAIL-TOLERANCE (numeric boundary)",
       natural_spec="NEGATIVE / BOUNDARY: 45-degree rotation of a DEM is NOT claimed to preserve fill-then-D8 metrics within epsilon tolerance in the verified PCOMP_4 fragment (empirical FAIL-TOLERANCE). Formalize a clear statement that axis-aligned homotopy results do not entail 45-degree invariance, ideally with a witness schema or an explicit non-entailment lemma. Do not relabel the 45-degree case as PASS."),
]

for t in tasks:
    lines = []
    lines.append(f"id: {t['id']}")
    lines.append(f"difficulty: {t['difficulty']}")
    lines.append(f"target: {t['target']}")
    lines.append(f"prop_family: {t['prop_family']}")
    lines.append(f"expected_verdict: {t['expected_verdict']}")
    lines.append("natural_spec: |")
    for ln in textwrap.wrap(t["natural_spec"], width=88):
        lines.append(f"  {ln}")
    lines.append(f"reference_impl: {t['reference_impl']}")
    lines.append(f"gold_formal: {t['gold_formal']}")
    lines.append(f"lemma_hint: {t['lemma_hint']}")
    if t.get("notes"):
        lines.append(f"notes: {t['notes']}")
    lines.append("schema_version: p2_llm_task_v1")
    (out / f"{t['id']}.yaml").write_text("\n".join(lines) + "\n", encoding="utf-8")

print("rewrote", len(tasks))
sample = (out / "GPB-001-flat.yaml").read_text(encoding="utf-8")
assert "\\n" not in sample
print("newlines", sample.count("\n"))
print(sample[:200])
