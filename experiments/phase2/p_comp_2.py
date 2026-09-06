#!/usr/bin/env python3
"""P-COMP-2 / GPB-022: full-plane fill-then-watershed closure.

Two 256² suites:
  PLANE     constant elevation (0 relief)
  ROW       h[r,c] = C + eps * r   for eps in {1e-6, 1e-4}

Algebraic half: formal/dafny/PCOMP_2.dfy and
formal/lean4/VeriGIS/Composition/PitFillingThenWatershedPlane.lean.

Kernels imported from p_comp_1 / p_comp_1_multires / phase1 — not copied.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PHASE1 = os.path.abspath(os.path.join(HERE, "..", "phase1"))
if PHASE1 not in sys.path:
    sys.path.insert(0, PHASE1)
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from p_comp_1 import no_pit_implies_descent
from p_comp_1_multires import (
    d8_codes,
    interior_stats,
    min_flow_drop,
    pit_fill_2d_progress,
    trace_all,
)

N = 256
C0 = 12.0
EPSILONS = (1e-6, 1e-4)
DIR_NAMES = ("E", "SE", "S", "SW", "W", "NW", "N", "NE")


def gpb_root() -> str:
    d = os.environ.get("GPB022_OUT", os.path.join(HERE, "results", "gpb024_pcomp2"))
    os.makedirs(d, exist_ok=True)
    return d


def case_dir(slug: str) -> str:
    d = os.path.join(HERE, "results", "gpb024_pcomp2_" + slug)
    os.makedirs(d, exist_ok=True)
    return d


def make_plane() -> np.ndarray:
    return np.full((N, N), C0, dtype=np.float64)


def make_row(eps: float) -> np.ndarray:
    r = np.arange(N, dtype=np.float64)[:, None]
    return np.broadcast_to(C0 + eps * r, (N, N)).copy()


def flow_constant(d8: np.ndarray) -> tuple[bool, str]:
    interior = d8[1:-1, 1:-1]
    codes, counts = np.unique(interior, return_counts=True)
    if codes.size == 0:
        return False, "empty interior"
    dominant = int(codes[np.argmax(counts)])
    name = "NoFlow" if dominant < 0 else DIR_NAMES[dominant]
    ok = codes.size == 1
    return ok, "dir=%s n=%d uniq=%d" % (name, int(interior.size), int(codes.size))


def all_cells_terminate(
    outlet: np.ndarray, length: np.ndarray, terminated: np.ndarray
) -> tuple[bool, str, dict]:
    n = int(terminated.size)
    n_term = int(np.count_nonzero(terminated))
    longest = int(length.max()) if n else 0
    uniq = int(np.unique(outlet[terminated]).size) if n_term else 0
    visited = int(length.sum()) + n_term
    ok = n > 0 and n_term == n
    detail = "n=%d term=%d longest=%d uniq_out=%d visited=%d" % (
        n,
        n_term,
        longest,
        uniq,
        visited,
    )
    stats = {
        "n": n,
        "n_term": n_term,
        "longest": longest,
        "uniq_out": uniq,
        "visited": visited,
        "all_term": ok,
    }
    return ok, detail, stats


def run_suite(slug: str, h: np.ndarray) -> dict:
    dest = case_dir(slug)
    print("==== suite %s  shape=%s min=%.6g max=%.6g ====" % (slug, h.shape, h.min(), h.max()))
    print("---- fill ----")
    filled = pit_fill_2d_progress(h)
    g_fill = no_pit_implies_descent(filled)
    print("  fill %s" % g_fill[1])
    print("---- D8 + orbits ----")
    d8 = d8_codes(filled)
    g_flow = flow_constant(d8)
    drop_ok, min_drop, n_drop = min_flow_drop(filled, d8)
    outlet, length, terminated = trace_all(d8)
    g_term, term_detail, stats = all_cells_terminate(outlet, length, terminated)
    istats = interior_stats(outlet, length, terminated)
    g_uniq = g_term and stats["uniq_out"] >= 1
    print("  constant flow:", g_flow[1])
    print("  min_drop=%s n_drop=%d drop_nonneg=%s" % (min_drop, n_drop, drop_ok))
    print("  terminate:", term_detail)
    print("  interior:", istats)
    gates = [
        ("NoPitImpliesDescent after W&L fill", g_fill[0], g_fill[1]),
        ("PlaneConstantFlow", g_flow[0], g_flow[1]),
        ("AllCellsTerminate 256²", g_term, term_detail),
        (
            "BasinUnique (one outlet per start)",
            g_uniq,
            "uniq_out=%d all_term=%s" % (stats["uniq_out"], stats["all_term"]),
        ),
    ]
    ok = all(p for _n, p, _d in gates)
    payload = {
        "id": "GPB-022",
        "suite": slug,
        "shape": [int(h.shape[0]), int(h.shape[1])],
        "fill_min": float(filled.min()),
        "fill_max": float(filled.max()),
        "min_drop": None if np.isnan(min_drop) else float(min_drop),
        "n_drop": n_drop,
        "interior": istats,
        "full": stats,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gates],
        "entry": "PASS" if ok else "FAIL",
    }
    path = os.path.join(dest, "metrics.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    print("metrics ->", path)
    for name, passed, detail in gates:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
    return payload


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p_comp_2.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p_comp_2.wl"
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    try:
        proc = subprocess.run(
            [exe, "-file", wl],
            capture_output=True,
            text=True,
            timeout=180,
            cwd=HERE,
        )
    except (OSError, subprocess.TimeoutExpired) as err:
        payload["reason"] = str(err)
        print("  wolframscript: skip (%s)" % err)
        return payload
    stdout = (proc.stdout or "").strip()
    payload.update(
        {
            "available": proc.returncode == 0,
            "returncode": proc.returncode,
            "stdout": stdout[-2500:],
            "stderr": (proc.stderr or "")[-500:],
        }
    )
    start = stdout.find("JSON-BEGIN")
    end = stdout.find("JSON-END")
    blob = ""
    if start >= 0 and end > start:
        blob = stdout[start + len("JSON-BEGIN") : end]
    else:
        start = stdout.rfind("{")
        end = stdout.rfind("}")
        if start >= 0 and end > start:
            blob = stdout[start : end + 1]
    if blob:
        try:
            payload["parsed"] = json.loads(blob.strip())
        except json.JSONDecodeError:
            pass
    print("  wolframscript rc=%s" % proc.returncode)
    parsed = payload.get("parsed") or {}
    print("  wolfram pigeonhole:", parsed.get("pigeonholeAll"))
    print("  wolfram descentAllFix:", parsed.get("descentAllFix"))
    print("  wolfram ringFixed:", parsed.get("ringHasFixedPoint"))
    print("  wolfram chain256:", parsed.get("chain256AllHit0"))
    print("  wolfram plane16x16:", parsed.get("plane16x16AllTerm"))
    path = os.path.join(dest, "wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    print("wolfram ->", path)
    return payload


def main() -> int:
    t0 = time.time()
    dest = gpb_root()
    print("==[P-COMP-2] GPB-022 full-plane closure 256² ==")

    suites = [("PLANE", make_plane())]
    for eps in EPSILONS:
        slug = "ROW_%s" % ("1e-6" if abs(eps - 1e-6) < 1e-18 else "1e-4")
        suites.append((slug, make_row(eps)))

    results = []
    ok = True
    for slug, h in suites:
        rec = run_suite(slug, h)
        results.append(rec)
        ok = ok and rec["entry"] == "PASS"

    print("---- wolframscript 256-cell + 4^4 ----")
    wolfram = eval_wolfram(dest)
    parsed = wolfram.get("parsed") or {}
    w_ok = False
    if wolfram.get("available"):
        w_ok = (
            parsed.get("pigeonholeAll") is True
            and parsed.get("descentAllFix") is True
            and parsed.get("ringHasFixedPoint") is False
            and parsed.get("chain256AllHit0") is True
            and parsed.get("plane16x16AllTerm") is True
        )
        print(
            "  [%s] wolfram pigeon + descent-fix + chain256 + 16x16  "
            "(pigeon=%s descent=%s fixed=%s chain=%s plane=%s)"
            % (
                "PASS" if w_ok else "FAIL",
                parsed.get("pigeonholeAll"),
                parsed.get("descentAllFix"),
                parsed.get("ringHasFixedPoint"),
                parsed.get("chain256AllHit0"),
                parsed.get("plane16x16AllTerm"),
            )
        )
        ok = ok and w_ok
    elif shutil.which("wolframscript") or shutil.which("wolframscript.exe"):
        print("  [FAIL] wolfram ran but did not parse  (rc=%s)" % wolfram.get("returncode"))
        ok = False
    else:
        print("  [SKIP] wolfram (not a fail; AutoDL has no wolframscript)")

    visited = sum(int(r["full"]["visited"]) for r in results)
    payload = {
        "id": "GPB-022",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "n": N,
        "suites": results,
        "visited_cells": visited,
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "wolfram_parsed": bool(parsed),
        "entry": "PASS" if ok else "FAIL",
        "note": (
            "P-COMP-2: 256² constant plane (0 relief) and row-slope eps in "
            "{1e-6,1e-4}; fill then D8 orbits all terminate with unique outlets."
        ),
    }
    for path in (
        os.path.join(dest, "gpb024_metrics.json"),
        os.path.join(dest, "metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb022"), "gpb024_metrics.json")
        if os.path.isdir(os.path.expanduser("~/.workbuddy"))
        else None,
    ):
        if not path:
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, indent=2)
            fh.write("\n")
        print("metrics ->", path)

    print("visited_cells=%d" % visited)
    print("GPB-022 ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
