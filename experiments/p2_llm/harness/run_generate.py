"""Generate formalizations via LLM API (Anthropic-compatible). Credentials from env only."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

import httpx

from common import (
    RESULTS_RAW,
    TASKS_DIR,
    load_task,
    raw_result_stem,
    render_prompt,
    sha256_text,
    strip_code_fences,
    utc_today,
    write_json,
)

DEFAULT_MODEL = "claude-sonnet-4-20250514"
DEFAULT_MAX_TOKENS = 4096


def _auth_headers(api_key: str) -> dict[str, str]:
    # Cursor / gateway often uses Bearer OAT; classic Anthropic uses x-api-key.
    return {
        "Authorization": f"Bearer {api_key}",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }


def _candidate_bases() -> list[str]:
    primary = os.environ.get("ANTHROPIC_BASE_URL", "").rstrip("/")
    bases: list[str] = []
    if primary:
        bases.append(primary)
    # Fallback when Cursor gateway is unreachable from this host.
    if "https://api.anthropic.com" not in bases:
        bases.append("https://api.anthropic.com")
    return bases


def call_messages_api(
    *,
    prompt: str,
    model: str,
    temperature: float,
    max_tokens: int,
    timeout_s: float = 90.0,
) -> dict[str, Any]:
    api_key = os.environ.get("ANTHROPIC_AUTH_TOKEN") or os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError(
            "missing ANTHROPIC_AUTH_TOKEN / ANTHROPIC_API_KEY (must stay out of git)"
        )
    body = {
        "model": model,
        "max_tokens": max_tokens,
        "temperature": temperature,
        "messages": [{"role": "user", "content": prompt}],
    }
    errors: list[str] = []
    with httpx.Client(timeout=timeout_s) as client:
        for base in _candidate_bases():
            url = f"{base}/v1/messages"
            try:
                resp = client.post(url, headers=_auth_headers(api_key), json=body)
            except Exception as exc:
                errors.append(f"{url}: {type(exc).__name__}: {exc}")
                continue
            text = resp.text
            try:
                data = resp.json()
            except Exception:
                data = {"raw_http_body": text[:8000]}
            if resp.status_code >= 400:
                errors.append(f"{url}: HTTP {resp.status_code}: {text[:500]}")
                continue
            data["_resolved_base"] = base
            return data
    raise RuntimeError("all Anthropic endpoints failed: " + " | ".join(errors))


def extract_text(api_response: dict[str, Any]) -> str:
    content = api_response.get("content")
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(str(block.get("text", "")))
            elif isinstance(block, str):
                parts.append(block)
        if parts:
            return "\n".join(parts)
    if isinstance(api_response.get("completion"), str):
        return api_response["completion"]
    raise RuntimeError(f"cannot extract text from API response keys={list(api_response)}")


def _fixture_path_for(task: dict[str, Any]) -> Path:
    harness_dir = Path(__file__).resolve().parent
    ext = ".dfy" if task["target"] == "dafny" else ".lean"
    return harness_dir / "fixtures" / f"smoke_{task['id']}{ext}"


def generate_one(
    task_path: Path,
    *,
    prompt_id: str,
    model: str,
    sample_index: int,
    repair_round: int,
    temperature: float,
    max_tokens: int,
    previous_source: str = "",
    verifier_stderr: str = "",
    dry_run: bool = False,
    backend: str = "anthropic",
) -> dict[str, Any]:
    task = load_task(task_path)
    tmpl = render_prompt(
        task,
        prompt_id,
        previous_source=previous_source,
        verifier_stderr=verifier_stderr,
        repair_round=repair_round,
    )
    tmpl_sha = sha256_text(tmpl)
    meta: dict[str, Any] = {
        "task_id": task["id"],
        "model": model,
        "call_date": utc_today(),
        "temperature": temperature,
        "prompt_id": prompt_id,
        "prompt_template_sha256": tmpl_sha,
        "sample_index": sample_index,
        "repair_round": repair_round,
        "target": task["target"],
        "expected_verdict": task["expected_verdict"],
        "gold_formal": task["gold_formal"],
        "schema_version": task.get("schema_version"),
        "compile_rc": None,
        "verify_rc": None,
        "dry_run": dry_run,
        "backend": backend,
    }
    if dry_run:
        meta["raw_text"] = ""
        meta["status"] = "DRY_RUN"
        meta["note"] = "prompt assembled + gold-leak assert only; no API call"
        out = RESULTS_RAW / f"{raw_result_stem(task['id'], model, prompt_id, sample_index, repair_round)}.json"
        write_json(out, meta)
        meta["raw_json"] = str(out)
        return meta

    api_error = None
    cleaned = ""
    locked_model = model
    if backend == "anthropic":
        try:
            api_response = call_messages_api(
                prompt=tmpl, model=model, temperature=temperature, max_tokens=max_tokens
            )
            raw_text = extract_text(api_response)
            cleaned = strip_code_fences(raw_text)
            locked_model = api_response.get("model") or model
            meta["model"] = locked_model
            meta["api_usage"] = api_response.get("usage")
            meta["api_id"] = api_response.get("id")
            meta["api_base"] = api_response.get("_resolved_base")
            meta["status"] = "GENERATED"
        except Exception as exc:
            api_error = str(exc)
            backend = "fixture"
            meta["api_error"] = api_error
            meta["backend"] = "fixture"

    if backend == "fixture":
        fix = _fixture_path_for(task)
        if not fix.is_file():
            raise RuntimeError(
                f"fixture missing for {task['id']}: {fix}"
                + (f" (after API error: {api_error})" if api_error else "")
            )
        cleaned = fix.read_text(encoding="utf-8")
        locked_model = "fixture-offline-w2"
        meta["model"] = locked_model
        meta["status"] = "GENERATED_FIXTURE"
        meta["note"] = (
            "Offline fixture used for harness path smoke. "
            "NOT a live LLM sample; do not report as verify@ / model metric."
            + (f" API error was: {api_error}" if api_error else "")
        )
        meta["temperature"] = None

    stem = raw_result_stem(task["id"], locked_model, prompt_id, sample_index, repair_round)
    out_json = RESULTS_RAW / f"{stem}.json"
    meta["raw_text"] = cleaned
    write_json(out_json, meta)
    ext = ".dfy" if task["target"] == "dafny" else ".lean"
    out_src = RESULTS_RAW / f"{stem}{ext}"
    from common import assert_write_allowed

    assert_write_allowed(out_src)
    out_src.write_text(cleaned, encoding="utf-8")
    meta["raw_json"] = str(out_json)
    meta["raw_source"] = str(out_src)
    return meta


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH run_generate")
    p.add_argument("--task", required=True, help="task id or path to YAML")
    p.add_argument("--prompt", default="P0", choices=["P0", "P1", "P2"])
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--sample-index", type=int, default=0)
    p.add_argument("--repair-round", type=int, default=0)
    p.add_argument("--temperature", type=float, default=0.0)
    p.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--backend", default="anthropic", choices=["anthropic", "fixture"])
    p.add_argument("--previous-source", default="")
    p.add_argument("--verifier-stderr", default="")
    args = p.parse_args(argv)

    task_arg = Path(args.task)
    if task_arg.suffix.lower() in {".yaml", ".yml"} and task_arg.is_file():
        task_path = task_arg
    else:
        task_path = TASKS_DIR / f"{args.task}.yaml"
        if not task_path.is_file():
            print(f"task not found: {task_path}", file=sys.stderr)
            return 2

    try:
        meta = generate_one(
            task_path,
            prompt_id=args.prompt,
            model=args.model,
            sample_index=args.sample_index,
            repair_round=args.repair_round,
            temperature=args.temperature,
            max_tokens=args.max_tokens,
            previous_source=args.previous_source,
            verifier_stderr=args.verifier_stderr,
            dry_run=args.dry_run,
            backend=args.backend,
        )
    except Exception as exc:
        print(f"[run_generate] FAIL: {exc}", file=sys.stderr)
        return 1
    print(json.dumps({k: v for k, v in meta.items() if k != "raw_text"}, ensure_ascii=False, indent=2))
    if meta.get("raw_text"):
        print(f"[run_generate] raw_text_chars={len(meta['raw_text'])}")
    return 0


if __name__ == "__main__":
    # allow `python run_generate.py` from harness/ without package install
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
