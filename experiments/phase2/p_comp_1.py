#!/usr/bin/env python3
"""P-COMP-1 / GPB-021 entry: pit-fill then unique D8 basin.

Algebraic half: formal/dafny/PCOMP_1.dfy and
formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean.

  (i)   After W&L fill, every cell with a 4-neighbour has min(nbr) ≤ cell.
  (ii)  Plane A=1 B=0: each D8 step drops elevation by ≥ 1.
  (iii) 5×5 plane: every interior orbit terminates in ≤ 50 steps.

D8 / orbit kernels are imported from phase1 P-005 / P-006 — not copied.
W&L fill uses the same scalar rule as P-002-bis RaiseNbr (max(orig[n], fill[p])).
"""
from __future__ import annotations

import heapq
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

from p005_d8 import DIRS, d8_at, plane_grid
from p006_watershed import RING, RING_SUCC, follow_d8, follow_ring, pit_dem

NBR4 = ((-1, 0), (1, 0), (0, -1), (0, 1))


def out_dir() -> str:
    d = os.environ.get("GPB021_OUT", os.path.join(HERE, "results", "gpb021"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb021"), exist_ok=True)
    return d


def pit_fill_2d(h: np.ndarray) -> np.ndarray:
    """Wang & Liu 4-connected flood: boundary seeds, raise n to max(orig[n], fill[p])."""
    rows, cols = h.shape
    fill = np.full((rows, cols), np.inf, dtype=float)
    visited = np.zeros((rows, cols), dtype=bool)
    heap: list[tuple[float, int, int]] = []

    def seed(r: int, c: int) -> None:
        if visited[r, c]:
            return
        fill[r, c] = float(h[r, c])
        visited[r, c] = True
        heapq.heappush(heap, (fill[r, c], r, c))

    for r in range(rows):
        seed(r, 0)
        seed(r, cols - 1)
    for c in range(cols):
        seed(0, c)
        seed(rows - 1, c)

    while heap:
        _, pr, pc = heapq.heappop(heap)
        for dr, dc in NBR4:
            nr, nc = pr + dr, pc + dc
            if not (0 <= nr < rows and 0 <= nc < cols) or visited[nr, nc]:
                continue
            nv = max(float(h[nr, nc]), float(fill[pr, pc]))
            fill[nr, nc] = nv
            visited[nr, nc] = True
            heapq.heappush(heap, (nv, nr, nc))
    return fill


try:
    from p002_pit_filling_2d import pitFill2D  # type: ignore
except ImportError:
    pitFill2D = pit_fill_2d


def no_pit_implies_descent(filled: np.ndarray) -> tuple[bool, str]:
    rows, cols = filled.shape
    bad = 0
    checked = 0
    for r in range(rows):
        for c in range(cols):
            nbrs = []
            for dr, dc in NBR4:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols:
                    nbrs.append(float(filled[nr, nc]))
            if not nbrs:
                continue
            checked += 1
            if min(nbrs) > float(filled[r, c]) + 1e-12:
                bad += 1
    ok = bad == 0 and checked > 0
    return ok, "checked=%d pits=%d" % (checked, bad)


def strict_descent_plane(h: np.ndarray) -> tuple[bool, str]:
    drops = []
    for r in range(1, h.shape[0] - 1):
        for c in range(1, h.shape[1] - 1):
            d = d8_at(h, r, c)
            if d == "NoFlow":
                continue
            dp = dq = None
            for name, ddp, ddq, _dist2 in DIRS:
                if name == d:
                    dp, dq = ddp, ddq
                    break
            nr, nc = r + dq, c + dp
            drop = float(h[r, c]) - float(h[nr, nc])
            drops.append(drop)
    ok = len(drops) > 0 and all(x >= 1.0 - 1e-9 for x in drops)
    return ok, "n=%d min_drop=%s" % (
        len(drops),
        ("%.4f" % min(drops)) if drops else "na",
    )


def terminates_interior(h: np.ndarray, max_steps: int) -> tuple[bool, str]:
    n = 0
    term = 0
    longest = 0
    outlets = []
    for r in range(1, h.shape[0] - 1):
        for c in range(1, h.shape[1] - 1):
            n += 1
            ok, out, path = follow_d8(h, r, c, max_steps)
            longest = max(longest, len(path) - 1)
            if ok:
                term += 1
                outlets.append(out)
    passed = n > 0 and term == n and longest <= max_steps
    return passed, "n=%d term=%d longest=%d uniq_out=%d" % (
        n,
        term,
        longest,
        len(set(outlets)),
    )


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p_comp_1.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p_comp_1.wl"
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    try:
        proc = subprocess.run(
            [exe, "-file", wl],
            capture_output=True,
            text=True,
            timeout=90,
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
            "stdout": stdout[-2000:],
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
    path = os.path.join(dest, "p_comp_1_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p_comp_1_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "FillThenWatershedStencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("PCOMP1_MANIM", "0") != "1":
        print("  manim: skip (set PCOMP1_MANIM=1 to render)")
        print("  manim cmd:", info["cmd"])
        return info
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    except (OSError, subprocess.TimeoutExpired) as err:
        info["reason"] = str(err)
        print("  manim: skip (%s)" % err)
        return info
    info["returncode"] = proc.returncode
    info["rendered"] = proc.returncode == 0
    print("  manim rc=%s" % proc.returncode)
    if proc.returncode != 0:
        print((proc.stderr or proc.stdout or "")[-800:])
    else:
        src = os.path.join(
            dest, "videos", "p_comp_1_manim", "480p15", "FillThenWatershedStencil.mp4"
        )
        fig_dir = os.path.join(HERE, "figures")
        fig = os.path.join(fig_dir, "FillThenWatershedStencil.mp4")
        if os.path.isfile(src):
            os.makedirs(fig_dir, exist_ok=True)
            shutil.copy2(src, fig)
            info["figure"] = fig
            print("  manim copied ->", fig)
    return info


def gates(
    g1: tuple[bool, str],
    g2: tuple[bool, str],
    g3: tuple[bool, str],
    ring_term: bool,
) -> list:
    return [
        ("NoPitImpliesDescent after W&L fill", g1[0], g1[1]),
        ("StrictDescent plane A=1 each step drop>=1", g2[0], g2[1]),
        ("TerminatesUnderStrictDescent 5x5 interior <=50", g3[0], g3[1]),
        (
            "unfilled flat 4-ring does not terminate (P-006b contrast)",
            ring_term is False,
            "ring_terminated=%s" % ring_term,
        ),
    ]


def main() -> int:
    t0 = time.time()
    dest = out_dir()
    print("==[P-COMP-1] GPB-021 pit-fill then unique watershed ==")
    max_steps = 50

    print("---- (i) fill pit DEM, no remaining 4-neighbour pits ----")
    h_pit = pit_dem()
    h_filled = pitFill2D(h_pit)
    g1 = no_pit_implies_descent(h_filled)
    print("  fill min=%.3f max=%.3f  %s" % (h_filled.min(), h_filled.max(), g1[1]))

    print("---- (ii)(iii) plane A=1 B=0 n=5 ----")
    h_plane = plane_grid(1.0, 0.0, 12.0, n=5)
    g2 = strict_descent_plane(h_plane)
    g3 = terminates_interior(h_plane, max_steps)
    print("  strict descent:", g2[1])
    print("  terminate:", g3[1])

    print("---- contrast: unfilled P-006b ring ----")
    ring_term, ring_end, ring_path = follow_ring((0, 0), max_steps=8)
    print(
        "  start=(0,0) terminated=%s end=%s steps=%d"
        % (ring_term, ring_end, len(ring_path) - 1)
    )
    _ = RING, RING_SUCC

    print("---- wolframscript pigeonhole + descent maps ----")
    wolfram = eval_wolfram(dest)
    print("---- manim ----")
    manim_info = maybe_manim(dest)

    gs = gates(g1, g2, g3, ring_term)
    print("---- gates ----")
    ok = True
    for name, passed, detail in gs:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
        ok = ok and passed

    parsed = wolfram.get("parsed") or {}
    if wolfram.get("available"):
        w_ok = (
            parsed.get("pigeonholeAll") is True
            and parsed.get("descentAllFix") is True
            and parsed.get("ringHasFixedPoint") is False
        )
        print(
            "  [%s] wolfram pigeon + descent-fix + ring  (pigeon=%s descent=%s fixed=%s)"
            % (
                "PASS" if w_ok else "FAIL",
                parsed.get("pigeonholeAll"),
                parsed.get("descentAllFix"),
                parsed.get("ringHasFixedPoint"),
            )
        )
        ok = ok and w_ok
    elif shutil.which("wolframscript") or shutil.which("wolframscript.exe"):
        print(
            "  [FAIL] wolfram ran but did not parse  (rc=%s)"
            % wolfram.get("returncode")
        )
        ok = False
    else:
        print("  [SKIP] wolfram (not a fail; AutoDL has no wolframscript)")

    payload = {
        "id": "GPB-021",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "fill_min": float(h_filled.min()),
        "fill_max": float(h_filled.max()),
        "ring_terminated": ring_term,
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gs],
        "entry": "PASS" if ok else "FAIL",
        "note": (
            "P-COMP-1: W&L fill removes 4-neighbour pits; planar D8 strictly "
            "descends and terminates. Unfilled flat ring is the P-006b contrast."
        ),
    }
    for path in (
        os.path.join(dest, "gpb021_metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb021"), "gpb021_metrics.json")
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

    print("GPB-021 ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
