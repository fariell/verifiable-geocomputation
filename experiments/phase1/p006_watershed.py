#!/usr/bin/env python3
"""P-006 / GPB-015 entry: watershed uniqueness under deterministic D8.

Algebraic half: formal/dafny/P006_watershed.dfy and
formal/lean4/VeriGIS/Watershed.lean.

  1. Planar slope: every interior orbit terminates; each cell has one outlet.
  2. Pit DEM: pit cells are NoFlow; remaining cells still have a unique outlet.
  3. Artificial flat 4-ring (P-006b): orbit exceeds the step bound (no fixed point).

D8 kernel is imported from p005_d8 — not copied.
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

from p005_d8 import DIRS, d8_at, plane_grid

HERE = os.path.dirname(os.path.abspath(__file__))

RING = ((0, 0), (0, 1), (1, 1), (1, 0))
RING_SUCC = {
    (0, 0): (0, 1),
    (0, 1): (1, 1),
    (1, 1): (1, 0),
    (1, 0): (0, 0),
}


def out_dir() -> str:
    d = os.environ.get("GPB006_OUT", os.path.join(HERE, "results", "gpb006"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb006"), exist_ok=True)
    return d


def _delta(name: str) -> tuple[int, int]:
    for dname, dp, dq, _dist2 in DIRS:
        if dname == name:
            return dp, dq
    raise KeyError(name)


def follow_d8(
    h: np.ndarray, r: int, c: int, max_steps: int
) -> tuple[bool, tuple[int, int], list[tuple[int, int]]]:
    path = [(r, c)]
    for _ in range(max_steps):
        d = d8_at(h, r, c)
        if d == "NoFlow":
            return True, (r, c), path
        dp, dq = _delta(d)
        nr, nc = r + dq, c + dp
        if not (0 <= nr < h.shape[0] and 0 <= nc < h.shape[1]):
            return True, (r, c), path
        r, c = nr, nc
        path.append((r, c))
        if len(path) != len(set(path)):
            return False, (r, c), path
    return False, (r, c), path


def follow_ring(
    start: tuple[int, int], max_steps: int
) -> tuple[bool, tuple[int, int], list[tuple[int, int]]]:
    cell = start
    path = [cell]
    for _ in range(max_steps):
        nxt = RING_SUCC[cell]
        if nxt == cell:
            return True, cell, path
        cell = nxt
        path.append(cell)
    return False, cell, path


def pit_dem() -> np.ndarray:
    h = np.ones((5, 5), dtype=float) * 5.0
    h[1:4, 1:4] = 4.0
    h[2, 2] = 0.0
    return h


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p006_watershed.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p006_watershed.wl"
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
    print("  wolfram ringFixed:", parsed.get("ringHasFixedPoint"))
    path = os.path.join(dest, "p006_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p006_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "WatershedStencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("P006_MANIM", "0") != "1":
        print("  manim: skip (set P006_MANIM=1 to render)")
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
    return info


def slope_report(h: np.ndarray, max_steps: int) -> tuple[list[bool], list[tuple[int, int]]]:
    terms: list[bool] = []
    outlets: list[tuple[int, int]] = []
    for r in range(1, h.shape[0] - 1):
        for c in range(1, h.shape[1] - 1):
            ok, out, _path = follow_d8(h, r, c, max_steps)
            terms.append(ok)
            outlets.append(out)
    return terms, outlets


def pit_report(h: np.ndarray, max_steps: int) -> tuple[str, list[tuple[int, int]], list[bool]]:
    pit_flow = d8_at(h, 2, 2)
    outlets: list[tuple[int, int]] = []
    terms: list[bool] = []
    rows, cols = h.shape
    for r in range(rows):
        for c in range(cols):
            if (r, c) == (2, 2):
                continue
            ok, out, _path = follow_d8(h, r, c, max_steps)
            terms.append(ok)
            outlets.append(out)
    return pit_flow, outlets, terms


def gates(
    slope_terms: list[bool],
    slope_outlets: list[tuple[int, int]],
    pit_flow: str,
    pit_outlets: list[tuple[int, int]],
    pit_terms: list[bool],
    ring_term: bool,
) -> list:
    by_cell_ok = len(slope_outlets) == len(slope_terms) and len(slope_terms) > 0
    return [
        (
            "slope interior 100% terminate + unique outlet per cell",
            by_cell_ok and all(slope_terms) and len(slope_outlets) == len(slope_terms),
            "n=%d term=%d uniq_outlets=%d"
            % (len(slope_terms), sum(slope_terms), len(set(slope_outlets))),
        ),
        (
            "pit centre NoFlow; other cells terminate with an outlet",
            pit_flow == "NoFlow" and all(pit_terms) and len(pit_outlets) > 0,
            "pit=%s others_term=%d/%d"
            % (pit_flow, sum(pit_terms), len(pit_terms)),
        ),
        (
            "flat 4-ring does not terminate (P-006b)",
            ring_term is False,
            "ring_terminated=%s" % ring_term,
        ),
    ]


def main() -> int:
    t0 = time.time()
    dest = out_dir()
    print("==[P-006] GPB-015 watershed uniqueness + flat-ring witness ==")
    max_steps = 32

    print("---- slope plane A>0 B=0 ----")
    h_slope = plane_grid(0.4, 0.0, 12.0, n=7)
    slope_terms, slope_outlets = slope_report(h_slope, max_steps)
    print(
        "  interior n=%d term=%d outlets=%s"
        % (len(slope_terms), sum(slope_terms), sorted(set(slope_outlets)))
    )

    print("---- pit 5x5 ----")
    h_pit = pit_dem()
    pit_flow, pit_outlets, pit_terms = pit_report(h_pit, max_steps)
    print(
        "  pit flow=%s others term=%d/%d outlets=%s"
        % (pit_flow, sum(pit_terms), len(pit_terms), sorted(set(pit_outlets)))
    )

    print("---- P-006b flat 4-ring ----")
    ring_term, ring_end, ring_path = follow_ring((0, 0), max_steps=8)
    print(
        "  start=(0,0) terminated=%s end=%s steps=%d"
        % (ring_term, ring_end, len(ring_path) - 1)
    )

    print("---- wolframscript pigeonhole + ring ----")
    wolfram = eval_wolfram(dest)
    print("---- manim ----")
    manim_info = maybe_manim(dest)

    gs = gates(slope_terms, slope_outlets, pit_flow, pit_outlets, pit_terms, ring_term)
    print("---- gates ----")
    ok = True
    for name, passed, detail in gs:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
        ok = ok and passed

    parsed = wolfram.get("parsed") or {}
    if wolfram.get("available"):
        w_ok = parsed.get("pigeonholeAll") is True and parsed.get("ringHasFixedPoint") is False
        print(
            "  [%s] wolfram pigeonhole + ring witness  (pigeon=%s fixed=%s)"
            % (
                "PASS" if w_ok else "FAIL",
                parsed.get("pigeonholeAll"),
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
        "id": "GPB-015",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "slope_n": len(slope_terms),
        "slope_term": int(sum(slope_terms)),
        "slope_outlets": [list(x) for x in sorted(set(slope_outlets))],
        "pit_flow": pit_flow,
        "pit_other_term": int(sum(pit_terms)),
        "ring_terminated": ring_term,
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gs],
        "entry": "PASS" if ok else "FAIL",
        "note": (
            "Layer A: deterministic D8 ⇒ unique outlet if the orbit terminates. "
            "Layer B / P-006b: constructed flat 4-cycle does not terminate."
        ),
    }
    for path in (
        os.path.join(dest, "gpb006_metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb006"), "gpb006_metrics.json")
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

    print("GPB-015 ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
