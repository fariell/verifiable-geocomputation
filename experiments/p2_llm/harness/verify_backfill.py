"""Offline verify backfill for W3 (A.16.2).

Scans results/raw/*.{dfy,lean}, runs dafny/lean verify (no LLM calls), and
rewrites compile_rc / verify_rc / verify_status / semantic into:
  * matching raw/*.json
  * l1_full_w3_live.jsonl (rewritten atomically)

Also sanitizes a truncated last jsonl line from a killed agent (A.16.3).
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from common import RESULTS_RAW, RESULTS_SCORED, TASKS_DIR, load_task, write_json
from run_verify import is_metric_eligible, verify_dafny, verify_lean
from score_semantic import score_pair

JSONL_NAME = "l1_full_w3_live.jsonl"


def sanitize_jsonl(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {"ok": False, "reason": "missing", "n_kept": 0}
    raw = path.read_text(encoding="utf-8", errors="replace")
    lines = raw.splitlines()
    kept: list[str] = []
    bad: list[str] = []
    for i, line in enumerate(lines):
        s = line.strip()
        if not s:
            continue
        try:
            json.loads(s)
            kept.append(s)
        except json.JSONDecodeError:
            bad.append(f"line_{i+1}")
    if bad:
        bak = path.with_suffix(path.suffix + ".bak")
        shutil.copy2(path, bak)
        path.write_text("\n".join(kept) + ("\n" if kept else ""), encoding="utf-8")
    return {
        "ok": True,
        "n_kept": len(kept),
        "n_bad": len(bad),
        "bad_lines": bad,
        "backup": str(path.with_suffix(path.suffix + ".bak")) if bad else None,
    }


def task_for_stem(stem: str) -> dict[str, Any] | None:
    # stem = GPB-001-flat__deepseek-ai_DeepSeek-V3.2__P0__k1__r0
    task_id = stem.split("__", 1)[0]
    for path in TASKS_DIR.glob("*.yaml"):
        t = load_task(path)
        if t.get("id") == task_id:
            return t
    return None


def backfill_one(source: Path, *, force: bool = False) -> dict[str, Any]:
    raw_json = source.with_suffix(".json")
    prior: dict[str, Any] = {}
    if raw_json.is_file():
        prior = json.loads(raw_json.read_text(encoding="utf-8"))
    if (
        not force
        and prior.get("verify_status") == "RAN"
        and prior.get("compile_rc") is not None
        and prior.get("verify_rc") is not None
    ):
        return {
            "source": str(source),
            "skipped": True,
            "verify_status": prior.get("verify_status"),
            "compile_rc": prior.get("compile_rc"),
            "verify_rc": prior.get("verify_rc"),
            "metric_eligible": is_metric_eligible(
                verify_status=prior.get("verify_status"),
                compile_rc=prior.get("compile_rc"),
                verify_rc=prior.get("verify_rc"),
                generate_status=prior.get("status"),
            ),
        }

    if source.suffix.lower() == ".dfy":
        ver = verify_dafny(source)
    else:
        ver = verify_lean(source)

    write_json(RESULTS_SCORED / f"{source.stem}.verify.json", ver)

    task = task_for_stem(source.stem)
    gen_text = prior.get("raw_text") or source.read_text(encoding="utf-8", errors="replace")
    score: dict[str, Any] | None = None
    if task is not None:
        score = score_pair(
            task=task,
            generated_text=gen_text,
            verify_rc=ver.get("verify_rc"),
            compile_rc=ver.get("compile_rc"),
        )
        write_json(RESULTS_SCORED / f"{source.stem}.semantic.json", score)

    if raw_json.is_file():
        prior["compile_rc"] = ver.get("compile_rc")
        prior["verify_rc"] = ver.get("verify_rc")
        prior["verify_status"] = ver.get("status")
        prior["verify_note"] = ver.get("note")
        prior["failure_code_auto"] = ver.get("failure_code")
        if score is not None:
            prior["semantic"] = score.get("fidelity_label")
            prior["fidelity_label"] = score.get("fidelity_label")
        prior["metric_eligible"] = is_metric_eligible(
            verify_status=ver.get("status"),
            compile_rc=ver.get("compile_rc"),
            verify_rc=ver.get("verify_rc"),
            generate_status=prior.get("status"),
        )
        prior["backfill_ts_utc"] = datetime.now(timezone.utc).isoformat()
        write_json(raw_json, prior)

    return {
        "source": str(source),
        "skipped": False,
        "verify_status": ver.get("status"),
        "compile_rc": ver.get("compile_rc"),
        "verify_rc": ver.get("verify_rc"),
        "semantic": None if score is None else score.get("fidelity_label"),
        "metric_eligible": is_metric_eligible(
            verify_status=ver.get("status"),
            compile_rc=ver.get("compile_rc"),
            verify_rc=ver.get("verify_rc"),
            generate_status=prior.get("status"),
        ),
        "toolchain": ver.get("toolchain"),
        "failure_code": ver.get("failure_code"),
    }


def rewrite_jsonl_from_raw(jsonl_path: Path) -> dict[str, Any]:
    """Patch jsonl rows in place from updated raw/*.json by raw_json / stem match."""
    if not jsonl_path.is_file():
        return {"ok": False, "reason": "missing_jsonl"}
    rows: list[dict[str, Any]] = []
    for line in jsonl_path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s:
            continue
        rows.append(json.loads(s))

    n_patched = 0
    for row in rows:
        raw_s = row.get("raw_json")
        if not raw_s:
            continue
        raw_p = Path(raw_s)
        if not raw_p.is_file():
            continue
        data = json.loads(raw_p.read_text(encoding="utf-8"))
        if data.get("verify_status") is None and data.get("compile_rc") is None:
            continue
        row["compile_rc"] = data.get("compile_rc")
        row["verify_rc"] = data.get("verify_rc")
        row["verify_status"] = data.get("verify_status")
        if data.get("semantic"):
            row["semantic"] = data.get("semantic")
        row["metric_eligible"] = is_metric_eligible(
            verify_status=data.get("verify_status"),
            compile_rc=data.get("compile_rc"),
            verify_rc=data.get("verify_rc"),
            generate_status=data.get("status") or row.get("generate_status"),
        )
        n_patched += 1

    tmp = jsonl_path.with_suffix(".jsonl.tmp")
    tmp.write_text(
        "\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n",
        encoding="utf-8",
    )
    tmp.replace(jsonl_path)
    n_elig = sum(1 for r in rows if r.get("metric_eligible"))
    n_ran = sum(1 for r in rows if r.get("verify_status") == "RAN")
    n_missing = sum(1 for r in rows if r.get("verify_status") == "TOOLCHAIN_MISSING")
    return {
        "ok": True,
        "n_rows": len(rows),
        "n_patched": n_patched,
        "n_metric_eligible": n_elig,
        "n_verify_ran": n_ran,
        "n_toolchain_missing": n_missing,
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="A.16 offline verify backfill")
    p.add_argument("--force", action="store_true", help="re-verify even if RAN already")
    p.add_argument("--limit", type=int, default=0, help="max sources to verify (0=all)")
    p.add_argument("--dfy-only", action="store_true", help="skip .lean sources")
    args = p.parse_args(argv)

    RESULTS_RAW.mkdir(parents=True, exist_ok=True)
    jsonl_path = RESULTS_RAW / JSONL_NAME
    sanitize = sanitize_jsonl(jsonl_path)
    print(f"[backfill] sanitize_jsonl: {sanitize}", flush=True)

    sources = sorted(RESULTS_RAW.glob("*.dfy"))
    if not args.dfy_only:
        sources += sorted(RESULTS_RAW.glob("*.lean"))
    if args.limit and args.limit > 0:
        sources = sources[: args.limit]

    results: list[dict[str, Any]] = []
    for i, src in enumerate(sources, 1):
        row = backfill_one(src, force=args.force)
        results.append(row)
        print(
            f"[backfill] {i}/{len(sources)} {src.name} "
            f"ver={row.get('verify_status')} crc={row.get('compile_rc')} "
            f"vrc={row.get('verify_rc')} elig={row.get('metric_eligible')} "
            f"sem={row.get('semantic')}",
            flush=True,
        )

    patched = rewrite_jsonl_from_raw(jsonl_path)
    print(f"[backfill] jsonl_patch: {patched}", flush=True)

    summary = {
        "ts_utc": datetime.now(timezone.utc).isoformat(),
        "sanitize": sanitize,
        "n_sources": len(sources),
        "n_ran": sum(1 for r in results if r.get("verify_status") == "RAN"),
        "n_toolchain_missing": sum(
            1 for r in results if r.get("verify_status") == "TOOLCHAIN_MISSING"
        ),
        "n_metric_eligible": sum(1 for r in results if r.get("metric_eligible")),
        "n_compile_ok": sum(1 for r in results if r.get("compile_rc") == 0),
        "n_verify_ok": sum(1 for r in results if r.get("verify_rc") == 0),
        "jsonl": patched,
        "rows": results,
    }
    out = RESULTS_SCORED / "verify_backfill_w3.json"
    write_json(out, summary)
    print(json.dumps({k: v for k, v in summary.items() if k != "rows"}, indent=2), flush=True)
    # Pass if we got at least one real RAN (dafny path alive). Lean-only missing is OK to report.
    if summary["n_ran"] == 0 and sources:
        return 2
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
