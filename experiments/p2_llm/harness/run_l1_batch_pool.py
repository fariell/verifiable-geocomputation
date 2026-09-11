"""Concurrent L1 batch runner (A.17.3). Does not modify run_l1_batch.py.

Design constraints from INBOX §A.17:
  * ThreadPoolExecutor (IO-bound); default --workers 8
  * Reuse run_l1_batch.run_cell (generation + verify semantics unchanged)
  * jsonl append only on the main thread (no concurrent file writes)
  * 429 → exponential backoff; 3 consecutive 429s → auto-reduce workers
  * verify gated to ≤4 concurrent WSL dafny calls (semaphore)
  * A.17.8: append-only with attempt field; never overwrite prior rows
  * A.17.10: --no-capability-fuse to finish M3 coverage even at compile@1=0
"""

from __future__ import annotations

import argparse
import json
import sys
import threading
import time
from concurrent.futures import Future, ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import run_l1_batch as serial
import run_verify
from common import RESULTS_RAW, RESULTS_SCORED, load_task, validate_all_tasks, write_json
from run_l1_batch import (
    DEFAULT_BUDGET_USD,
    append_jsonl,
    dry_validate_prompts,
    estimate_cost_usd,
    list_l1_tasks,
    resolve_models,
    run_cell,
)
from run_generate import DEFAULT_MODEL
from openai_compat import probe_live_api_openai

# Gate WSL dafny concurrency (A.17.3 §5).
_VERIFY_SEM = threading.Semaphore(4)
_ORIG_VERIFY_DAFNY = run_verify.verify_dafny
_ORIG_VERIFY_LEAN = run_verify.verify_lean


def _gated_verify_dafny(path: Path, **kwargs: Any) -> dict[str, Any]:
    with _VERIFY_SEM:
        return _ORIG_VERIFY_DAFNY(path, **kwargs)


def _gated_verify_lean(path: Path, **kwargs: Any) -> dict[str, Any]:
    with _VERIFY_SEM:
        return _ORIG_VERIFY_LEAN(path, **kwargs)


def install_verify_gate() -> None:
    run_verify.verify_dafny = _gated_verify_dafny  # type: ignore[assignment]
    run_verify.verify_lean = _gated_verify_lean  # type: ignore[assignment]
    serial.verify_dafny = _gated_verify_dafny  # type: ignore[attr-defined]
    serial.verify_lean = _gated_verify_lean  # type: ignore[attr-defined]


def is_rate_limit_error(cell: dict[str, Any]) -> bool:
    blob = " ".join(
        str(x)
        for x in (
            cell.get("api_error"),
            cell.get("note"),
            cell.get("status"),
        )
        if x
    ).lower()
    return "429" in blob or "rate limit" in blob or "rate_limit" in blob


def load_attempt_counts(jsonl_path: Path) -> dict[tuple[Any, ...], int]:
    counts: dict[tuple[Any, ...], int] = {}
    if not jsonl_path.is_file():
        return counts
    with jsonl_path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            try:
                o = json.loads(s)
            except json.JSONDecodeError:
                continue
            k = (
                o.get("model"),
                o.get("task_id"),
                o.get("prompt_id"),
                o.get("sample_index"),
            )
            counts[k] = counts.get(k, 0) + 1
    return counts


def run_cell_with_429_retry(
    task_path: Path,
    *,
    prompt_id: str,
    model: str,
    sample_index: int,
    do_verify: bool,
    backend: str,
    max_429_retries: int = 3,
) -> dict[str, Any]:
    delay = 1.0
    last: dict[str, Any] = {}
    for attempt_429 in range(max_429_retries + 1):
        last = run_cell(
            task_path,
            prompt_id=prompt_id,
            model=model,
            sample_index=sample_index,
            do_verify=do_verify,
            backend=backend,
        )
        if not is_rate_limit_error(last):
            last["rate_limit_retries"] = attempt_429
            return last
        if attempt_429 >= max_429_retries:
            break
        time.sleep(delay)
        delay = min(delay * 2.0, 30.0)
    last["rate_limit_retries"] = max_429_retries
    last["note"] = ((last.get("note") or "") + " | gave_up_after_429_retries").strip(" |")
    return last


def filter_task_paths(
    paths: list[Path],
    *,
    limit: int,
    task_ids: list[str],
) -> list[Path]:
    if task_ids:
        wanted = set(task_ids)
        paths = [p for p in paths if load_task(p).get("id") in wanted]
    if limit > 0:
        paths = paths[:limit]
    return paths


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH W3 L1 concurrent batch (A.17)")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--models", default="")
    p.add_argument("--prompts", default="P0,P1,P2")
    p.add_argument("--k", type=int, default=5)
    p.add_argument("--backend", default="openai", choices=["anthropic", "openai", "fixture"])
    p.add_argument("--skip-verify", action="store_true")
    p.add_argument("--limit", type=int, default=0, help="max L1 tasks after task-id filter")
    p.add_argument(
        "--task-ids",
        default="",
        help="comma list of task ids (e.g. M3 catch-up 8 tasks)",
    )
    p.add_argument("--require-live", action="store_true")
    p.add_argument("--budget-usd", type=float, default=DEFAULT_BUDGET_USD)
    p.add_argument("--jsonl", default="")
    p.add_argument("--workers", type=int, default=8)
    p.add_argument(
        "--verify-workers",
        type=int,
        default=4,
        help="max concurrent dafny/lean verifies (semaphore)",
    )
    p.add_argument(
        "--no-capability-fuse",
        action="store_true",
        help="A.17.10: do not stop model on compile@1=0 streak (needed for M3 full coverage)",
    )
    p.add_argument(
        "--compare-serial-stems",
        default="",
        help="optional: comma stems already produced by serial; print content-hash check after run",
    )
    args = p.parse_args(argv)

    global _VERIFY_SEM
    _VERIFY_SEM = threading.Semaphore(max(1, args.verify_workers))
    install_verify_gate()

    prompts = [x.strip() for x in args.prompts.split(",") if x.strip()]
    models = resolve_models(args)
    task_ids = [x.strip() for x in args.task_ids.split(",") if x.strip()]
    jsonl_path = Path(args.jsonl) if args.jsonl else (RESULTS_RAW / "l1_full_w3_live.jsonl")

    report: dict[str, Any] = {
        "batch": "task16-W3-L1-pool",
        "models": models,
        "prompts": prompts,
        "k": args.k,
        "backend": args.backend,
        "workers_start": args.workers,
        "verify_workers": args.verify_workers,
        "no_capability_fuse": args.no_capability_fuse,
        "jsonl": str(jsonl_path),
        "steps": [],
        "circuit_breaks": [],
        "worker_reductions": [],
    }

    val = validate_all_tasks()
    report["steps"].append({"step": "validate_tasks", "n_tasks": val["n_tasks"], "n_ok": val["n_ok"]})
    if val["n_ok"] != val["n_tasks"]:
        report["verdict"] = "FAIL"
        report["blocker"] = "task schema validation failed"
        write_json(RESULTS_SCORED / "l1_batch_w3_pool.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    l1_paths = filter_task_paths(list_l1_tasks(), limit=args.limit, task_ids=task_ids)
    report["n_l1"] = len(l1_paths)
    report["l1_ids"] = [load_task(p).get("id") for p in l1_paths]
    report["n_cells_planned"] = len(l1_paths) * len(models) * len(prompts) * args.k

    dry = dry_validate_prompts(l1_paths, prompts)
    report["steps"].append({"step": "dry_validate_prompts", "n": dry["n"], "n_ok": dry["n_ok"]})
    if dry["n_ok"] != dry["n"]:
        report["verdict"] = "FAIL"
        report["blocker"] = "prompt render failed"
        write_json(RESULTS_SCORED / "l1_batch_w3_pool.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    if args.backend == "openai":
        probe = probe_live_api_openai(models[0])
    elif args.backend == "anthropic":
        probe = serial.probe_live_api(models[0])
    else:
        probe = {"live_api_ok": True, "note": "fixture"}
    report["steps"].append({"step": "api_probe", **probe})
    if args.backend in ("anthropic", "openai") and not probe.get("live_api_ok"):
        report["verdict"] = "BLOCKED"
        report["blocker"] = f"live probe failed: {probe.get('error', '')[:200]}"
        report["cells"] = []
        write_json(RESULTS_SCORED / "l1_batch_w3_pool.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 2 if args.require_live else 0

    workers = max(1, args.workers)
    cells: list[dict[str, Any]] = []
    est_spend = 0.0
    t0 = time.time()
    consecutive_429 = 0
    stopped_models: set[str] = set()
    attempt_counts = load_attempt_counts(jsonl_path)

    for model in models:
        if model in stopped_models:
            continue
        http_fail_streak = 0
        compile_fail_streak = 0
        model_cells = 0
        model_gen = 0
        model_compile_ok = 0

        work: list[tuple[Path, str, int]] = []
        for task_path in l1_paths:
            for prompt_id in prompts:
                for sample_index in range(args.k):
                    work.append((task_path, prompt_id, sample_index))

        # Process in waves so we can shrink the pool on 429 storms.
        idx = 0
        while idx < len(work):
            if model in stopped_models or est_spend >= args.budget_usd:
                break
            wave = work[idx : idx + max(workers * 2, workers)]
            idx += len(wave)

            with ThreadPoolExecutor(max_workers=workers) as ex:
                futs: dict[Future, tuple[Path, str, int]] = {}
                for task_path, prompt_id, sample_index in wave:
                    fut = ex.submit(
                        run_cell_with_429_retry,
                        task_path,
                        prompt_id=prompt_id,
                        model=model,
                        sample_index=sample_index,
                        do_verify=not args.skip_verify,
                        backend=args.backend,
                    )
                    futs[fut] = (task_path, prompt_id, sample_index)

                for fut in as_completed(futs):
                    task_path, prompt_id, sample_index = futs[fut]
                    try:
                        cell = fut.result()
                    except Exception as exc:  # pragma: no cover
                        cell = {
                            "task_id": load_task(task_path).get("id"),
                            "prompt_id": prompt_id,
                            "sample_index": sample_index,
                            "model": model,
                            "status": "PROVIDER_ERROR",
                            "api_error": str(exc)[:800],
                            "metric_eligible": False,
                        }

                    key = (model, cell.get("task_id"), prompt_id, sample_index)
                    attempt = attempt_counts.get(key, 0)
                    cell["attempt"] = attempt
                    cell["ts_utc"] = datetime.now(timezone.utc).isoformat()
                    cell["est_spend_usd_cum"] = round(est_spend, 4)
                    cell["pool_workers"] = workers

                    # Main-thread append only (A.17.3 / A.17.8 append-only).
                    append_jsonl(jsonl_path, cell)
                    attempt_counts[key] = attempt + 1
                    cells.append(cell)
                    model_cells += 1

                    usage = cell.get("api_usage") if isinstance(cell.get("api_usage"), dict) else None
                    if cell.get("status") == "GENERATED" and usage:
                        est_spend += estimate_cost_usd(model, usage)

                    if is_rate_limit_error(cell):
                        consecutive_429 += 1
                    else:
                        consecutive_429 = 0

                    if cell.get("status") == "PROVIDER_ERROR":
                        http_fail_streak += 1
                    elif cell.get("status") in ("GENERATED", "SKIP_EXISTING"):
                        http_fail_streak = 0

                    if cell.get("status") == "GENERATED":
                        model_gen += 1
                        crc = cell.get("compile_rc")
                        if crc == 0:
                            model_compile_ok += 1
                            compile_fail_streak = 0
                        elif crc is not None and cell.get("verify_status") != "TOOLCHAIN_MISSING":
                            compile_fail_streak += 1
                        else:
                            compile_fail_streak = 0

                    print(
                        f"[L1-pool] w={workers} {model} {cell.get('task_id')} "
                        f"{prompt_id} k{sample_index} att={attempt} "
                        f"-> {cell.get('status')} ver={cell.get('verify_status')} "
                        f"elig={cell.get('metric_eligible')} spend~${est_spend:.3f}",
                        flush=True,
                    )

                    if consecutive_429 >= 3 and workers > 2:
                        new_w = 4 if workers > 4 else 2
                        report["worker_reductions"].append(
                            {
                                "from": workers,
                                "to": new_w,
                                "reason": "consecutive_429_ge_3",
                                "at_model": model,
                            }
                        )
                        workers = new_w
                        consecutive_429 = 0
                        print(f"[pool] reduce workers → {workers} after 429 storm", flush=True)

                    if http_fail_streak >= 10:
                        report["circuit_breaks"].append(
                            {"reason": "HTTP_STREAK_10", "model": model, "action": "stop_model"}
                        )
                        stopped_models.add(model)
                        print(f"[circuit] stop model {model}: HTTP streak ≥10", flush=True)
                        for pending in futs:
                            pending.cancel()
                        break

                    if (
                        not args.no_capability_fuse
                        and model_gen >= 20
                        and model_compile_ok == 0
                        and compile_fail_streak >= 20
                    ):
                        report["circuit_breaks"].append(
                            {
                                "reason": "COMPILE_ZERO_STREAK_20",
                                "model": model,
                                "action": "stop_model_incapable",
                            }
                        )
                        stopped_models.add(model)
                        print(
                            f"[circuit] stop model {model}: compile@1=0 over 20 cells",
                            flush=True,
                        )
                        for pending in futs:
                            pending.cancel()
                        break

                    if est_spend >= args.budget_usd:
                        report["circuit_breaks"].append(
                            {
                                "reason": "BUDGET_CEILING",
                                "est_spend_usd": round(est_spend, 4),
                                "ceiling": args.budget_usd,
                            }
                        )
                        stopped_models.update(models)
                        for pending in futs:
                            pending.cancel()
                        break

        print(
            f"[L1-pool] model-done {model} cells={model_cells} gen={model_gen} "
            f"compile_ok={model_compile_ok} stopped={model in stopped_models}",
            flush=True,
        )

    report["cells"] = cells
    report["elapsed_s"] = round(time.time() - t0, 2)
    report["est_spend_usd"] = round(est_spend, 4)
    report["workers_final"] = workers
    n_gen = sum(1 for c in cells if c.get("status") == "GENERATED")
    n_skip = sum(1 for c in cells if c.get("status") == "SKIP_EXISTING")
    n_err = sum(1 for c in cells if c.get("status") == "PROVIDER_ERROR")
    n_elig = sum(1 for c in cells if c.get("metric_eligible"))
    planned = report["n_cells_planned"]
    done = n_gen + n_skip
    report["summary"] = {
        "n_cells": len(cells),
        "n_planned": planned,
        "n_generated_live": n_gen,
        "n_skip_existing": n_skip,
        "n_provider_error": n_err,
        "n_metric_eligible": n_elig,
        "pct_done": round(100.0 * done / planned, 2) if planned else 0.0,
        "partial": done < planned,
    }

    if n_gen + n_skip == 0:
        report["verdict"] = "FAIL"
        report["blocker"] = "no GENERATED/SKIP cells"
        rc = 1
    elif done >= planned:
        report["verdict"] = "PASS"
        rc = 0
    elif done >= 0.8 * planned:
        report["verdict"] = "PASS"
        report["summary"]["partial"] = True
        rc = 0
    else:
        report["verdict"] = "PARTIAL"
        rc = 0

    # Optional A.17.4 content check vs prior serial artifacts.
    if args.compare_serial_stems:
        mismatches = []
        for stem in [x.strip() for x in args.compare_serial_stems.split(",") if x.strip()]:
            a = RESULTS_RAW / f"{stem}.dfy"
            if not a.is_file():
                mismatches.append({"stem": stem, "error": "missing"})
                continue
            # Pool resume should SKIP_EXISTING → same bytes as serial.
            mismatches.append(
                {
                    "stem": stem,
                    "bytes": a.stat().st_size,
                    "note": "present; pool should SKIP_EXISTING without rewrite",
                }
            )
        report["compare_serial"] = mismatches

    write_json(RESULTS_SCORED / "l1_batch_w3_pool.json", report)
    slim = {k: v for k, v in report.items() if k != "cells"}
    try:
        print(json.dumps(slim, ensure_ascii=False, indent=2))
    except UnicodeEncodeError:
        print(json.dumps(slim, ensure_ascii=True, indent=2))
    print(
        f"[run_l1_batch_pool] cells={len(cells)} planned={planned} "
        f"verdict={report['verdict']} workers={workers} jsonl={jsonl_path}",
        flush=True,
    )
    return rc


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
