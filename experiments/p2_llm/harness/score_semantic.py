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

# A.17.16: strip line comments + fold paren-balanced wraps before matching.
# Without this, trailing Chinese comments and multi-line ensures defeat token match.
_CONTRACT_RE = re.compile(
    r"\b(requires|ensures|decreases|invariant|reads|modifies)\b([^;{]*)",
    re.I | re.S,
)


def normalize_dafny_text(text: str) -> str:
    """Strip // comments, then collapse paren-balanced newlines to spaces."""
    no_line_comments: list[str] = []
    for line in text.splitlines():
        in_str = False
        out: list[str] = []
        i = 0
        while i < len(line):
            ch = line[i]
            if ch == '"' and (i == 0 or line[i - 1] != "\\"):
                in_str = not in_str
                out.append(ch)
                i += 1
                continue
            if not in_str and ch == "/" and i + 1 < len(line) and line[i + 1] == "/":
                break
            out.append(ch)
            i += 1
        no_line_comments.append("".join(out))
    s = "\n".join(no_line_comments)
    # Drop /* ... */ block comments (non-greedy, non-nested — enough for GPB).
    s = re.sub(r"/\*.*?\*/", " ", s, flags=re.S)
    # Fold newlines that sit inside unmatched parentheses.
    out_chars: list[str] = []
    depth = 0
    for ch in s:
        if ch == "(":
            depth += 1
            out_chars.append(ch)
        elif ch == ")":
            depth = max(0, depth - 1)
            out_chars.append(ch)
        elif ch in "\r\n" and depth > 0:
            out_chars.append(" ")
        else:
            out_chars.append(ch)
    collapsed = "".join(out_chars)
    return re.sub(r"[ \t]{2,}", " ", collapsed)


def extract_contract_clauses(text: str) -> list[str]:
    norm = normalize_dafny_text(text)
    return [m.group(0).strip() for m in _CONTRACT_RE.finditer(norm)]


def clause_token_overlap(gen_text: str, gold_text: str) -> dict[str, Any]:
    """Overlap of alphanumeric tokens in requires/ensures after normalization."""
    stop = {
        "requires",
        "ensures",
        "decreases",
        "invariant",
        "reads",
        "modifies",
        "true",
        "false",
        "real",
        "int",
        "nat",
        "bool",
        "seq",
        "set",
        "map",
        "this",
        "result",
    }

    def toks(clauses: list[str]) -> set[str]:
        bag: set[str] = set()
        for c in clauses:
            for t in re.findall(r"[A-Za-z_][A-Za-z0-9_]{2,}", c.lower()):
                if t not in stop:
                    bag.add(t)
        return bag

    gen_c = extract_contract_clauses(gen_text)
    gold_c = extract_contract_clauses(gold_text)
    gset, oset = toks(gen_c), toks(gold_c)
    if not oset:
        ratio = 0.0
        inter: set[str] = set()
    else:
        inter = gset & oset
        ratio = len(inter) / len(oset)
    return {
        "n_gen_clauses": len(gen_c),
        "n_gold_clauses": len(gold_c),
        "gen_clause_tokens": sorted(gset)[:60],
        "gold_clause_tokens": sorted(oset)[:60],
        "overlap": sorted(inter)[:60],
        "overlap_ratio": round(ratio, 4),
        "normalized_preview_gen": normalize_dafny_text(gen_text)[:400],
    }


def extract_names(text: str) -> set[str]:
    names: set[str] = set()
    norm = normalize_dafny_text(text)
    for pat in LEMMA_PATTERNS:
        names.update(pat.findall(norm))
    return {n for n in names if len(n) >= 3}


def keyword_hits(spec: str, generated: str) -> dict[str, Any]:
    # Lightweight tokens from natural_spec; match against *normalized* generated.
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
        "merely",
        "asymptotically",
    }
    keywords = sorted({t for t in tokens if t not in stop})[:40]
    gen_l = normalize_dafny_text(generated).lower()
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
    gen_norm = normalize_dafny_text(generated_text)
    gold_norm = normalize_dafny_text(gold_text)
    gen_names = extract_names(generated_text)
    gold_names = extract_names(gold_text)
    name_overlap = sorted(gen_names & gold_names)
    kw = keyword_hits(str(task.get("natural_spec", "")), generated_text)
    clauses = clause_token_overlap(generated_text, gold_text)

    # Flags — never claim PASS verify without toolchain rc
    verified = verify_rc == 0 and not timed_out
    compile_ok = compile_rc == 0 and not timed_out
    # assume/axiom only count outside comments (A.17.16)
    trivial_assume = bool(re.search(r"\b(assume|axiom)\b", gen_norm, re.I))
    emptyish = len(generated_text.strip()) < 40

    # Heuristic drift suspicion (human must confirm F7)
    drift_suspect = False
    if verified and task.get("expected_verdict") == "NEG":
        if not re.search(r"witness|counter|negat|not\s+imply|≠|!=", gen_norm, re.I):
            drift_suspect = True
    if verified and trivial_assume:
        drift_suspect = True

    # Alignment signal: natural_spec keywords OR gold contract-token overlap.
    # Thresholds unchanged for keyword path; clause path is the A.17.16 fix for
    # multi-line ensures that keyword prose never sees.
    aligned_signal = kw["hit_ratio"] >= 0.35 or (
        clauses["n_gold_clauses"] > 0 and clauses["overlap_ratio"] >= 0.45
    )

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
    elif verified and aligned_signal:
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
        "clause_overlap": clauses,
        "normalized_used": True,
        "trivial_assume": trivial_assume,
        "drift_suspect": drift_suspect,
        "fidelity_label": fidelity_label,
        "note": (
            "Heuristic only (A.17.16 normalized). F7 semantic drift requires human "
            "adjudication. Do not treat LIKELY_ALIGNED as paper-ready fidelity. "
            "NEEDS_HUMAN remaining after normalize still need PI judgment."
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
