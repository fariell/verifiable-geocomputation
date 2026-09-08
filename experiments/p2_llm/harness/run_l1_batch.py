"""W3 L1 main-experiment batch runner (resume-safe). Never fabricates verify@."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

from common import (
    RESULTS_RAW,
    RESULTS_SCORED,
    TASKS_DIR,
    load_task,
    raw_result_stem,
    render_prompt,
    utc_today,
    validate_all_tasks,
    write_json,
)
from run_generate import DEFAULT_MODEL, generate_one
from run_verify import verify_dafny, verify_lean
from score_semantic import score_pair


def list_l1_tasks() -> list[Path]:
    out: list[Path] = []
    for path in sorted(TASKS_DIR.glob("*.yaml")):
        task = load_task(path)
        if task.get("difficulty") == "L1":
            out.append(path)
    return out


def existing_raw(task_id: str, model: str, prompt_id: str, sample_index: int) -> Path | None:
    stem = raw_result_stem(task_id, model, prompt_id, sample_index, 0)
    p = RESULTS_RAW / f"{stem}.json"
    return p if p.is_file() else None


def probe_live_api(model: str) -> dict[str, Any]:
    """Lightweight connectivity probe; does not count as an experiment sample."""
    from run_generate import call_messages_api, extract_text

    try:
        resp = call_messages_api(
            prompt="Reply with exactly: PONG",
            model=model,
            temperature=0.0,
            max_tokens=16,
            timeout_s=45.0,
        )
        text = extract_text(resp)
        return {
            "live_api_ok": True,
            "model_locked": resp.get("model") or model,
            "api_base": resp.get("_resolved_base"),
            "pong_chars": len(text),
            "call_date": utc_today(),
        }
    except Exception as exc:
        return {
            "live_api_ok": False,
            "error": str(exc)[:800],
            "call_date": utc_today(),
        }


def dry_validate_prompts(paths: list[Path], prompts: list[str]) -> dict[str, Any]:
    rows = []
    n_ok = 0
    for path in paths:
        task = load_task(path)
        for pid in prompts:
            try:
                text = render_prompt(task, pid)
                rows.append(
                    {
                        "id": task["id"],
                        "prompt": pid,
                        "ok": True,
                        "chars": len(text),
                    }
                )
                n_ok += 1
            except Exception as exc:
                rows.append(
                    {
                        "id": task["id"],
                        "prompt": pid,
                        "ok": False,
                        "error": str(exc)[:300],
                    }
                )
    return {"n": len(rows), "n_ok": n_ok, "rows": rows}


def run_cell(
    task_path: Path,
    *,
    prompt_id: str,
    model: str,
    sample_index: int,
    do_verify: bool,
    backend: str,
) -> dict[str, Any]:
    task = load_task(task_path)
    prior = existing_raw(task["id"], model, prompt_id, sample_index)
    if prior is not None:
        data = json.loads(prior.read_text(encoding="utf-8"))
        return {
            "task_id": task["id"],
            "prompt_id": prompt_id,
            "sample_index": sample_index,
            "status": "SKIP_EXISTING",
            "raw_json": str(prior),
            "generate_status": data.get("status"),
            "model": data.get("model"),
        }

    gen = generate_one(
        task_path,
        prompt_id=prompt_id,
        model=model,
        sample_index=sample_index,
        repair_round=0,
        temperature=0.0,
        max_tokens=4096,
        dry_run=False,
        backend=backend,
    )
    cell: dict[str, Any] = {
        "task_id": task["id"],
        "prompt_id": prompt_id,
        "sample_index": sample_index,
        "status": gen.get("status"),
        "backend": gen.get("backend"),
        "model": gen.get("model"),
        "raw_json": gen.get("raw_json"),
        "raw_source": gen.get("raw_source"),
        "api_error": gen.get("api_error"),
        "note": gen.get("note"),
    }
    if gen.get("status") == "GENERATED_FIXTURE":
        cell["metric_eligible"] = False
        cell["note"] = (cell.get("note") or "") + " | NOT eligible for verify@ tables"
        return cell

    if not do_verify or not gen.get("raw_source"):
        cell["metric_eligible"] = gen.get("status") == "GENERATED"
        return cell

    src = Path(gen["raw_source"])
    if task["target"] == "dafny":
        ver = verify_dafny(src)
    else:
        ver = verify_lean(src)
    ver_out = RESULTS_SCORED / f"{src.stem}.verify.json"
    write_json(ver_out, ver)
    if gen.get("raw_json"):
        raw_path = Path(gen["raw_json"])
        data = json.loads(raw_path.read_text(encoding="utf-8"))
        data["compile_rc"] = ver.get("compile_rc")
        data["verify_rc"] = ver.get("verify_rc")
        data["verify_status"] = ver.get("status")
        write_json(raw_path, data)
    score = score_pair(
        task=task,
        generated_text=gen.get("raw_text") or "",
        verify_rc=ver.get("verify_rc"),
        compile_rc=ver.get("compile_rc"),
    )
    score_out = RESULTS_SCORED / f"{src.stem}.semantic.json"
    write_json(score_out, score)
    cell["verify_status"] = ver.get("status")
    cell["compile_rc"] = ver.get("compile_rc")
    cell["verify_rc"] = ver.get("verify_rc")
    cell["semantic"] = score.get("fidelity_label")
    cell["metric_eligible"] = (
        gen.get("status") == "GENERATED" and ver.get("status") == "RAN"
    )
    return cell


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH W3 L1 batch")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument(
        "--prompts",
        default="P0,P1",
        help="comma list; default P0,P1 (P2 needs verifier loop — W3 start uses P0/P1)",
    )
    p.add_argument("--k", type=int, default=1, help="samples per cell (DESIGN allows ≤5)")
    p.add_argument("--dry-run-prompts", action="store_true")
    p.add_argument(
        "--backend",
        default="anthropic",
        choices=["anthropic", "fixture"],
        help="anthropic=live; fixture=NOT for metrics",
    )
    p.add_argument("--skip-verify", action="store_true")
    p.add_argument("--limit", type=int, default=0, help="max L1 tasks (0=all)")
    p.add_argument(
        "--require-live",
        action="store_true",
        help="abort with BLOCKED if live API probe fails (default for W3 main)",
    )
    args = p.parse_args(argv)

    prompts = [x.strip() for x in args.prompts.split(",") if x.strip()]
    report: dict[str, Any] = {
        "batch": "task16-W3-L1",
        "call_date": utc_today(),
        "model_requested": args.model,
        "prompts": prompts,
        "k": args.k,
        "backend": args.backend,
        "steps": [],
    }

    val = validate_all_tasks()
    report["steps"].append(
        {
            "step": "validate_tasks",
            "n_tasks": val["n_tasks"],
            "n_ok": val["n_ok"],
        }
    )
    if val["n_ok"] != val["n_tasks"]:
        report["verdict"] = "FAIL"
        report["blocker"] = "task schema validation failed"
        write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    l1_paths = list_l1_tasks()
    if args.limit > 0:
        l1_paths = l1_paths[: args.limit]
    report["n_l1"] = len(l1_paths)
    report["l1_ids"] = [load_task(p).get("id") for p in l1_paths]

    dry = dry_validate_prompts(l1_paths, prompts)
    report["steps"].append(
        {
            "step": "dry_validate_prompts",
            "n": dry["n"],
            "n_ok": dry["n_ok"],
            "failed": [r for r in dry["rows"] if not r["ok"]],
        }
    )
    if dry["n_ok"] != dry["n"]:
        report["verdict"] = "FAIL"
        report["blocker"] = "prompt gold-leak / render failed on L1"
        write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    if args.dry_run_prompts:
        report["verdict"] = "PASS"
        report["note"] = "dry-run prompts only; no API; no verify@ claimed"
        write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0

    if args.backend == "anthropic":
        probe = probe_live_api(args.model)
        report["steps"].append({"step": "api_probe", **probe})
        write_json(RESULTS_SCORED / "api_probe_w3.json", probe)
        if not probe.get("live_api_ok"):
            report["verdict"] = "BLOCKED"
            report["blocker"] = (
                "live Anthropic unreachable on this host "
                f"(error={probe.get('error', '')[:200]}). "
                "Need reachable ANTHROPIC_BASE_URL / key or AutoDL egress. "
                "No verify@ numbers fabricated."
            )
            report["cells"] = []
            write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
            print(json.dumps(report, ensure_ascii=False, indent=2))
            return 2 if args.require_live else 0
        if probe.get("model_locked"):
            report["model_locked"] = probe["model_locked"]

    cells: list[dict[str, Any]] = []
    t0 = time.time()
    for task_path in l1_paths:
        for prompt_id in prompts:
            for sample_index in range(args.k):
                cell = run_cell(
                    task_path,
                    prompt_id=prompt_id,
                    model=args.model,
                    sample_index=sample_index,
                    do_verify=not args.skip_verify,
                    backend=args.backend,
                )
                cells.append(cell)
                print(
                    f"[L1] {cell.get('task_id')} {prompt_id} k{sample_index} "
                    f"-> {cell.get('status')} eligible={cell.get('metric_eligible')}",
                    flush=True,
                )

    report["cells"] = cells
    report["elapsed_s"] = round(time.time() - t0, 2)
    n_gen = sum(1 for c in cells if c.get("status") == "GENERATED")
    n_fix = sum(1 for c in cells if c.get("status") == "GENERATED_FIXTURE")
    n_elig = sum(1 for c in cells if c.get("metric_eligible"))
    report["summary"] = {
        "n_cells": len(cells),
        "n_generated_live": n_gen,
        "n_fixture": n_fix,
        "n_metric_eligible": n_elig,
    }
    # Honesty: only PASS if we have live generations (fixture alone is not W3 main).
    if n_gen > 0 and n_fix == 0:
        report["verdict"] = "PASS"
        report["note"] = (
            f"live L1 cells generated={n_gen}; "
            "verify@ tables only from metric_eligible + AutoDL authority verify if local TOOLCHAIN_MISSING"
        )
        rc = 0
    elif n_fix and not n_gen:
        report["verdict"] = "BLOCKED"
        report["blocker"] = "only fixture outputs; not reportable as model metrics"
        rc = 2
    else:
        report["verdict"] = "FAIL"
        report["blocker"] = "no GENERATED live cells"
        rc = 1

    write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
    print(json.dumps({k: v for k, v in report.items() if k != "cells"}, ensure_ascii=False, indent=2))
    print(f"[run_l1_batch] cells={len(cells)} verdict={report['verdict']}")
    return rc


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
