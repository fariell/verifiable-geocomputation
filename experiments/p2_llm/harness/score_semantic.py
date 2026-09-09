"""Heuristic semantic-fidelity scoring vs gold_formal (not a substitute for human F7)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from common import (
    GOLD_EXCERPT_FOR_SCORE_MAX,
    REPO_ROOT,
    RESULTS_SCORED,
    load_task,
    read_text_capped,
    write_json,
)

LEMMA_PATTERNS = [
    re.compile(r"\blemma\s+(\w+)", re.I),
    re.compile(r"\btheorem\s+(\w+)", re.I),
    re.compile(r"\bdef\s+(\w+)", re.I),
    re.compile(r"\bfunction\s+(\w+)", re.I),
]


def extract_names(text: str) -> set[str]:
    names: set[str] = set()
    for pat in LEMMA_PATTERNS:
        names.update(pat.findall(text))
    return {n for n in names if len(n) >= 3}


def keyword_hits(spec: str, generated: str) -> dict[str, Any]:
    # Lightweight tokens from natural_spec
    tokens = re.findall(r"[A-Za-z][A-Za-z0-9_-]{3,}", spec.lower())
    stop = {
        "that",
        "with",
        "from",
        "this",
        "must",
        "have",
        "when",
        "into",
        "under",
        "after",
        "before",
        "same",
        "each",
        "only",
        "than",
        "then",
        "also",
        "does",
        "were",
        "been",
        "formalize",
        "prove",
        "lemma",
        "theorem",
    }
    keywords = sorted({t for t in tokens if t not in stop})[:40]
    gen_l = generated.lower()
    hit = [k for k in keywords if k in gen_l]
    miss = [k for k in keywords if k not in gen_l]
    ratio = (len(hit) / len(keywords)) if keywords else 0.0
    return {"keywords": keywords, "hit": hit, "miss": miss, "hit_ratio": round(ratio, 4)}


def score_pair(
    *,
    task: dict[str, Any],
    generated_text: str,
    verify_rc: int | None,
    compile_rc: int | None,
    timed_out: bool = False,
) -> dict[str, Any]:
    gold_path = REPO_ROOT / task["gold_formal"]
    gold_text = (
        read_text_capped(gold_path, GOLD_EXCERPT_FOR_SCORE_MAX) if gold_path.is_file() else ""
    )
    gen_names = extract_names(generated_text)
    gold_names = extract_names(gold_text)
    name_overlap = sorted(gen_names & gold_names)
    kw = keyword_hits(str(task.get("natural_spec", "")), generated_text)

    # Flags — never claim PASS verify without toolchain rc
    verified = verify_rc == 0 and not timed_out
    compile_ok = compile_rc == 0 and not timed_out
    trivial_assume = bool(re.search(r"\bassume\b", generated_text, re.I))
    emptyish = len(generated_text.strip()) < 40

    # Heuristic drift suspicion (human must confirm F7)
    drift_suspect = False
    if verified and task.get("expected_verdict") == "NEG":
        if not re.search(r"witness|counter|negat|not\s+imply|≠|!=", generated_text, re.I):
            drift_suspect = True
    if verified and trivial_assume:
        drift_suspect = True

    fidelity_label = "UNKNOWN"
    if timed_out:
        fidelity_label = "TIMEOUT"
    elif emptyish:
        fidelity_label = "EMPTY"
    elif not compile_ok and compile_rc is not None:
        fidelity_label = "UNCOMPILED"
    elif verify_rc is None:
        fidelity_label = "VERIFY_SKIPPED"
    elif verified and drift_suspect:
        fidelity_label = "VERIFIED_BUT_DRIFT_SUSPECT"
    elif verified and kw["hit_ratio"] >= 0.35:
        fidelity_label = "LIKELY_ALIGNED"
    elif verified:
        fidelity_label = "VERIFIED_NEEDS_HUMAN"
    elif compile_ok:
        fidelity_label = "COMPILE_ONLY"
    else:
        fidelity_label = "FAILED"

    return {
        "task_id": task.get("id"),
        "expected_verdict": task.get("expected_verdict"),
        "compile_rc": compile_rc,
        "verify_rc": verify_rc,
        "timed_out": timed_out,
        "name_overlap": name_overlap,
        "n_gen_names": len(gen_names),
        "n_gold_names": len(gold_names),
        "keyword_hits": kw,
        "trivial_assume": trivial_assume,
        "drift_suspect": drift_suspect,
        "fidelity_label": fidelity_label,
        "note": (
            "Heuristic only. F7 semantic drift requires human adjudication. "
            "Do not treat LIKELY_ALIGNED as paper-ready fidelity."
        ),
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH score_semantic")
    p.add_argument("--task", required=True, help="path to task YAML")
    p.add_argument("--generated", required=True, help="path to generated source")
    p.add_argument("--compile-rc", type=int, default=-999)
    p.add_argument("--verify-rc", type=int, default=-999)
    p.add_argument("--out", default="")
    args = p.parse_args(argv)

    task = load_task(Path(args.task))
    gen = Path(args.generated).read_text(encoding="utf-8", errors="replace")
    compile_rc = None if args.compile_rc == -999 else args.compile_rc
    verify_rc = None if args.verify_rc == -999 else args.verify_rc
    score = score_pair(task=task, generated_text=gen, verify_rc=verify_rc, compile_rc=compile_rc)
    out = Path(args.out) if args.out else RESULTS_SCORED / f"{task['id']}.semantic.json"
    write_json(out, score)
    print(json.dumps(score, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
