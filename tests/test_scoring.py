"""Unit tests for score_semantic.score_pair (offline; no network; no dafny)."""

from __future__ import annotations

import sys
from pathlib import Path

HARNESS = Path(__file__).resolve().parents[1] / "experiments" / "p2_llm" / "harness"
sys.path.insert(0, str(HARNESS))

from score_semantic import extract_names, keyword_hits, score_pair  # noqa: E402


def _task(**kwargs):
    base = {
        "id": "GPB-001-flat",
        "expected_verdict": "PASS",
        "natural_spec": "flat elevation window Horn slope magnitude identically zero",
        "gold_formal": "formal/dafny/P001_horn_slope.dfy",
    }
    base.update(kwargs)
    return base


ALIGNED = """
lemma FlatSlopeZero(C: real, w: real)
  requires w > 0.0
  ensures SlopeSq(C, C, C, C, C, C, C, C, w) == 0.0
{
}
function SlopeSq(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real, w: real): real
  requires w > 0.0
{ 0.0 }
"""


def test_empty_output():
    s = score_pair(task=_task(), generated_text="   \n", verify_rc=1, compile_rc=1)
    assert s["fidelity_label"] == "EMPTY"


def test_compile_failure():
    src = "lemma BrokenSyntax(x: int\n" + ("x" * 40)
    s = score_pair(task=_task(), generated_text=src, verify_rc=1, compile_rc=1)
    assert s["fidelity_label"] == "UNCOMPILED"
    assert s["compile_rc"] == 1


def test_verify_failure_compile_ok():
    s = score_pair(
        task=_task(),
        generated_text=ALIGNED,
        verify_rc=1,
        compile_rc=0,
    )
    assert s["fidelity_label"] == "COMPILE_ONLY"
    assert s["verify_rc"] == 1


def test_verify_pass_aligned():
    s = score_pair(task=_task(), generated_text=ALIGNED, verify_rc=0, compile_rc=0)
    assert s["fidelity_label"] in ("LIKELY_ALIGNED", "VERIFIED_NEEDS_HUMAN")
    assert s["drift_suspect"] is False
    assert "FlatSlopeZero" in s["name_overlap"] or s["n_gen_names"] >= 1


def test_verified_but_drift_neg_without_witness():
    """F7 heuristic: NEG task verified without witness/counterexample language."""
    drifted = (
        "lemma AlwaysTrue()\n  ensures true\n{\n}\n"
        "// padding so emptyish threshold is not triggered\n" * 3
    )
    s = score_pair(
        task=_task(
            id="GPB-023-pcomp3-neg",
            expected_verdict="NEG",
            natural_spec="ZT curvature does not imply Horn quadratic",
        ),
        generated_text=drifted,
        verify_rc=0,
        compile_rc=0,
    )
    assert s["drift_suspect"] is True
    assert s["fidelity_label"] == "VERIFIED_BUT_DRIFT_SUSPECT"


def test_verified_but_drift_trivial_assume():
    src = """
lemma FlatSlopeZero(C: real, w: real)
  ensures true
{
  assume false;  // trivializes
}
"""
    s = score_pair(task=_task(), generated_text=src, verify_rc=0, compile_rc=0)
    assert s["trivial_assume"] is True
    assert s["drift_suspect"] is True
    assert s["fidelity_label"] == "VERIFIED_BUT_DRIFT_SUSPECT"


def test_timeout():
    s = score_pair(
        task=_task(),
        generated_text=ALIGNED,
        verify_rc=None,
        compile_rc=None,
        timed_out=True,
    )
    assert s["fidelity_label"] == "TIMEOUT"
    assert s["timed_out"] is True


def test_verify_skipped_no_toolchain():
    s = score_pair(task=_task(), generated_text=ALIGNED, verify_rc=None, compile_rc=None)
    assert s["fidelity_label"] == "VERIFY_SKIPPED"


def test_neg_with_witness_not_drift():
    src = "lemma ZTNotImpliesHorn()\n  ensures exists witness :: counterexample\n{\n}\n" + (" " * 10)
    s = score_pair(
        task=_task(expected_verdict="NEG", natural_spec="ZT not imply Horn counterexample"),
        generated_text=src,
        verify_rc=0,
        compile_rc=0,
    )
    assert s["drift_suspect"] is False


def test_extract_names_and_keywords():
    names = extract_names("lemma FooBar theorem BazQux def HelloWorld")
    assert "FooBar" in names and "BazQux" in names
    kw = keyword_hits(
        "Horn slope elevation window identically zero",
        "Horn slope is zero on flat",
    )
    assert kw["hit_ratio"] > 0.0
    assert "horn" in kw["hit"] or "slope" in kw["hit"]
