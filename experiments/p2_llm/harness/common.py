"""Shared helpers for P2_AIMATH harness (pathlib-first, Windows-safe)."""

from __future__ import annotations

import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml

try:
    import jsonschema
except ImportError:  # pragma: no cover
    jsonschema = None

REPO_ROOT = Path(__file__).resolve().parents[3]
P2_ROOT = REPO_ROOT / "experiments" / "p2_llm"
TASKS_DIR = P2_ROOT / "tasks"
PROMPTS_DIR = P2_ROOT / "prompts"
RESULTS_RAW = P2_ROOT / "results" / "raw"
RESULTS_SCORED = P2_ROOT / "results" / "scored"
HARNESS_DIR = Path(__file__).resolve().parent
SCHEMA_PATH = HARNESS_DIR / "schema_task.json"

FORMAL_DIR = REPO_ROOT / "formal"
FORBIDDEN_WRITE_PREFIXES = (
    REPO_ROOT / "formal",
    REPO_ROOT / "papers" / "P2",
    REPO_ROOT / "papers" / "P2-geoproofbench",
)

PROMPT_FILES = {
    "P0": PROMPTS_DIR / "P0_zero_shot.md",
    "P1": PROMPTS_DIR / "P1_few_shot.md",
    "P2": PROMPTS_DIR / "P2_repair.md",
}

REF_EXCERPT_MAX_CHARS = 4000
FEWSHOT_EXCERPT_MAX_CHARS = 3500
GOLD_EXCERPT_FOR_SCORE_MAX = 8000


def utc_today() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def load_schema() -> dict[str, Any]:
    with SCHEMA_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def load_task(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ValueError(f"task YAML must be a mapping: {path}")
    return data


def validate_task(task: dict[str, Any]) -> list[str]:
    """Return list of validation errors (empty = OK)."""
    errors: list[str] = []
    if jsonschema is None:
        errors.append("jsonschema not installed")
        return errors
    schema = load_schema()
    validator = jsonschema.Draft202012Validator(schema)
    for err in sorted(validator.iter_errors(task), key=lambda e: list(e.path)):
        errors.append(f"{list(err.path)}: {err.message}")
    for key in ("reference_impl", "gold_formal"):
        rel = task.get(key)
        if isinstance(rel, str):
            p = REPO_ROOT / rel
            if not p.is_file():
                errors.append(f"missing file for {key}: {rel}")
    return errors


def validate_all_tasks() -> dict[str, Any]:
    schema_ok = SCHEMA_PATH.is_file()
    rows = []
    for path in sorted(TASKS_DIR.glob("*.yaml")):
        task = load_task(path)
        errs = validate_task(task)
        rows.append({"file": path.name, "id": task.get("id"), "ok": not errs, "errors": errs})
    return {
        "schema_present": schema_ok,
        "n_tasks": len(rows),
        "n_ok": sum(1 for r in rows if r["ok"]),
        "rows": rows,
    }


def read_text_capped(path: Path, max_chars: int) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    if len(text) <= max_chars:
        return text
    half = max_chars // 2
    return (
        text[:half]
        + f"\n\n/* ... truncated by harness ({len(text)} chars total) ... */\n\n"
        + text[-half:]
    )


def assert_write_allowed(path: Path) -> None:
    resolved = path.resolve()
    for prefix in FORBIDDEN_WRITE_PREFIXES:
        try:
            resolved.relative_to(prefix.resolve())
            raise RuntimeError(f"harness refuse write under forbidden prefix: {prefix}")
        except ValueError:
            continue
    try:
        resolved.relative_to(RESULTS_RAW.resolve().parent)
    except ValueError as exc:
        raise RuntimeError(f"writes must stay under results/: {resolved}") from exc


def load_prompt_template(prompt_id: str) -> str:
    path = PROMPT_FILES[prompt_id]
    return path.read_text(encoding="utf-8")


def pick_fewshot(task: dict[str, Any]) -> tuple[str, str]:
    """Pick a non-homologous verified formal file for P1 few-shot."""
    family = task.get("prop_family")
    target = task["target"]
    gold = Path(task["gold_formal"]).as_posix()
    candidates: list[Path] = []
    for other_path in sorted(TASKS_DIR.glob("*.yaml")):
        other = load_task(other_path)
        if other.get("id") == task.get("id"):
            continue
        if other.get("target") != target:
            continue
        if family and other.get("prop_family") == family:
            continue
        other_gold = Path(other["gold_formal"]).as_posix()
        if other_gold == gold:
            continue
        p = REPO_ROOT / other["gold_formal"]
        if p.is_file():
            candidates.append(p)
    if not candidates:
        # fallback: any other gold of same target
        for other_path in sorted(TASKS_DIR.glob("*.yaml")):
            other = load_task(other_path)
            if other.get("id") == task.get("id"):
                continue
            if other.get("target") != target:
                continue
            p = REPO_ROOT / other["gold_formal"]
            if p.is_file() and Path(other["gold_formal"]).as_posix() != gold:
                candidates.append(p)
                break
    if not candidates:
        raise RuntimeError(f"no few-shot candidate for {task.get('id')}")
    chosen = candidates[0]
    rel = chosen.relative_to(REPO_ROOT).as_posix()
    return rel, read_text_capped(chosen, FEWSHOT_EXCERPT_MAX_CHARS)


def render_prompt(
    task: dict[str, Any],
    prompt_id: str,
    *,
    previous_source: str = "",
    verifier_stderr: str = "",
    repair_round: int = 0,
) -> str:
    tmpl = load_prompt_template(prompt_id)
    ref_path = REPO_ROOT / task["reference_impl"]
    ref_excerpt = read_text_capped(ref_path, REF_EXCERPT_MAX_CHARS) if ref_path.is_file() else ""
    fewshot_path, fewshot_excerpt = ("", "")
    if prompt_id == "P1":
        fewshot_path, fewshot_excerpt = pick_fewshot(task)
    filled = tmpl
    replacements = {
        "{{TARGET}}": str(task["target"]),
        "{{NATURAL_SPEC}}": str(task["natural_spec"]).strip(),
        "{{REFERENCE_IMPL}}": str(task["reference_impl"]),
        "{{REFERENCE_EXCERPT}}": ref_excerpt,
        "{{FEWSHOT_PATH}}": fewshot_path,
        "{{FEWSHOT_EXCERPT}}": fewshot_excerpt,
        "{{PREVIOUS_SOURCE}}": previous_source,
        "{{VERIFIER_STDERR}}": verifier_stderr[:4000],
        "{{REPAIR_ROUND}}": str(repair_round),
    }
    for k, v in replacements.items():
        filled = filled.replace(k, v)
    assert_no_gold_leak(filled, task)
    return filled


def assert_no_gold_leak(prompt_text: str, task: dict[str, Any]) -> None:
    """Hard gate: prompt must not contain gold_formal body (RISKS §8 #3)."""
    gold_path = REPO_ROOT / task["gold_formal"]
    if not gold_path.is_file():
        return
    gold = gold_path.read_text(encoding="utf-8", errors="replace")
    # Strip comments/headers; require a distinctive non-trivial contiguous chunk
    body_lines = [
        ln
        for ln in gold.splitlines()
        if ln.strip()
        and not ln.strip().startswith("//")
        and not ln.strip().startswith("--")
        and not ln.strip().startswith("/-")
    ]
    chunks = [ln.strip() for ln in body_lines if len(ln.strip()) >= 40]
    for chunk in chunks[:30]:
        if chunk in prompt_text:
            raise RuntimeError(
                f"GOLD LEAK: prompt contains gold_formal body chunk from {task['gold_formal']!r}"
            )


def strip_code_fences(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        t = re.sub(r"^```[a-zA-Z0-9_+-]*\n?", "", t)
        if t.endswith("```"):
            t = t[: -3]
    return t.strip() + "\n"


def raw_result_stem(
    task_id: str,
    model: str,
    prompt_id: str,
    sample_index: int,
    repair_round: int,
) -> str:
    safe_model = re.sub(r"[^a-zA-Z0-9._-]+", "_", model)
    return f"{task_id}__{safe_model}__{prompt_id}__k{sample_index}__r{repair_round}"


def write_json(path: Path, obj: dict[str, Any]) -> None:
    assert_write_allowed(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def which_tool(names: list[str]) -> str | None:
    path_env = os.environ.get("PATH", "")
    exts = [""]
    if os.name == "nt":
        exts = os.environ.get("PATHEXT", ".EXE;.BAT;.CMD").split(";")
    for directory in path_env.split(os.pathsep):
        if not directory:
            continue
        for name in names:
            for ext in exts:
                candidate = Path(directory) / f"{name}{ext}"
                if candidate.is_file():
                    return str(candidate)
    return None
