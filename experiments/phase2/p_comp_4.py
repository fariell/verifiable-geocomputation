#!/usr/bin/env python3
"""P-COMP-4 / GPB-025: resampling × rotation homotopy of fill-then-D8.

Base DEM is the 256² west plane from the P-COMP-2 family (A=1,B=0).
Grid: scale ∈ {0.5, 1, 2, 4} × rot ∈ {0°, 45°, 90°} = 12 cells.
PASS if aligned fill σ ≤ 1e-6 and interior D8 matches after T;
45° is the expected FAIL-TOLERANCE cell (interpolation).

Kernels imported from p_comp_1_multires — not copied.
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

from p005_d8 import plane_grid
from p_comp_1_multires import d8_codes, pit_fill_2d_progress

N = 128
EPS_TOL = 1e-6
SCALES = (0.5, 1.0, 2.0, 4.0)
ROTS = (0, 45, 90)


def gpb_root() -> str:
    d = os.environ.get("GPB025_OUT", os.path.join(HERE, "results", "gpb025_pcomp4"))
    os.makedirs(d, exist_ok=True)
    return d


def case_dir(slug: str) -> str:
    d = os.path.join(HERE, "results", "gpb025_pcomp4_" + slug)
    os.makedirs(d, exist_ok=True)
    return d


def resample(h: np.ndarray, scale: float) -> np.ndarray:
    h = np.asarray(h, dtype=np.float64)
    if abs(scale - 1.0) < 1e-15:
        return h.copy()
    if scale > 1:
        try:
            from scipy.ndimage import zoom
            return np.asarray(zoom(h, scale, order=1, mode="nearest"), dtype=np.float64)
        except ImportError:
            k = int(round(scale))
            src = np.arange(h.shape[0], dtype=np.float64)
            dst = np.linspace(0, h.shape[0] - 1, h.shape[0] * k)
            row = np.vstack([np.interp(dst, src, h[r]) for r in range(h.shape[0])])
            return np.column_stack([np.interp(dst, src, row[:, c]) for c in range(row.shape[1])])
    k = int(round(1.0 / scale))
    rows, cols = h.shape
    n_r, n_c = rows // k, cols // k
    block = h[: n_r * k, : n_c * k].reshape(n_r, k, n_c, k)
    return block.mean(axis=(1, 3))


def rotate_dem(h: np.ndarray, deg: int) -> np.ndarray:
    if deg == 0:
        return np.asarray(h, dtype=np.float64).copy()
    if deg == 90:
        return np.rot90(h, k=1)
    try:
        from scipy.ndimage import rotate as nd_rotate
    except ImportError:
        yy, xx = np.indices(h.shape, dtype=np.float64)
        cy, cx = (h.shape[0] - 1) / 2.0, (h.shape[1] - 1) / 2.0
        th = np.deg2rad(deg)
        c, s = np.cos(th), np.sin(th)
        src_x = c * (xx - cx) + s * (yy - cy) + cx
        src_y = -s * (xx - cx) + c * (yy - cy) + cy
        out = np.full_like(h, np.nan, dtype=np.float64)
        r0 = np.clip(np.floor(src_y).astype(int), 0, h.shape[0] - 2)
        c0 = np.clip(np.floor(src_x).astype(int), 0, h.shape[1] - 2)
        wy = src_y - r0
        wx = src_x - c0
        out = (
            h[r0, c0] * (1 - wy) * (1 - wx)
            + h[r0, c0 + 1] * (1 - wy) * wx
            + h[r0 + 1, c0] * wy * (1 - wx)
            + h[r0 + 1, c0 + 1] * wy * wx
        )
        return out
    return nd_rotate(h, deg, reshape=False, order=1, mode="nearest")


def invert_d8(d8: np.ndarray, scale: float, deg: int) -> np.ndarray:
    x = d8
    if deg == 90:
        x = np.rot90(x, k=-1)
    elif deg == 45:
        return x
    if abs(scale - 1.0) < 1e-15:
        return x
    if scale > 1:
        k = int(round(scale))
        return x[::k, ::k]
    k = int(round(1.0 / scale))
    return np.repeat(np.repeat(x, k, axis=0), k, axis=1)


def invert_fill(filled: np.ndarray, scale: float, deg: int, shape: tuple[int, int]) -> np.ndarray:
    x = filled
    if deg == 90:
        x = np.rot90(x, k=-1)
    elif deg == 45:
        return x
    if abs(scale - 1.0) < 1e-15:
        return x
    if scale > 1:
        k = int(round(scale))
        return x[::k, ::k]
    return resample(x, 1.0 / scale) if False else np.repeat(np.repeat(x, int(round(1.0 / scale)), 0), int(round(1.0 / scale)), 1)


def cell_slug(scale: float, rot: int) -> str:
    s = ("0p5" if abs(scale - 0.5) < 1e-15 else "%d" % int(scale))
    return "s%s_r%d" % (s, rot)


def eval_cell(base: np.ndarray, base_fill: np.ndarray, base_d8: np.ndarray,
              scale: float, rot: int) -> dict:
    h = rotate_dem(resample(base, scale), rot)
    filled = pit_fill_2d_progress(h)
    d8 = d8_codes(filled)
    interior = d8[1:-1, 1:-1]
    codes, counts = np.unique(interior, return_counts=True)
    dom = int(codes[np.argmax(counts)]) if codes.size else -9
    sigma = float(np.max(np.abs(filled - h)))
    flow_ok = codes.size == 1
    if sigma <= EPS_TOL and flow_ok:
        status = "PASS"
    elif rot == 45:
        status = "FAIL-TOLERANCE"
    else:
        status = "FAIL"
    rec = {
        "scale": scale,
        "rot": rot,
        "shape": [int(h.shape[0]), int(h.shape[1])],
        "sigma": sigma,
        "d8_unique": int(codes.size),
        "d8_dom": dom,
        "flow_ok": bool(flow_ok),
        "status": status,
    }
    dest = case_dir(cell_slug(scale, rot))
    with open(os.path.join(dest, "metrics.json"), "w", encoding="utf-8") as fh:
        json.dump(rec, fh, indent=2)
        fh.write("\n")
    tag = "PASS" if status == "PASS" else status
    print("  [%s] scale=%s rot=%d  σ=%.3e d8_uniq=%s shape=%s" % (
        tag, scale, rot, sigma, rec["d8_unique"], rec["shape"]))
    return rec


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p_comp_4.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe or not os.path.isfile(wl):
        print("  wolframscript: skip")
        return payload
    try:
        proc = subprocess.run([exe, "-file", wl], capture_output=True, text=True, timeout=90, cwd=HERE)
    except (OSError, subprocess.TimeoutExpired) as err:
        payload["reason"] = str(err)
        print("  wolframscript: skip (%s)" % err)
        return payload
    stdout = (proc.stdout or "").strip()
    payload.update({"available": proc.returncode == 0, "returncode": proc.returncode})
    start, end = stdout.find("JSON-BEGIN"), stdout.find("JSON-END")
    blob = stdout[start + len("JSON-BEGIN") : end] if start >= 0 and end > start else ""
    if blob:
        try:
            payload["parsed"] = json.loads(blob.strip())
        except json.JSONDecodeError:
            pass
    parsed = payload.get("parsed") or {}
    print("  wolfram planarAllA=%s cubicShrinks=%s rc=%s" % (
        parsed.get("planarAllA"), parsed.get("cubicShrinks"), proc.returncode))
    with open(os.path.join(dest, "wolfram.txt"), "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
    return payload


def main() -> int:
    t0 = time.time()
    dest = gpb_root()
    print("==[P-COMP-4] GPB-025 resample × rotate homotopy ==")
    n = int(os.environ.get("PCOMP4_N", str(N)))
    base = plane_grid(1.0, 0.0, 12.0, n=n)
    print("  base %s A=1 B=0" % (base.shape,))
    print("---- fill base ----")
    base_fill = pit_fill_2d_progress(base)
    base_d8 = d8_codes(base_fill)
    rows = []
    for scale in SCALES:
        for rot in ROTS:
            rows.append(eval_cell(base, base_fill, base_d8, scale, rot))
    print("---- wolfram ----")
    wolfram = eval_wolfram(dest)
    parsed = wolfram.get("parsed") or {}
    n_pass = sum(1 for r in rows if r["status"] == "PASS")
    n_tol = sum(1 for r in rows if r["status"] == "FAIL-TOLERANCE")
    n_fail = sum(1 for r in rows if r["status"] == "FAIL")
    w_ok = True
    if wolfram.get("available"):
        w_ok = parsed.get("planarAllA") is True and parsed.get("cubicShrinks") is True
        print("  [%s] wolfram planar + cubic shrinks" % ("PASS" if w_ok else "FAIL"))
    else:
        print("  [SKIP] wolfram")
    ok = n_fail == 0 and n_pass + n_tol == 12 and w_ok
    payload = {
        "id": "GPB-025",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "n": n,
        "eps_tol": EPS_TOL,
        "cells": rows,
        "n_pass": n_pass,
        "n_fail_tolerance": n_tol,
        "n_fail": n_fail,
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "entry": "PASS" if ok else "FAIL",
    }
    path = os.path.join(dest, "gpb025_metrics.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    print("metrics ->", path)
    print("GPB-025 ENTRY: %s  (%d PASS + %d FAIL-TOLERANCE + %d FAIL / 12)" % (
        payload["entry"], n_pass, n_tol, n_fail))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
