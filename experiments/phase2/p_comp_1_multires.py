#!/usr/bin/env python3
"""P-COMP-1 multi-resolution scale-out / GPB-024 directories.

Same fill + D8 + terminate algorithm as p_comp_1.py, four DEM sizes.
Formal kernels stay in PCOMP_1.dfy / T6 — this file only instantiates them.

  plane-5m      5×5    5 m   synthetic plane (P-COMP-1 baseline)
  terrain-A     256²   5 m   synthetic hill + pits + σ=5e-3
  SRTM-30m      3601²  30 m  USGS N32E110 if cached, else synthetic stand-in
  LiDAR-down    256²   5 m   1024² 1 m-like field block-mean → 256²
                             (real USGS TNM point cloud not in-repo)

Kernels imported from phase1 P-005 / P-006 and phase2 p_comp_1 — not copied.
"""
from __future__ import annotations

import gzip
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PHASE1 = os.path.abspath(os.path.join(HERE, "..", "phase1"))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
if PHASE1 not in sys.path:
    sys.path.insert(0, PHASE1)
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from p005_d8 import DIRS, plane_grid
from p006_watershed import follow_ring
from p_comp_1 import no_pit_implies_descent, pitFill2D

CACHE = os.path.join(REPO, "data", "cache")
SRTM_URLS = (
    "https://s3.amazonaws.com/elevation-tiles-prod/skadi/N32/N32E110.hgt.gz",
    "https://elevation-tiles-prod.s3.amazonaws.com/skadi/N32/N32E110.hgt.gz",
)
HGT_BYTES = 3601 * 3601 * 2

def pit_fill_2d_progress(h: np.ndarray) -> np.ndarray:
    """Wang & Liu 4-connected priority flood (P-002 RaiseNbr scalar).

    The first-touch queue in p_comp_1.pit_fill_2d is enough on the 5×5 pit DEM
    (equal seeds). A sloped grid must let a later, lower spill path decrease
    fill[n]: closed-on-pop, extra heap pushes. Same rule: max(orig[n], fill[p]).
    """
    import heapq

    rows, cols = h.shape
    fill = np.full((rows, cols), np.inf, dtype=float)
    closed = np.zeros((rows, cols), dtype=bool)
    heap: list[tuple[float, int, int]] = []

    def seed(r: int, c: int) -> None:
        val = float(h[r, c])
        if val < fill[r, c]:
            fill[r, c] = val
            heapq.heappush(heap, (val, r, c))

    for r in range(rows):
        seed(r, 0)
        seed(r, cols - 1)
    for c in range(cols):
        seed(0, c)
        seed(rows - 1, c)

    n = rows * cols
    popped = 0
    mark = max(n // 8, 1)
    while heap:
        fv, pr, pc = heapq.heappop(heap)
        if closed[pr, pc] or fv > fill[pr, pc] + 1e-15:
            continue
        closed[pr, pc] = True
        popped += 1
        if popped % mark == 0:
            print(
                "  fill progress closed=%d/%d heap=%d" % (popped, n, len(heap)),
                flush=True,
            )
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = pr + dr, pc + dc
            if not (0 <= nr < rows and 0 <= nc < cols) or closed[nr, nc]:
                continue
            nv = max(float(h[nr, nc]), float(fill[pr, pc]))
            if nv < fill[nr, nc] - 1e-15:
                fill[nr, nc] = nv
                heapq.heappush(heap, (nv, nr, nc))
    return fill


DIR_OFF = [(dq, dp) for _name, dp, dq, _d2 in DIRS]


def gpb_root() -> str:
    d = os.environ.get("GPB024_OUT", os.path.join(HERE, "results", "gpb024"))
    os.makedirs(d, exist_ok=True)
    return d


def case_dir(slug: str) -> str:
    d = os.path.join(HERE, "results", "gpb024_" + slug)
    os.makedirs(d, exist_ok=True)
    return d


def coarsen_mean(h: np.ndarray, out_n: int) -> np.ndarray:
    rows, cols = h.shape
    if rows < out_n or cols < out_n:
        return np.asarray(h, dtype=float)
    fr = rows // out_n
    fc = cols // out_n
    rr, cc = out_n * fr, out_n * fc
    block = h[:rr, :cc].reshape(out_n, fr, out_n, fc)
    return block.mean(axis=(1, 3))


def count_pits4(h: np.ndarray, interior: bool = False) -> int:
    inf = np.inf
    up = np.empty_like(h)
    down = np.empty_like(h)
    left = np.empty_like(h)
    right = np.empty_like(h)
    up[0, :] = inf
    up[1:, :] = h[:-1, :]
    down[-1, :] = inf
    down[:-1, :] = h[1:, :]
    left[:, 0] = inf
    left[:, 1:] = h[:, :-1]
    right[:, -1] = inf
    right[:, :-1] = h[:, 1:]
    mn = np.minimum(np.minimum(up, down), np.minimum(left, right))
    pit = mn > h + 1e-12
    if interior:
        pit[0, :] = False
        pit[-1, :] = False
        pit[:, 0] = False
        pit[:, -1] = False
    return int(np.sum(pit))


def d8_codes(h: np.ndarray) -> np.ndarray:
    rows, cols = h.shape
    best_p = np.zeros((rows, cols), dtype=np.float64)
    best_d = np.full((rows, cols), -1, dtype=np.int8)
    for idx, (_name, dp, dq, dist2) in enumerate(DIRS):
        sr0, sr1 = max(0, -dq), min(rows, rows - dq)
        sc0, sc1 = max(0, -dp), min(cols, cols - dp)
        drop = h[sr0:sr1, sc0:sc1] - h[sr0 + dq : sr1 + dq, sc0 + dp : sc1 + dp]
        p = (drop * drop) / dist2
        ok = drop > 0.0
        region_p = best_p[sr0:sr1, sc0:sc1]
        region_d = best_d[sr0:sr1, sc0:sc1]
        better = ok & ((region_d < 0) | (p > region_p))
        region_p[better] = p[better]
        region_d[better] = np.int8(idx)
    return best_d


def min_flow_drop(h: np.ndarray, d8: np.ndarray) -> tuple[bool, float, int]:
    chunks = []
    rows, cols = h.shape
    for idx, (_name, dp, dq, _d2) in enumerate(DIRS):
        rr, cc = np.nonzero(d8 == idx)
        if rr.size == 0:
            continue
        nr, nc = rr + dq, cc + dp
        valid = (nr >= 0) & (nr < rows) & (nc >= 0) & (nc < cols)
        if not np.any(valid):
            continue
        chunks.append(h[rr[valid], cc[valid]] - h[nr[valid], nc[valid]])
    if not chunks:
        return True, float("nan"), 0
    drops = np.concatenate(chunks)
    return bool(np.all(drops > -1e-12)), float(drops.min()), int(drops.size)


def trace_all(d8: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rows, cols = d8.shape
    n = rows * cols
    succ = np.full(n, -1, dtype=np.int32)
    for idx, (dq, dp) in enumerate(DIR_OFF):
        rr, cc = np.nonzero(d8 == idx)
        if rr.size == 0:
            continue
        nr, nc = rr + dq, cc + dp
        valid = (nr >= 0) & (nr < rows) & (nc >= 0) & (nc < cols)
        succ[rr[valid] * cols + cc[valid]] = nr[valid] * cols + nc[valid]
    outlet = np.full(n, -1, dtype=np.int32)
    length = np.zeros(n, dtype=np.int32)
    terminated = np.zeros(n, dtype=bool)
    state = np.zeros(n, dtype=np.uint8)
    DONE, WALKING = 2, 1
    for start in range(n):
        if state[start] == DONE:
            continue
        path: list[int] = []
        cur = int(start)
        while True:
            if state[cur] == DONE:
                for k, node in enumerate(reversed(path)):
                    outlet[node] = outlet[cur]
                    length[node] = length[cur] + 1 + k
                    terminated[node] = terminated[cur]
                    state[node] = DONE
                break
            if state[cur] == WALKING:
                cyc_at = path.index(cur)
                for node in path[cyc_at:]:
                    outlet[node] = node
                    length[node] = 0
                    terminated[node] = False
                    state[node] = DONE
                for k, node in enumerate(reversed(path[:cyc_at])):
                    outlet[node] = outlet[cur]
                    length[node] = length[cur] + 1 + k
                    terminated[node] = False
                    state[node] = DONE
                break
            state[cur] = WALKING
            path.append(cur)
            nxt = int(succ[cur])
            if nxt < 0:
                outlet[cur] = cur
                length[cur] = 0
                terminated[cur] = True
                state[cur] = DONE
                for k, node in enumerate(reversed(path[:-1])):
                    outlet[node] = cur
                    length[node] = k + 1
                    terminated[node] = True
                    state[node] = DONE
                break
            cur = nxt
    return outlet.reshape(rows, cols), length.reshape(rows, cols), terminated.reshape(
        rows, cols
    )


def interior_stats(
    outlet: np.ndarray, length: np.ndarray, terminated: np.ndarray
) -> dict:
    rows, cols = terminated.shape
    ir = slice(1, rows - 1)
    ic = slice(1, cols - 1)
    term = terminated[ir, ic]
    leng = length[ir, ic]
    out = outlet[ir, ic]
    n = int(term.size)
    n_term = int(np.count_nonzero(term))
    longest = int(leng.max()) if n else 0
    uniq = int(np.unique(out[term]).size) if n_term else 0
    return {
        "n": n,
        "n_term": n_term,
        "longest": longest,
        "uniq_out": uniq,
        "all_term": n > 0 and n_term == n,
    }


def make_plane() -> tuple[np.ndarray, dict]:
    h = plane_grid(1.0, 0.0, 12.0, n=5)
    return h, {"source": "synthetic plane A=1 B=0", "cell_m": 5.0, "sigma": 0.0}


def make_terrain_a() -> tuple[np.ndarray, dict]:
    rng = np.random.default_rng(20260906)
    n = 256
    y, x = np.mgrid[0:n, 0:n].astype(float)
    h = 0.05 * x + 0.02 * y
    h += 12.0 * np.exp(-((x - 80.0) ** 2 + (y - 90.0) ** 2) / (2.0 * 40.0**2))
    h += 7.5 * np.exp(-((x - 180.0) ** 2 + (y - 170.0) ** 2) / (2.0 * 28.0**2))
    pits = (
        (36, 40, 2.4),
        (48, 200, 1.8),
        (70, 90, 1.6),
        (96, 24, 2.1),
        (110, 150, 1.7),
        (128, 128, 2.8),
        (140, 210, 1.5),
        (160, 60, 2.0),
        (188, 40, 1.9),
        (200, 180, 2.2),
        (220, 110, 1.4),
        (232, 230, 1.6),
    )
    for r, c, depth in pits:
        h[r, c] -= depth
        h[r - 1 : r + 2, c - 1 : c + 2] -= 0.15 * depth
    h += rng.normal(0.0, 5e-3, size=h.shape)
    return h, {
        "source": "synthetic terrain-A (hill+12 pits+sigma=5e-3); phase1 raster absent",
        "cell_m": 5.0,
        "sigma": 5e-3,
        "seed": 20260906,
    }


def _load_hgt(path: str) -> np.ndarray | None:
    raw = open(path, "rb").read()
    if len(raw) != HGT_BYTES:
        return None
    z = np.frombuffer(raw, dtype=">i2").reshape(3601, 3601).astype(np.float64)
    nodata = z == -32768
    if np.any(nodata):
        fill = float(np.nanmedian(np.where(nodata, np.nan, z)))
        z[nodata] = fill
    return z


def make_srtm() -> tuple[np.ndarray, dict]:
    os.makedirs(CACHE, exist_ok=True)
    hgt = os.path.join(CACHE, "N32E110.hgt")
    gz_path = os.path.join(CACHE, "N32E110.hgt.gz")
    if os.path.isfile(hgt) and os.path.getsize(hgt) == HGT_BYTES:
        z = _load_hgt(hgt)
        if z is not None:
            return z, {
                "source": "USGS SRTMGL1 N32E110 (local cache)",
                "cell_m": 30.0,
                "sigma": 0.0,
                "tile": "N32E110",
            }
    if os.path.isfile(gz_path) and os.path.getsize(gz_path) > 100000:
        with gzip.open(gz_path, "rb") as fh:
            blob = fh.read()
        if len(blob) == HGT_BYTES:
            open(hgt, "wb").write(blob)
            z = _load_hgt(hgt)
            if z is not None:
                return z, {
                    "source": "USGS SRTMGL1 N32E110 (gunzip cache)",
                    "cell_m": 30.0,
                    "sigma": 0.0,
                    "tile": "N32E110",
                }
    if os.environ.get("VERIGIS_SKIP_SRTM", "0") == "1":
        print("  SRTM fetch skipped (VERIGIS_SKIP_SRTM=1)")
    else:
        for url in SRTM_URLS:
            try:
                print("  SRTM fetch", url)
                req = urllib.request.Request(url, headers={"User-Agent": "verigis-task9"})
                with urllib.request.urlopen(req, timeout=8) as resp, open(gz_path, "wb") as out:
                    while True:
                        chunk = resp.read(1024 * 1024)
                        if not chunk:
                            break
                        out.write(chunk)
            except OSError as err:
                print("  SRTM fetch fail:", err)
                continue
            try:
                with gzip.open(gz_path, "rb") as fh:
                    blob = fh.read()
            except OSError as err:
                print("  SRTM gunzip fail:", err)
                continue
            if len(blob) != HGT_BYTES:
                print("  SRTM unexpected size", len(blob))
                continue
            open(hgt, "wb").write(blob)
            z = _load_hgt(hgt)
            if z is not None:
                return z, {
                    "source": "USGS SRTMGL1 N32E110 (downloaded)",
                    "cell_m": 30.0,
                    "sigma": 0.0,
                    "tile": "N32E110",
                    "url": url,
                }
    print("  SRTM tile missing → synthetic 3601² stand-in (same shape/cell size)")
    y, x = np.ogrid[0:3601, 0:3601]
    xf = x.astype(float)
    yf = y.astype(float)
    rng = np.random.default_rng(11032)
    h = (
        1180.0
        + 0.035 * (3600.0 - xf)
        + 85.0 * np.sin(xf / 180.0)
        + 55.0 * np.cos(yf / 220.0)
        + 25.0 * np.sin((xf + yf) / 95.0)
    )
    h = h + rng.normal(0.0, 1.6, size=(3601, 3601))
    return h, {
        "source": "synthetic SRTM-scale stand-in (N32E110 download unavailable)",
        "cell_m": 30.0,
        "sigma": 1.6,
        "tile": "SYNTHETIC_3601",
    }


def make_lidar_down() -> tuple[np.ndarray, dict]:
    rng = np.random.default_rng(20260906 + 1)
    n = 1024
    y, x = np.mgrid[0:n, 0:n].astype(float)
    h = 0.04 * x + 0.015 * y
    h += 4.0 * np.sin(x / 18.0) * np.cos(y / 22.0)
    h += 1.2 * np.sin(x / 3.5) + 0.8 * np.cos(y / 4.2)
    h += rng.normal(0.0, 0.25, size=h.shape)
    down = coarsen_mean(h, 256)
    return down, {
        "source": "synthetic 1024² 1m-like field, 4×4 mean → 256² (no USGS TNM in repo)",
        "cell_m": 4.0,
        "sigma": 0.25,
        "seed": 20260907,
        "fine_n": 1024,
    }


def save_csv(path: str, arr: np.ndarray) -> None:
    np.savetxt(path, arr, delimiter=",", fmt="%.6f")


def save_panel_png(path: str, h: np.ndarray, title: str) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    view = coarsen_mean(h, min(32, h.shape[0]))
    fig, ax = plt.subplots(figsize=(3.2, 3.2), dpi=120)
    ax.imshow(view, cmap="terrain", origin="upper")
    ax.set_title(title, fontsize=9)
    ax.set_xticks([])
    ax.set_yticks([])
    fig.tight_layout()
    fig.savefig(path)
    plt.close(fig)


def evaluate_case(slug: str, name: str, h: np.ndarray, meta: dict, max_steps: int) -> dict:
    dest = case_dir(slug)
    t0 = time.time()
    print("==[%s] %s  shape=%s cell_m=%s ==" % (slug, name, h.shape, meta.get("cell_m")))
    n_pit = count_pits4(h, interior=True)
    n_pit_all = count_pits4(h, interior=False)
    print("  pits before fill: interior=%d all=%d" % (n_pit, n_pit_all))
    filled = pitFill2D(h) if h.shape == (5, 5) else pit_fill_2d_progress(h)
    pits_after = count_pits4(filled, interior=True)
    pits_after_all = count_pits4(filled, interior=False)
    if h.shape == (5, 5):
        g1_ok, g1_detail = no_pit_implies_descent(filled)
    else:
        g1_ok = pits_after == 0
        g1_detail = "interior_checked=%d pits=%d (boundary_localmin=%d)" % (
            int((h.shape[0] - 2) * (h.shape[1] - 2)),
            pits_after,
            pits_after_all - pits_after,
        )
    print("  fill min=%.3f max=%.3f  %s  pits_after_interior=%d" % (
        filled.min(), filled.max(), g1_detail, pits_after
    ))
    d8 = d8_codes(filled)
    drop_ok, min_drop, n_flow = min_flow_drop(filled, d8)
    if slug == "PLANE":
        drop_gate = bool(drop_ok and (np.isnan(min_drop) or min_drop >= 1.0 - 1e-9))
        drop_name = "StrictDescent plane A=1 each step drop>=1"
    else:
        drop_gate = bool(drop_ok and (n_flow == 0 or min_drop > -1e-12))
        drop_name = "flowing D8 steps strictly descend (drop>0)"
    drop_detail = "n_flow=%d min_drop=%s" % (
        n_flow,
        "na" if np.isnan(min_drop) else ("%.4f" % min_drop),
    )
    print("  descent:", drop_detail)
    outlet, length, terminated = trace_all(d8)
    st = interior_stats(outlet, length, terminated)
    term_ok = bool(st["all_term"] and st["longest"] <= max_steps)
    term_detail = "n=%d term=%d longest=%d uniq_out=%d bound=%d" % (
        st["n"],
        st["n_term"],
        st["longest"],
        st["uniq_out"],
        max_steps,
    )
    print("  terminate:", term_detail)
    ring_term, ring_end, ring_path = follow_ring((0, 0), max_steps=8)
    ring_ok = ring_term is False
    print(
        "  ring contrast: terminated=%s end=%s steps=%d"
        % (ring_term, ring_end, len(ring_path) - 1)
    )
    gates = [
        ("NoPitImpliesDescent after W&L fill", g1_ok and pits_after == 0, g1_detail),
        (drop_name, drop_gate, drop_detail),
        ("TerminatesUnderStrictDescent interior", term_ok, term_detail),
        (
            "unfilled flat 4-ring does not terminate (P-006b contrast)",
            ring_ok,
            "ring_terminated=%s" % ring_term,
        ),
    ]
    ok = True
    print("---- gates %s ----" % slug)
    for gname, passed, detail in gates:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", gname, detail))
        ok = ok and passed
    coarsen_n = 8 if min(h.shape) <= 256 else 16
    if min(h.shape) < coarsen_n:
        coarsen_n = int(min(h.shape))
    coarse = coarsen_mean(filled, coarsen_n)
    root = gpb_root()
    csv_name = "%s_%d.csv" % (slug, coarsen_n)
    save_csv(os.path.join(root, csv_name), coarse)
    png = os.path.join(root, "%s_panel.png" % slug)
    save_panel_png(png, filled, "%s %sx%s" % (name, h.shape[0], h.shape[1]))
    payload = {
        "id": "GPB-024",
        "slug": slug,
        "name": name,
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "shape": [int(h.shape[0]), int(h.shape[1])],
        "n_cells": int(h.size),
        "n_pit": n_pit,
        "n_pit_after": pits_after,
        "n_term": st["n_term"],
        "uniq_out": st["uniq_out"],
        "longest": st["longest"],
        "max_steps": max_steps,
        "min_drop": None if np.isnan(min_drop) else float(min_drop),
        "meta": meta,
        "coarsen_csv": csv_name,
        "panel_png": png,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gates],
        "entry": "PASS" if ok else "FAIL",
    }
    mpath = os.path.join(dest, "metrics.json")
    with open(mpath, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    print("metrics ->", mpath)
    return payload


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p_comp_1_multires.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    try:
        proc = subprocess.run(
            [exe, "-file", wl],
            capture_output=True,
            text=True,
            timeout=180,
            cwd=HERE,
            env={**os.environ, "GPB024_OUT": dest},
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
    path = os.path.join(dest, "p_comp_1_multires_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p_comp_1_multires_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "FillThenWatershedMultiresStencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("PCOMP1_MULTIRES_MANIM", os.environ.get("PCOMP1_MANIM", "0")) != "1":
        print("  manim: skip (set PCOMP1_MULTIRES_MANIM=1 to render)")
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
            dest,
            "videos",
            "p_comp_1_multires_manim",
            "480p15",
            "FillThenWatershedMultiresStencil.mp4",
        )
        fig_dir = os.path.join(HERE, "figures")
        os.makedirs(fig_dir, exist_ok=True)
        for name in ("FillThenWatershedMultiresStencil.mp4", "MultiresFillThenWatershed.mp4"):
            fig = os.path.join(fig_dir, name)
            if os.path.isfile(src):
                shutil.copy2(src, fig)
                info["figure"] = fig
                print("  manim copied ->", fig)
    return info


def main() -> int:
    t0 = time.time()
    root = gpb_root()
    print("==[P-COMP-1 multi-res] GPB-024 scale-out ==")
    cases = [
        ("PLANE", "plane-5m", make_plane, 50),
        ("TERRAIN_A", "terrain-A", make_terrain_a, 256 * 256),
        ("SRTM_30M", "SRTM-30m", make_srtm, 3601 * 3601),
        ("LIDAR", "LiDAR-down", make_lidar_down, 256 * 256),
    ]
    records = []
    all_ok = True
    for slug, name, factory, bound in cases:
        h, meta = factory()
        rec = evaluate_case(slug, name, h, meta, bound)
        records.append(rec)
        all_ok = all_ok and rec["entry"] == "PASS"

    print("---- wolframscript coarsened + 4^4 orbits ----")
    wolfram = eval_wolfram(root)
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
        all_ok = all_ok and w_ok
    elif shutil.which("wolframscript") or shutil.which("wolframscript.exe"):
        print("  [FAIL] wolfram ran but did not parse  (rc=%s)" % wolfram.get("returncode"))
        all_ok = False
    else:
        print("  [SKIP] wolfram (not a fail; AutoDL has no wolframscript)")

    print("---- manim ----")
    manim_info = maybe_manim(root)

    combined = {
        "id": "GPB-024",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "cases": records,
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "entry": "PASS" if all_ok else "FAIL",
        "note": (
            "P-COMP-1 multi-res: same fill+D8+terminate on 4 DEM sizes. "
            "Formal lemmas do not mention grid size."
        ),
    }
    for path in (
        os.path.join(root, "metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb024"), "metrics.json")
        if os.path.isdir(os.path.expanduser("~/.workbuddy"))
        else None,
    ):
        if not path:
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(combined, fh, indent=2)
            fh.write("\n")
        print("metrics ->", path)

    print("GPB-024 ENTRY:", "PASS" if all_ok else "FAIL")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
