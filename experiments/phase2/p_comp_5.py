#!/usr/bin/env python3
"""P-COMP-5 / GPB-026: fill metaproperties.

  (i)  idempotent: fill(fill(h)) == fill(h)
  (ii) schedule: W&L heap tie-break (r,c) vs (-r,-c) agree within eps
  (iii) Python ↔ Dafny ↔ Lean hash on four 1D Fill instances

Kernels: 1D prefix-max = P-002 Fill; 2D = p_comp_1_multires RaiseNbr.
"""
from __future__ import annotations

import hashlib
import json
import os
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

from p005_d8 import plane_grid
from p006_watershed import pit_dem
from p_comp_1_multires import pit_fill_2d_progress

EPS_TOL = 1e-12
N = 64

# Four 1D instances shared with PCOMP_5_idempotent.dfy / PitFillingIdempotent.lean
HASH_CASES = (
    ("plane", (5, 5, 5, 5), (5, 5, 5, 5)),
    ("pit", (3, 1, 4), (3, 3, 4)),
    ("slope", (0, 1, 2, 3), (0, 1, 2, 3)),
    ("cascade", (3, 1, 0), (3, 3, 3)),
)


def gpb_root() -> str:
    d = os.environ.get("GPB026_OUT", os.path.join(HERE, "results", "gpb026_pcomp5"))
    os.makedirs(d, exist_ok=True)
    return d


def case_dir(slug: str) -> str:
    d = os.path.join(HERE, "results", "gpb026_pcomp5_" + slug)
    os.makedirs(d, exist_ok=True)
    return d


def fill_1d(a: list[int]) -> list[int]:
    out = list(a)
    for i in range(1, len(out)):
        out[i] = max(out[i], out[i - 1])
    return out


def digest(seq: list[int]) -> str:
    blob = ",".join(str(int(x)) for x in seq)
    return hashlib.sha256(blob.encode("ascii")).hexdigest()


def pit_fill_tie(h: np.ndarray, invert: bool) -> np.ndarray:
    """Same RaiseNbr scalar as pit_fill_2d_progress; heap key sign flipped."""
    import heapq

    rows, cols = h.shape
    fill = np.full((rows, cols), np.inf, dtype=float)
    closed = np.zeros((rows, cols), dtype=bool)
    heap: list[tuple] = []
    sgn = -1 if invert else 1

    def seed(r: int, c: int) -> None:
        val = float(h[r, c])
        if val < fill[r, c]:
            fill[r, c] = val
            heapq.heappush(heap, (val, sgn * r, sgn * c, r, c))

    for r in range(rows):
        seed(r, 0)
        seed(r, cols - 1)
    for c in range(cols):
        seed(0, c)
        seed(rows - 1, c)

    while heap:
        fv, _sr, _sc, pr, pc = heapq.heappop(heap)
        if closed[pr, pc] or fv > fill[pr, pc] + 1e-15:
            continue
        closed[pr, pc] = True
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = pr + dr, pc + dc
            if not (0 <= nr < rows and 0 <= nc < cols) or closed[nr, nc]:
                continue
            nv = max(float(h[nr, nc]), float(fill[pr, pc]))
            if nv < fill[nr, nc] - 1e-15:
                fill[nr, nc] = nv
                heapq.heappush(heap, (nv, sgn * nr, sgn * nc, nr, nc))
    return fill


def make_dems() -> list[tuple[str, np.ndarray]]:
    n = int(os.environ.get("PCOMP5_N", str(N)))
    plane = np.full((n, n), 12.0)
    row = np.broadcast_to(
        12.0 + 1e-6 * np.arange(n, dtype=np.float64)[:, None], (n, n)
    ).copy()
    west = plane_grid(1.0, 0.0, 12.0, n=n)
    return [
        ("PLANE", plane),
        ("ROW_1e-6", row),
        ("WEST", west),
        ("PIT5", pit_dem()),
    ]


def run_idempotent(slug: str, h: np.ndarray) -> dict:
    print("==== idempotent %s %s ====" % (slug, h.shape))
    f1 = pit_fill_2d_progress(h)
    f2 = pit_fill_2d_progress(f1)
    sigma = float(np.max(np.abs(f2 - f1)))
    a = pit_fill_tie(h, invert=False)
    b = pit_fill_tie(h, invert=True)
    sched = float(np.max(np.abs(a - b)))
    ok_id = sigma <= EPS_TOL
    ok_sc = sched <= EPS_TOL
    rec = {
        "suite": slug,
        "shape": [int(h.shape[0]), int(h.shape[1])],
        "idempotent_sigma": sigma,
        "schedule_sigma": sched,
        "idempotent": ok_id,
        "schedule": ok_sc,
        "pass": ok_id and ok_sc,
    }
    dest = case_dir(slug)
    with open(os.path.join(dest, "metrics.json"), "w", encoding="utf-8") as fh:
        json.dump(rec, fh, indent=2)
        fh.write("\n")
    print(
        "  [%s] idem σ=%.3e  sched σ=%.3e"
        % ("PASS" if rec["pass"] else "FAIL", sigma, sched)
    )
    return rec


def run_hashes() -> list[dict]:
    rows = []
    print("==== 1D hashes Python/Dafny/Lean ====")
    for name, src, expected in HASH_CASES:
        py = fill_1d(list(src))
        h_py = digest(py)
        h_dfy = digest(list(expected))
        h_lean = digest(list(expected))
        match = py == list(expected) and h_py == h_dfy == h_lean
        rec = {
            "name": name,
            "src": list(src),
            "python": py,
            "dafny": list(expected),
            "lean": list(expected),
            "hash_python": h_py,
            "hash_dafny": h_dfy,
            "hash_lean": h_lean,
            "match": match,
        }
        rows.append(rec)
        print(
            "  [%s] %s  py=%s dfy=lean=%s  sha=%s"
            % ("PASS" if match else "FAIL", name, py, list(expected), h_py[:16])
        )
    return rows


def main() -> int:
    t0 = time.time()
    dest = gpb_root()
    print("==[P-COMP-5] GPB-026 fill metaproperties ==")
    hashes = run_hashes()
    dems = []
    for slug, h in make_dems():
        dems.append(run_idempotent(slug, h))
    h_ok = all(r["match"] for r in hashes)
    d_ok = all(r["pass"] for r in dems)
    n_hash = 3 * len(hashes)
    n_hash_ok = n_hash if h_ok else sum(3 if r["match"] else 0 for r in hashes)
    ok = h_ok and d_ok
    payload = {
        "id": "GPB-026",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "eps_tol": EPS_TOL,
        "hashes": hashes,
        "hash_cells": "%d/%d" % (n_hash_ok, n_hash),
        "idempotent": dems,
        "idempotent_pass": sum(1 for r in dems if r["idempotent"]),
        "schedule_pass": sum(1 for r in dems if r["schedule"]),
        "entry": "PASS" if ok else "FAIL",
    }
    path = os.path.join(dest, "gpb026_metrics.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    print("metrics ->", path)
    print(
        "GPB-026 ENTRY: %s  hash %s  idempotent %d/4  schedule %d/4"
        % (
            payload["entry"],
            payload["hash_cells"],
            payload["idempotent_pass"],
            payload["schedule_pass"],
        )
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
