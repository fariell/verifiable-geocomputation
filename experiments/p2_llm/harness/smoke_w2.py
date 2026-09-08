"""W2 smoke: validate all tasks + generate 1 task × 1 model × P0 + verify attempt + score."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from common import RESULTS_RAW, RESULTS_SCORED, TASKS_DIR, validate_all_tasks, write_json
from run_generate import DEFAULT_MODEL, generate_one
from run_verify import verify_dafny, verify_lean
from score_semantic import score_pair
from common import load_task


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH W2 smoke")
    p.add_argument("--task", default="GPB-001-flat")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--prompt", default="P0", choices=["P0", "P1", "P2"])
    p.add_argument("--dry-run", action="store_true")
    p.add_argument(
        "--backend",
        default="anthropic",
        choices=["anthropic", "fixture"],
        help="anthropic tries live API then falls back to fixture on failure",
    )
    args = p.parse_args(argv)

    report: dict = {"smoke": "task16-W2", "steps": []}

    # 1) schema validate all tasks
    val = validate_all_tasks()
    report["steps"].append(
        {
            "step": "validate_tasks",
            "n_tasks": val["n_tasks"],
            "n_ok": val["n_ok"],
            "failed": [r for r in val["rows"] if not r["ok"]],
        }
    )
    if val["n_ok"] != val["n_tasks"] or val["n_tasks"] < 21:
        report["verdict"] = "FAIL"
        report["blocker"] = "task schema validation failed or n_tasks < 21"
        write_json(RESULTS_SCORED / "smoke_w2.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    # 2) generate
    task_path = TASKS_DIR / f"{args.task}.yaml"
    if not task_path.is_file():
        report["verdict"] = "FAIL"
        report["blocker"] = f"missing task {task_path}"
        write_json(RESULTS_SCORED / "smoke_w2.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    try:
        gen = generate_one(
            task_path,
            prompt_id=args.prompt,
            model=args.model,
            sample_index=0,
            repair_round=0,
            temperature=0.0,
            max_tokens=4096,
            dry_run=args.dry_run,
            backend=args.backend,
        )
    except Exception as exc:
        report["verdict"] = "BLOCKED"
        report["blocker"] = f"generate failed: {exc}"
        report["steps"].append({"step": "generate", "error": str(exc)})
        write_json(RESULTS_SCORED / "smoke_w2.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 2

    report["steps"].append(
        {
            "step": "generate",
            "status": gen.get("status"),
            "backend": gen.get("backend"),
            "model": gen.get("model"),
            "prompt_id": gen.get("prompt_id"),
            "prompt_template_sha256": gen.get("prompt_template_sha256"),
            "raw_json": gen.get("raw_json"),
            "raw_source": gen.get("raw_source"),
            "raw_text_chars": len(gen.get("raw_text") or ""),
            "api_usage": gen.get("api_usage"),
            "api_error": gen.get("api_error"),
            "note": gen.get("note"),
        }
    )

    if args.dry_run:
        report["verdict"] = "PASS"
        report["note"] = "dry-run only (no API, no verify numbers claimed)"
        write_json(RESULTS_SCORED / "smoke_w2.json", report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0

    src = Path(gen["raw_source"])
    task = load_task(task_path)
    if task["target"] == "dafny":
        ver = verify_dafny(src)
    else:
        ver = verify_lean(src)
    ver_out = RESULTS_SCORED / f"{src.stem}.verify.json"
    write_json(ver_out, ver)
    report["steps"].append(
        {
            "step": "verify",
            "status": ver.get("status"),
            "compile_rc": ver.get("compile_rc"),
            "verify_rc": ver.get("verify_rc"),
            "note": ver.get("note"),
            "out": str(ver_out),
        }
    )

    # update raw json rcs
    if gen.get("raw_json"):
        raw_path = Path(gen["raw_json"])
        data = json.loads(raw_path.read_text(encoding="utf-8"))
        data["compile_rc"] = ver.get("compile_rc")
        data["verify_rc"] = ver.get("verify_rc")
        data["verify_status"] = ver.get("status")
        from common import write_json as _wj

        _wj(raw_path, data)

    score = score_pair(
        task=task,
        generated_text=gen.get("raw_text") or "",
        verify_rc=ver.get("verify_rc"),
        compile_rc=ver.get("compile_rc"),
    )
    score_out = RESULTS_SCORED / f"{src.stem}.semantic.json"
    write_json(score_out, score)
    report["steps"].append({"step": "score_semantic", "out": str(score_out), **score})

    # W2 acceptance: harness path works. Live LLM optional; never fabricate verify@.
    has_text = bool((gen.get("raw_text") or "").strip())
    status = gen.get("status")
    if has_text and status in {"GENERATED", "GENERATED_FIXTURE"}:
        report["verdict"] = "PASS"
        bits = [
            f"backend={gen.get('backend')}",
            f"generate_status={status}",
            f"verify_status={ver.get('status')}",
        ]
        if gen.get("api_error"):
            bits.append("live_api=BLOCKED→fixture_fallback")
        if ver.get("status") == "TOOLCHAIN_MISSING":
            bits.append("local_toolchain=MISSING (no fabricated verify@; AutoDL later)")
        if status == "GENERATED_FIXTURE":
            bits.append("NO model metrics — fixture only")
        report["note"] = "; ".join(bits)
    else:
        report["verdict"] = "FAIL"
        report["blocker"] = "generate did not produce raw_text"

    write_json(RESULTS_SCORED / "smoke_w2.json", report)
    # also keep a small pointer under raw/
    write_json(RESULTS_RAW / "smoke_w2_pointer.json", {"scored": str(RESULTS_SCORED / "smoke_w2.json")})
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["verdict"] == "PASS" else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
