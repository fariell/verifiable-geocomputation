"""W3 L1 main-experiment batch runner (resume-safe). Never fabricates verify@.

A.13 / A.15.4:
  * multi-model via --models
  * append-only jsonl checkpoint after every cell
  * circuit breakers (HTTP streak / budget / compile@1=0 streak)
  * openai live path never falls back to fixtures
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime, timezone
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
from run_verify import is_metric_eligible, verify_dafny, verify_lean
from score_semantic import score_pair
from openai_compat import probe_live_api_openai  # noqa: E402

# Rough USD / 1M tokens for A.13.3 budget tracking (siliconflow public list, 2026-09).
# Not billing-grade; used only as a soft circuit-breaker estimate.
PRICE_USD_PER_M: dict[str, tuple[float, float]] = {
    "deepseek-ai/DeepSeek-V3.2": (0.27, 0.42),
    "deepseek-ai/DeepSeek-V3": (0.25, 1.00),
    "Qwen/Qwen2.5-72B-Instruct": (0.59, 0.59),
    "THUDM/GLM-4-32B-0414": (0.14, 0.14),
    "deepseek-ai/DeepSeek-R1": (0.50, 2.18),
}
DEFAULT_BUDGET_USD = 50.0


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


def estimate_cost_usd(model: str, usage: dict[str, Any] | None) -> float:
    if not usage:
        return 0.0
    pin, pout = PRICE_USD_PER_M.get(model, (0.5, 1.0))
    tin = float(usage.get("prompt_tokens") or usage.get("input_tokens") or 0)
    tout = float(usage.get("completion_tokens") or usage.get("output_tokens") or 0)
    return (tin * pin + tout * pout) / 1_000_000.0


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


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
        # A.13.3: ReadTimeout / PROVIDER_ERROR must be retryable — do not permanent-skip.
        if data.get("status") != "PROVIDER_ERROR":
            cell: dict[str, Any] = {
                "task_id": task["id"],
                "prompt_id": prompt_id,
                "sample_index": sample_index,
                "model": model,
                "status": "SKIP_EXISTING",
                "raw_json": str(prior),
                "raw_source": data.get("raw_source"),
                "generate_status": data.get("status"),
                "api_usage": data.get("api_usage"),
                "compile_rc": data.get("compile_rc"),
                "verify_rc": data.get("verify_rc"),
                "verify_status": data.get("verify_status"),
                "semantic": data.get("semantic") or data.get("fidelity_label"),
                # A.16: NEVER treat SKIP_EXISTING alone as eligible (false-positive trap).
                "metric_eligible": is_metric_eligible(
                    verify_status=data.get("verify_status"),
                    compile_rc=data.get("compile_rc"),
                    verify_rc=data.get("verify_rc"),
                    generate_status=data.get("status"),
                ),
            }
            # Re-verify if prior cell never got a real toolchain run (cold-start recovery).
            src_s = data.get("raw_source")
            need_reverify = (
                do_verify
                and src_s
                and Path(src_s).is_file()
                and (
                    data.get("verify_status") in (None, "TOOLCHAIN_MISSING")
                    or data.get("compile_rc") is None
                    or data.get("verify_rc") is None
                )
            )
            if need_reverify:
                src = Path(src_s)
                ver = verify_dafny(src) if task["target"] == "dafny" else verify_lean(src)
                ver_out = RESULTS_SCORED / f"{src.stem}.verify.json"
                write_json(ver_out, ver)
                data["compile_rc"] = ver.get("compile_rc")
                data["verify_rc"] = ver.get("verify_rc")
                data["verify_status"] = ver.get("status")
                data["verify_note"] = ver.get("note")
                data["failure_code_auto"] = ver.get("failure_code")
                write_json(prior, data)
                gen_text = data.get("raw_text") or ""
                if not gen_text and src.is_file():
                    gen_text = src.read_text(encoding="utf-8", errors="replace")
                score = score_pair(
                    task=task,
                    generated_text=gen_text,
                    verify_rc=ver.get("verify_rc"),
                    compile_rc=ver.get("compile_rc"),
                )
                write_json(RESULTS_SCORED / f"{src.stem}.semantic.json", score)
                cell["verify_status"] = ver.get("status")
                cell["compile_rc"] = ver.get("compile_rc")
                cell["verify_rc"] = ver.get("verify_rc")
                cell["semantic"] = score.get("fidelity_label")
                cell["metric_eligible"] = is_metric_eligible(
                    verify_status=ver.get("status"),
                    compile_rc=ver.get("compile_rc"),
                    verify_rc=ver.get("verify_rc"),
                    generate_status=data.get("status"),
                )
                cell["note"] = "reverified_on_skip_existing"
            return cell
        # else: fall through to regenerate over PROVIDER_ERROR stub

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
        allow_fixture_fallback=(backend != "openai"),
    )
    cell = {
        "task_id": task["id"],
        "prompt_id": prompt_id,
        "sample_index": sample_index,
        "model": model,
        "status": gen.get("status"),
        "backend": gen.get("backend"),
        "raw_json": gen.get("raw_json"),
        "raw_source": gen.get("raw_source"),
        "api_error": gen.get("api_error"),
        "api_usage": gen.get("api_usage"),
        "note": gen.get("note"),
    }
    if gen.get("status") == "GENERATED_FIXTURE":
        cell["metric_eligible"] = False
        cell["note"] = (cell.get("note") or "") + " | NOT eligible for verify@ tables"
        return cell
    if gen.get("status") == "PROVIDER_ERROR":
        cell["metric_eligible"] = False
        return cell

    if not do_verify or not gen.get("raw_source"):
        # Without a real verify run, never claim metric eligibility (A.16).
        cell["metric_eligible"] = False
        cell["verify_status"] = "VERIFY_SKIPPED"
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
        data["verify_note"] = ver.get("note")
        data["failure_code_auto"] = ver.get("failure_code")
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
    cell["metric_eligible"] = is_metric_eligible(
        verify_status=ver.get("status"),
        compile_rc=ver.get("compile_rc"),
        verify_rc=ver.get("verify_rc"),
        generate_status=gen.get("status"),
    )
    return cell


def resolve_models(args: argparse.Namespace) -> list[str]:
    if args.models:
        return [x.strip() for x in args.models.split(",") if x.strip()]
    if args.model and args.model != DEFAULT_MODEL:
        return [args.model]
    if args.backend == "openai":
        # blank → provider default inside call_chat_api
        from openai_compat import discover_provider
        import os

        _name, spec = discover_provider(os.environ.get("P2_LLM_PROVIDER"))
        return [spec["default_model"]]
    return [args.model]


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH W3 L1 batch")
    p.add_argument("--model", default=DEFAULT_MODEL, help="single model (legacy)")
    p.add_argument(
        "--models",
        default="",
        help="comma list of model ids (A.13 multi-model). Overrides --model when set.",
    )
    p.add_argument(
        "--prompts",
        default="P0,P1",
        help="comma list; A.13 full = P0,P1,P2",
    )
    p.add_argument("--k", type=int, default=1, help="samples per cell (DESIGN allows ≤5)")
    p.add_argument("--dry-run-prompts", action="store_true")
    p.add_argument(
        "--backend",
        default="anthropic",
        choices=["anthropic", "openai", "fixture"],
        help=(
            "anthropic=live Anthropic; openai=live OpenAI-compatible "
            "(provider from P2_LLM_PROVIDER or auto-detect); fixture=NOT for metrics"
        ),
    )
    p.add_argument("--skip-verify", action="store_true")
    p.add_argument("--limit", type=int, default=0, help="max L1 tasks (0=all)")
    p.add_argument(
        "--require-live",
        action="store_true",
        help="abort with BLOCKED if live API probe fails (default for W3 main)",
    )
    p.add_argument(
        "--budget-usd",
        type=float,
        default=DEFAULT_BUDGET_USD,
        help="A.13.3 soft spend ceiling (estimated from usage × public rates)",
    )
    p.add_argument(
        "--jsonl",
        default="",
        help="checkpoint path; default results/raw/l1_full_<ts>.jsonl",
    )
    args = p.parse_args(argv)

    prompts = [x.strip() for x in args.prompts.split(",") if x.strip()]
    models = resolve_models(args)
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    jsonl_path = Path(args.jsonl) if args.jsonl else (RESULTS_RAW / f"l1_full_{ts}.jsonl")
    # Prefer a stable resume file name when one already exists from this campaign.
    stable = RESULTS_RAW / "l1_full_w3_live.jsonl"
    if not args.jsonl:
        jsonl_path = stable

    report: dict[str, Any] = {
        "batch": "task16-W3-L1",
        "call_date": utc_today(),
        "models": models,
        "prompts": prompts,
        "k": args.k,
        "backend": args.backend,
        "budget_usd": args.budget_usd,
        "jsonl": str(jsonl_path),
        "steps": [],
        "circuit_breaks": [],
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
    report["n_cells_planned"] = len(l1_paths) * len(models) * len(prompts) * args.k

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

    probe_model = models[0]
    if args.backend == "openai":
        probe = probe_live_api_openai(probe_model)
    elif args.backend == "anthropic":
        probe = probe_live_api(probe_model)
    else:
        probe = {"live_api_ok": True, "note": "fixture backend"}
    if args.backend in ("anthropic", "openai"):
        report["steps"].append({"step": "api_probe", **probe})
        write_json(RESULTS_SCORED / "api_probe_w3.json", probe)
        if not probe.get("live_api_ok"):
            report["verdict"] = "BLOCKED"
            report["blocker"] = (
                f"live {args.backend} endpoint unreachable on this host "
                f"(error={probe.get('error', '')[:200]}). "
                "Need a reachable base_url + key, or AutoDL egress. "
                "No verify@ numbers fabricated."
            )
            report["cells"] = []
            write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
            print(json.dumps(report, ensure_ascii=False, indent=2))
            return 2 if args.require_live else 0
        if probe.get("model_locked"):
            report["model_locked"] = probe["model_locked"]

    cells: list[dict[str, Any]] = []
    est_spend = 0.0
    t0 = time.time()
    stopped_models: set[str] = set()

    for model in models:
        http_fail_streak = 0
        compile_fail_streak = 0
        model_cells = 0
        model_gen = 0
        model_compile_ok = 0

        for task_path in l1_paths:
            if model in stopped_models:
                break
            for prompt_id in prompts:
                if model in stopped_models:
                    break
                for sample_index in range(args.k):
                    if model in stopped_models:
                        break
                    if est_spend >= args.budget_usd:
                        report["circuit_breaks"].append(
                            {
                                "reason": "BUDGET_CEILING",
                                "est_spend_usd": round(est_spend, 4),
                                "ceiling": args.budget_usd,
                                "at_model": model,
                            }
                        )
                        stopped_models.update(models)
                        break

                    cell = run_cell(
                        task_path,
                        prompt_id=prompt_id,
                        model=model,
                        sample_index=sample_index,
                        do_verify=not args.skip_verify,
                        backend=args.backend,
                    )
                    cell["ts_utc"] = datetime.now(timezone.utc).isoformat()
                    cell["est_spend_usd_cum"] = round(est_spend, 4)
                    cells.append(cell)
                    append_jsonl(jsonl_path, cell)
                    model_cells += 1

                    usage = cell.get("api_usage") if isinstance(cell.get("api_usage"), dict) else None
                    if cell.get("status") == "GENERATED" and usage:
                        est_spend += estimate_cost_usd(model, usage)

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
                        elif crc not in (None,):
                            # toolchain missing → don't count against capability fuse
                            if cell.get("verify_status") == "TOOLCHAIN_MISSING":
                                compile_fail_streak = 0
                            else:
                                compile_fail_streak += 1
                        else:
                            # no local verify numbers; don't trip capability fuse
                            compile_fail_streak = 0

                    print(
                        f"[L1] {model} {cell.get('task_id')} {prompt_id} k{sample_index} "
                        f"-> {cell.get('status')} ver={cell.get('verify_status')} "
                        f"elig={cell.get('metric_eligible')} "
                        f"spend~${est_spend:.3f}",
                        flush=True,
                    )

                    if http_fail_streak >= 10:
                        report["circuit_breaks"].append(
                            {
                                "reason": "HTTP_STREAK_10",
                                "model": model,
                                "action": "stop_model",
                            }
                        )
                        stopped_models.add(model)
                        print(f"[circuit] stop model {model}: HTTP streak ≥10", flush=True)
                        break

                    if model_gen >= 20 and model_compile_ok == 0 and compile_fail_streak >= 20:
                        report["circuit_breaks"].append(
                            {
                                "reason": "COMPILE_ZERO_STREAK_20",
                                "model": model,
                                "action": "stop_model_incapable",
                                "note": "valid negative result: model lacks task capability",
                            }
                        )
                        stopped_models.add(model)
                        print(
                            f"[circuit] stop model {model}: compile@1=0 over 20 cells",
                            flush=True,
                        )
                        break

        print(
            f"[L1] model-done {model} cells={model_cells} gen={model_gen} "
            f"compile_ok={model_compile_ok} stopped={model in stopped_models}",
            flush=True,
        )

    report["cells"] = cells
    report["elapsed_s"] = round(time.time() - t0, 2)
    report["est_spend_usd"] = round(est_spend, 4)
    n_gen = sum(1 for c in cells if c.get("status") == "GENERATED")
    n_skip = sum(1 for c in cells if c.get("status") == "SKIP_EXISTING")
    n_fix = sum(1 for c in cells if c.get("status") == "GENERATED_FIXTURE")
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
        "n_fixture": n_fix,
        "n_metric_eligible": n_elig,
        "pct_done": round(100.0 * done / planned, 2) if planned else 0.0,
        "partial": done < planned,
    }

    if n_fix and not n_gen and not n_skip:
        report["verdict"] = "BLOCKED"
        report["blocker"] = "only fixture outputs; not reportable as model metrics"
        rc = 2
    elif n_gen + n_skip == 0:
        report["verdict"] = "FAIL"
        report["blocker"] = "no GENERATED live cells"
        rc = 1
    elif done >= planned and n_fix == 0:
        report["verdict"] = "PASS"
        report["note"] = (
            f"live L1 complete gen={n_gen} skip={n_skip}; "
            "verify@ only from metric_eligible; TOOLCHAIN_MISSING → AutoDL authority"
        )
        rc = 0
    elif done >= 0.8 * planned:
        report["verdict"] = "PASS"
        report["note"] = (
            f"partial≥80% gen={n_gen} skip={n_skip} planned={planned}; "
            "A.13.3 allows intermediate report"
        )
        report["summary"]["partial"] = True
        rc = 0
    else:
        report["verdict"] = "PARTIAL"
        report["note"] = (
            f"incomplete gen={n_gen} skip={n_skip} planned={planned}; "
            "resume-safe via jsonl + existing raw/; re-run same command"
        )
        rc = 0

    write_json(RESULTS_SCORED / "l1_batch_w3.json", report)
    slim = {k: v for k, v in report.items() if k != "cells"}
    # Windows consoles are often GBK; never crash the batch after cells are saved.
    try:
        print(json.dumps(slim, ensure_ascii=False, indent=2))
    except UnicodeEncodeError:
        print(json.dumps(slim, ensure_ascii=True, indent=2))
    print(
        f"[run_l1_batch] cells={len(cells)} planned={planned} "
        f"verdict={report['verdict']} jsonl={jsonl_path}",
        flush=True,
    )
    return rc


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
