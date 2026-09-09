"""Generate P2_AIMATH summary figures from a results JSON (offline-safe).

Expected input schema (flexible):
{
  "cells": [ { "difficulty", "model", "prompt_id", "verify_ok", "compile_ok",
               "repair_round", "failure_codes": ["F1", ...] }, ... ]
  OR "rows": [ ... same ... ]
}

Honesty: if cells empty / all fixture, figures still render with zeros and a
watermark note in the JSON sidecar — never invent verify@ rates.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

from common import RESULTS_RAW, write_json

FIG_DIR = RESULTS_RAW.parent / "figures"


def _cells(payload: dict[str, Any]) -> list[dict[str, Any]]:
    for key in ("cells", "rows", "samples"):
        v = payload.get(key)
        if isinstance(v, list):
            return [c for c in v if isinstance(c, dict)]
    return []


def _is_fixture(cell: dict[str, Any]) -> bool:
    m = str(cell.get("model", "")).lower()
    return "fixture" in m or cell.get("status") == "GENERATED_FIXTURE"


def _rate(ok: list[bool]) -> float:
    if not ok:
        return 0.0
    return sum(1 for x in ok if x) / len(ok)


def build_aggregates(cells: list[dict[str, Any]]) -> dict[str, Any]:
    live = [c for c in cells if not _is_fixture(c)]
    by_diff: dict[str, list[bool]] = defaultdict(list)
    by_model: dict[str, list[bool]] = defaultdict(list)
    repair_curve: dict[int, list[bool]] = defaultdict(list)
    fail_counts: Counter[str] = Counter()

    for c in live:
        v = bool(c.get("verify_ok") or c.get("verify_rc") == 0)
        d = str(c.get("difficulty") or "UNK")
        m = str(c.get("model") or "UNK")
        by_diff[d].append(v)
        by_model[m].append(v)
        rr = int(c.get("repair_round") or 0)
        repair_curve[rr].append(v)
        for code in c.get("failure_codes") or []:
            fail_counts[str(code)] += 1

    return {
        "n_cells_total": len(cells),
        "n_live": len(live),
        "n_fixture_excluded": len(cells) - len(live),
        "verify_by_difficulty": {k: _rate(v) for k, v in sorted(by_diff.items())},
        "n_by_difficulty": {k: len(v) for k, v in sorted(by_diff.items())},
        "verify_by_model": {k: _rate(v) for k, v in sorted(by_model.items())},
        "n_by_model": {k: len(v) for k, v in sorted(by_model.items())},
        "verify_by_repair_round": {str(k): _rate(v) for k, v in sorted(repair_curve.items())},
        "failure_counts": dict(fail_counts),
        "note": "Rates are 0 when n_live=0; not paper metrics.",
    }


def _bar(ax, labels: list[str], values: list[float], title: str, ylabel: str) -> None:
    ax.bar(labels, values, color="#4C78A8")
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.set_ylim(0, 1.05)
    ax.tick_params(axis="x", rotation=30)
    for i, v in enumerate(values):
        ax.text(i, v + 0.02, f"{v:.2f}", ha="center", fontsize=8)


def make_figures(agg: dict[str, Any], out_dir: Path) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []

    # 1 difficulty stratified
    fig, ax = plt.subplots(figsize=(6, 4))
    labs = list(agg["verify_by_difficulty"].keys()) or ["L1", "L2", "L3"]
    vals = [agg["verify_by_difficulty"].get(k, 0.0) for k in labs]
    if not agg["verify_by_difficulty"]:
        labs, vals = ["L1", "L2", "L3"], [0.0, 0.0, 0.0]
    _bar(ax, labs, vals, "verify rate by difficulty (live only)", "verify rate")
    p = out_dir / "fig_difficulty_bars.png"
    fig.tight_layout()
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths.append(p)

    # 2 model compare
    fig, ax = plt.subplots(figsize=(7, 4))
    labs = list(agg["verify_by_model"].keys()) or ["(no-live)"]
    vals = [agg["verify_by_model"].get(k, 0.0) for k in labs]
    if not agg["verify_by_model"]:
        labs, vals = ["(no-live)"], [0.0]
    _bar(ax, labs, vals, "verify rate by model (live only)", "verify rate")
    p = out_dir / "fig_model_compare.png"
    fig.tight_layout()
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths.append(p)

    # 3 repair gain curve
    fig, ax = plt.subplots(figsize=(6, 4))
    rmap = agg["verify_by_repair_round"]
    if rmap:
        xs = sorted(int(k) for k in rmap)
        ys = [rmap[str(x)] for x in xs]
    else:
        xs, ys = [0, 1, 2, 3], [0.0, 0.0, 0.0, 0.0]
    ax.plot(xs, ys, marker="o", color="#F58518")
    ax.set_xlabel("repair_round")
    ax.set_ylabel("verify rate")
    ax.set_ylim(0, 1.05)
    ax.set_title("repair curve (verify vs round)")
    p = out_dir / "fig_repair_gain.png"
    fig.tight_layout()
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths.append(p)

    # 4 failure taxonomy
    fig, ax = plt.subplots(figsize=(7, 4))
    codes = [f"F{i}" for i in range(1, 9)]
    counts = [int(agg["failure_counts"].get(c, 0)) for c in codes]
    ax.bar(codes, counts, color="#E45756")
    ax.set_title("failure taxonomy counts (annotated)")
    ax.set_ylabel("count")
    p = out_dir / "fig_failure_taxonomy.png"
    fig.tight_layout()
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths.append(p)

    return paths


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH make_figures")
    p.add_argument("--input", required=True, help="results JSON with cells/rows")
    p.add_argument("--out-dir", default=str(FIG_DIR))
    args = p.parse_args(argv)

    payload = json.loads(Path(args.input).read_text(encoding="utf-8"))
    cells = _cells(payload)
    agg = build_aggregates(cells)
    out_dir = Path(args.out_dir)
    paths = make_figures(agg, out_dir)
    side = out_dir / "figures_aggregate.json"
    write_json(side, {**agg, "outputs": [str(x) for x in paths]})
    print(json.dumps({"n_live": agg["n_live"], "outputs": [str(x) for x in paths]}, indent=2))
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
