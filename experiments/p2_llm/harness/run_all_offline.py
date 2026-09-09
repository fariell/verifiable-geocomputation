"""One-shot offline self-check: fixture → score → figures (no network)."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from common import (
    RESULTS_SCORED,
    TASKS_DIR,
    load_task,
    utc_today,
    validate_all_tasks,
    write_json,
)
from make_figures import build_aggregates, make_figures
from score_semantic import score_pair

HARNESS = Path(__file__).resolve().parent
FIXTURE = HARNESS / "fixtures" / "smoke_GPB-001-flat.dfy"
FIG_DIR = RESULTS_SCORED.parent / "figures"


def _synthetic_demo_cells() -> list[dict[str, Any]]:
    """Offline demo cells for figure pipeline only — NOT live metrics."""
    return [
        {
            "task_id": "GPB-001-flat",
            "difficulty": "L1",
            "model": "fixture-offline-w35",
            "prompt_id": "P0",
            "verify_ok": False,
            "compile_ok": False,
            "repair_round": 0,
            "failure_codes": ["F1"],
            "status": "GENERATED_FIXTURE",
        },
        {
            "task_id": "demo-L2",
            "difficulty": "L2",
            "model": "fixture-offline-w35",
            "prompt_id": "P0",
            "verify_ok": False,
            "compile_ok": True,
            "repair_round": 1,
            "failure_codes": ["F5"],
            "status": "GENERATED_FIXTURE",
        },
        {
            "task_id": "demo-L3",
            "difficulty": "L3",
            "model": "fixture-offline-w35",
            "prompt_id": "P2",
            "verify_ok": False,
            "compile_ok": True,
            "repair_round": 2,
            "failure_codes": ["F7"],
            "status": "GENERATED_FIXTURE",
        },
    ]


def run_offline() -> dict[str, Any]:
    val = validate_all_tasks()
    task_path = TASKS_DIR / "GPB-001-flat.yaml"
    task = load_task(task_path)
    gen = FIXTURE.read_text(encoding="utf-8") if FIXTURE.is_file() else ""

    # Score cases mirroring unit tests (offline labels only)
    cases = [
        score_pair(task=task, generated_text="", verify_rc=1, compile_rc=1),
        score_pair(task=task, generated_text=gen, verify_rc=1, compile_rc=1),
        score_pair(task=task, generated_text=gen, verify_rc=None, compile_rc=None),
        score_pair(task=task, generated_text=gen, verify_rc=None, compile_rc=None, timed_out=True),
        score_pair(
            task={**task, "expected_verdict": "NEG", "id": "GPB-023-pcomp3-neg"},
            generated_text="lemma T()\n  ensures true\n{\n}\n" + (" " * 40),
            verify_rc=0,
            compile_rc=0,
        ),
    ]

    demo_cells = _synthetic_demo_cells()
    payload = {
        "schema_version": "p2_llm_offline_selfcheck_v1",
        "call_date": utc_today(),
        "honesty": "fixture/demo only; n_live must be 0; no verify@ claimed",
        "validate_tasks": {"n_tasks": val["n_tasks"], "n_ok": val["n_ok"]},
        "score_cases": [{"fidelity_label": c["fidelity_label"], "drift_suspect": c["drift_suspect"]} for c in cases],
        "cells": demo_cells,
    }

    agg = build_aggregates(demo_cells)
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    paths = make_figures(agg, FIG_DIR)

    out = {
        **payload,
        "aggregates": agg,
        "figure_paths": [str(p) for p in paths],
        "gates": {
            "schema_ok": val["n_ok"] == val["n_tasks"] and val["n_tasks"] >= 21,
            "score_cases_n": len(cases),
            "figures_n": len(paths),
            "n_live": agg["n_live"],
        },
    }
    write_json(RESULTS_SCORED / "offline_selfcheck_w35.json", out)
    return out


def main(argv: list[str] | None = None) -> int:
    argparse.ArgumentParser(description="P2_AIMATH offline self-check").parse_args(argv)
    out = run_offline()
    gates = out["gates"]
    ok = (
        gates["schema_ok"]
        and gates["score_cases_n"] >= 4
        and gates["figures_n"] >= 4
        and gates["n_live"] == 0
    )
    print(json.dumps(gates, indent=2))
    print(f"figures: {out['figure_paths']}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
