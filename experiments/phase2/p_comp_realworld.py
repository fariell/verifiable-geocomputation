#!/usr/bin/env python3
"""P-COMP-1 on three real public DEMs / GPB-027.

  lidar       USGS 3DEP 1 m (LiDAR-derived), Griffith Park, Los Angeles
  ifsar       USGS 3DEP 5 m (Alaska IFSAR), Fairbanks-area window
  copernicus  Copernicus DEM GLO-30 1" (~30 m), N32E110 COG

Kernels imported from p_comp_1_multires — not copied.
Staged USGS S3 COGs (prd-tnm) are recorded as tried; this host times out /
returns CONNECT 502, so LiDAR and IFSAR windows come from the official
3DEP ImageServer (same product families, windowed export). Copernicus is
the public AWS eu-central-1 GLO-30 COG via /vsicurl/.
"""
from __future__ import annotations

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

from osgeo import gdal

from p006_watershed import follow_ring
from p_comp_1_multires import (
    DIR_OFF,
    count_pits4,
    d8_codes,
    interior_stats,
    min_flow_drop,
    pit_fill_2d_progress,
    trace_all,
)

gdal.UseExceptions()
gdal.SetConfigOption("GDAL_HTTP_TIMEOUT", "60")
gdal.SetConfigOption("GDAL_HTTP_CONNECTTIMEOUT", "25")
gdal.SetConfigOption("CPL_VSIL_CURL_USE_HEAD", "NO")
gdal.SetConfigOption("GDAL_DISABLE_READDIR_ON_OPEN", "EMPTY_DIR")

CACHE = os.path.join(REPO, "data", "cache")
IMAGESERVER = (
    "https://elevation.nationalmap.gov/arcgis/rest/services/"
    "3DEPElevation/ImageServer/exportImage"
)
LIDAR_COG_TRIED = (
    "https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/1m/Projects/"
    "CA_LosAngeles_B23/TIFF/USGS_1M_11_x37y377_CA_LosAngeles_B23.tif"
)
IFSAR_COG_TRIED = (
    "https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/OPR/Projects/"
    "AK_IFSAR_2010/AK_IFSAR-Cell38_2010/TIFF/USGS_AK5M_AK_IFSAR_2010_49.tif"
)
COP_URL = (
    "https://copernicus-dem-30m.s3.eu-central-1.amazonaws.com/"
    "Copernicus_DSM_COG_10_N32_00_E110_00_DEM/"
    "Copernicus_DSM_COG_10_N32_00_E110_00_DEM.tif"
)

UA = {"User-Agent": "verigis-task13"}


def gpb_root() -> str:
    d = os.environ.get("GPB027_OUT", os.path.join(HERE, "results", "gpb027_realworld"))
    os.makedirs(d, exist_ok=True)
    return d


def case_dir(slug: str) -> str:
    d = os.path.join(gpb_root(), slug)
    os.makedirs(d, exist_ok=True)
    return d


def window_n() -> int:
    return int(os.environ.get("GPB027_N", "256"))


def _clean_elev(arr: np.ndarray, nodata) -> np.ndarray:
    z = np.asarray(arr, dtype=np.float64)
    bad = ~np.isfinite(z)
    if nodata is not None:
        bad |= z == float(nodata)
    bad |= z < -1.0e4
    bad |= z > 9.0e4
    if np.all(bad):
        raise RuntimeError("window is entirely nodata")
    if np.any(bad):
        fill = float(np.nanmedian(np.where(bad, np.nan, z)))
        z[bad] = fill
    return z


def _http_download(url: str, dest: str, timeout: int = 120) -> None:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as resp, open(dest, "wb") as out:
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            out.write(chunk)


def _read_gtiff(path: str) -> tuple[np.ndarray, list, str | None, object]:
    ds = gdal.Open(path)
    if ds is None:
        raise RuntimeError("gdal.Open failed: %s" % path)
    band = ds.GetRasterBand(1)
    arr = band.ReadAsArray()
    nodata = band.GetNoDataValue()
    gt = list(ds.GetGeoTransform())
    proj = ds.GetProjection() or None
    ds = None
    return _clean_elev(arr, nodata), gt, proj, nodata


def _meters_per_deg(lat_deg: float) -> tuple[float, float]:
    lat = np.deg2rad(lat_deg)
    m_lat = 111132.92 - 559.82 * np.cos(2 * lat) + 1.175 * np.cos(4 * lat)
    m_lon = 111412.84 * np.cos(lat) - 93.5 * np.cos(3 * lat)
    return float(m_lat), float(m_lon)


def fetch_3dep_window(
    slug: str,
    west: float,
    south: float,
    n: int,
    cell_m: float,
    product: str,
    staged_tried: str,
) -> tuple[np.ndarray, dict]:
    cache = os.path.join(CACHE, "gpb027_%s.tif" % slug)
    m_lat, m_lon = _meters_per_deg(south)
    dlat = (n * cell_m) / m_lat
    dlon = (n * cell_m) / m_lon
    east = west + dlon
    north = south + dlat
    bbox = (west, south, east, north)
    url = (
        "%s?bbox=%s,%s,%s,%s&bboxSR=4326&size=%d,%d"
        "&imageSR=4326&format=tiff&pixelType=F32"
        "&interpolation=RSP_NearestNeighbor&f=image"
        % (IMAGESERVER, west, south, east, north, n, n)
    )
    if not (os.path.isfile(cache) and os.path.getsize(cache) > 1000):
        print("  fetch 3DEP ImageServer", slug, "n=%d" % n, flush=True)
        try:
            _http_download(url, cache)
        except OSError as err:
            raise RuntimeError(
                "3DEP ImageServer download failed for %s: %s; staged COG tried %s"
                % (slug, err, staged_tried)
            ) from err
    h, gt, proj, nodata = _read_gtiff(cache)
    if h.shape != (n, n):
        raise RuntimeError("%s unexpected shape %s" % (slug, h.shape))
    px_m = abs(gt[1]) * m_lon
    py_m = abs(gt[5]) * m_lat
    return h, {
        "source": product,
        "fetch": "USGS 3DEP ImageServer exportImage (nearest)",
        "url": url,
        "staged_cog_tried": staged_tried,
        "staged_cog_note": (
            "prd-tnm S3 vsicurl: CONNECT 502 via proxy, timeout without proxy"
        ),
        "cache": cache,
        "cell_m": float(cell_m),
        "pixel_m_approx": [round(px_m, 3), round(py_m, 3)],
        "bbox_wgs84": [west, south, east, north],
        "geotransform": gt,
        "shape": [int(h.shape[0]), int(h.shape[1])],
        "zmin": float(h.min()),
        "zmax": float(h.max()),
        "synthetic": False,
    }


def fetch_copernicus(n: int) -> tuple[np.ndarray, dict]:
    cache = os.path.join(CACHE, "gpb027_copernicus.tif")
    xoff, yoff = 1600, 1600
    if not (os.path.isfile(cache) and os.path.getsize(cache) > 1000):
        print("  fetch Copernicus GLO-30 /vsicurl/ n=%d" % n, flush=True)
        src = "/vsicurl/" + COP_URL
        try:
            ds = gdal.Open(src)
        except RuntimeError as err:
            raise RuntimeError(
                "Copernicus GLO-30 vsicurl failed: %s; url=%s" % (err, COP_URL)
            ) from err
        os.makedirs(CACHE, exist_ok=True)
        gdal.Translate(cache, ds, srcWin=[xoff, yoff, n, n])
        ds = None
    h, gt, proj, nodata = _read_gtiff(cache)
    if h.shape[0] != n or h.shape[1] != n:
        raise RuntimeError("copernicus unexpected shape %s" % (h.shape,))
    lat = gt[3] + 0.5 * gt[5]
    m_lat, m_lon = _meters_per_deg(lat)
    cell_m = 0.5 * (abs(gt[1]) * m_lon + abs(gt[5]) * m_lat)
    return h, {
        "source": "Copernicus DEM GLO-30 (DSM COG 10, tile N32E110)",
        "fetch": "AWS eu-central-1 /vsicurl/ + GDAL Translate srcWin",
        "url": COP_URL,
        "cache": cache,
        "cell_m": float(cell_m),
        "srcWin": [xoff, yoff, n, n],
        "geotransform": gt,
        "shape": [int(h.shape[0]), int(h.shape[1])],
        "zmin": float(h.min()),
        "zmax": float(h.max()),
        "synthetic": False,
    }


def diversity_metrics(h: np.ndarray, d8: np.ndarray, cell_m: float) -> dict:
    """Ridgeline / drainage-density / sink-count proxies on the filled D8 field.

    sink_count: interior 4-neighbour pits on the *original* window (before fill).
    ridgeline_frac: interior cells with D8 in-degree 0 (drainage divides).
    drainage_density_per_m: (cells with in-degree >= 2) / (n_int * cell_m),
    i.e. channel-length / area with cell length as the length unit.
    """
    sink_count = count_pits4(h, interior=True)
    rows, cols = d8.shape
    indeg = np.zeros((rows, cols), dtype=np.int32)
    for idx, (dq, dp) in enumerate(DIR_OFF):
        rr, cc = np.nonzero(d8 == idx)
        if rr.size == 0:
            continue
        nr, nc = rr + dq, cc + dp
        valid = (nr >= 0) & (nr < rows) & (nc >= 0) & (nc < cols)
        np.add.at(indeg, (nr[valid], nc[valid]), 1)
    ir, ic = slice(1, rows - 1), slice(1, cols - 1)
    n_int = (rows - 2) * (cols - 2)
    ridge = indeg[ir, ic] == 0
    channel = indeg[ir, ic] >= 2
    return {
        "sink_count": sink_count,
        "ridgeline_frac": float(np.mean(ridge)),
        "n_ridge": int(np.sum(ridge)),
        "n_channel": int(np.sum(channel)),
        "drainage_density_per_m": float(np.sum(channel)) / (n_int * cell_m),
        "cell_m": float(cell_m),
        "in_degree": indeg,
    }


def save_panel_png(
    path: str,
    h: np.ndarray,
    pits: np.ndarray,
    title: str,
    stats: str,
) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(3.4, 3.6), dpi=120)
    im = ax.imshow(h, cmap="terrain", origin="upper")
    yy, xx = np.nonzero(pits)
    if yy.size:
        ax.scatter(xx, yy, s=4, c="crimson", marker=".", linewidths=0, label="sinks")
    ax.set_title(title, fontsize=9)
    ax.set_xticks([])
    ax.set_yticks([])
    ax.text(
        0.5,
        -0.08,
        stats,
        transform=ax.transAxes,
        ha="center",
        va="top",
        fontsize=7,
    )
    fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    fig.tight_layout()
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)


def evaluate_case(slug: str, name: str, h: np.ndarray, meta: dict) -> dict:
    dest = case_dir(slug)
    t0 = time.time()
    cell_m = float(meta["cell_m"])
    n = h.shape[0]
    max_steps = n * n
    print("==[%s] %s  shape=%s cell_m=%.3f ==" % (slug, name, h.shape, cell_m))
    if bool(meta.get("synthetic")):
        raise RuntimeError("%s is synthetic — task13 forbids stand-ins" % slug)

    n_pit = count_pits4(h, interior=True)
    n_pit_all = count_pits4(h, interior=False)
    print("  pits before fill: interior=%d all=%d" % (n_pit, n_pit_all))
    filled = pit_fill_2d_progress(h)
    pits_after = count_pits4(filled, interior=True)
    pits_after_all = count_pits4(filled, interior=False)
    g1_ok = pits_after == 0
    g1_detail = "interior_checked=%d pits=%d (boundary_localmin=%d)" % (
        int((n - 2) * (n - 2)),
        pits_after,
        pits_after_all - pits_after,
    )
    print("  fill min=%.3f max=%.3f  %s" % (filled.min(), filled.max(), g1_detail))

    d8 = d8_codes(filled)
    drop_ok, min_drop, n_flow = min_flow_drop(filled, d8)
    drop_gate = bool(drop_ok and (n_flow == 0 or min_drop > -1e-12))
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

    div = diversity_metrics(h, d8, cell_m)
    print(
        "  diversity: sinks=%d ridge_frac=%.4f Dd=%.6g /m"
        % (div["sink_count"], div["ridgeline_frac"], div["drainage_density_per_m"])
    )

    gates = [
        ("NoPitImpliesDescent after W&L fill", g1_ok and pits_after == 0, g1_detail),
        ("flowing D8 steps strictly descend (drop>=0)", drop_gate, drop_detail),
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

    pit_mask = np.zeros(h.shape, dtype=bool)
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
    pit_mask = np.minimum(np.minimum(up, down), np.minimum(left, right)) > h + 1e-12
    pit_mask[0, :] = False
    pit_mask[-1, :] = False
    pit_mask[:, 0] = False
    pit_mask[:, -1] = False

    png = os.path.join(dest, "panel.png")
    stats_line = "sinks=%d  ridge=%.3f  Dd=%.3g/m  §7.7" % (
        div["sink_count"],
        div["ridgeline_frac"],
        div["drainage_density_per_m"],
    )
    save_panel_png(png, h, pit_mask, "%s %sx%s" % (name, n, n), stats_line)
    root_png = os.path.join(gpb_root(), "%s_panel.png" % slug)
    shutil.copy2(png, root_png)

    payload = {
        "id": "GPB-027",
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
        "sink_count": div["sink_count"],
        "ridgeline_frac": div["ridgeline_frac"],
        "drainage_density_per_m": div["drainage_density_per_m"],
        "n_ridge": div["n_ridge"],
        "n_channel": div["n_channel"],
        "meta": {k: v for k, v in meta.items() if k != "in_degree"},
        "panel_png": png,
        "gates": [{"name": gn, "pass": p, "detail": d} for gn, p, d in gates],
        "entry": "PASS" if ok else "FAIL",
        "caption": (
            "Real-world DEM diversity (paper §7.7): USGS 3DEP LiDAR 1 m / "
            "Alaska IFSAR 5 m / Copernicus GLO-30. Same P-COMP-1 fill then D8."
        ),
    }
    mpath = os.path.join(dest, "metrics.json")
    with open(mpath, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    print("metrics ->", mpath)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p_comp_realworld_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "RealWorldDiversity",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("GPB027_MANIM", os.environ.get("PCOMP1_MANIM", "0")) != "1":
        print("  manim: skip (set GPB027_MANIM=1 to render)")
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
        print((proc.stderr or proc.stdout or "")[-1200:])
    else:
        src = os.path.join(
            dest, "videos", "p_comp_realworld_manim", "480p15", "RealWorldDiversity.mp4"
        )
        fig_dir = os.path.join(HERE, "figures")
        os.makedirs(fig_dir, exist_ok=True)
        fig = os.path.join(fig_dir, "RealWorldDiversity.mp4")
        if os.path.isfile(src):
            shutil.copy2(src, fig)
            info["figure"] = fig
            info["bytes"] = os.path.getsize(fig)
            print("  manim copied ->", fig, info["bytes"], "bytes")
    return info


def load_cases(n: int) -> list[tuple[str, str, np.ndarray, dict]]:
    lidar_h, lidar_meta = fetch_3dep_window(
        "lidar",
        west=-118.2964,
        south=34.1348,
        n=n,
        cell_m=1.0,
        product=(
            "USGS 3DEP 1 m LiDAR-derived DEM, Griffith Park / Los Angeles "
            "(CA_LosAngeles_B23 family; ImageServer window ~256 m x 256 m)"
        ),
        staged_tried=LIDAR_COG_TRIED,
    )
    ifsar_h, ifsar_meta = fetch_3dep_window(
        "ifsar",
        west=-147.815,
        south=64.894,
        n=n,
        cell_m=5.0,
        product=(
            "USGS 3DEP 5 m Alaska IFSAR DEM, Fairbanks-area window "
            "(AK_IFSAR_2010 family; ImageServer window ~1.28 km x 1.28 km)"
        ),
        staged_tried=IFSAR_COG_TRIED,
    )
    cop_h, cop_meta = fetch_copernicus(n)
    return [
        ("lidar", "USGS-LiDAR 1m Griffith Park", lidar_h, lidar_meta),
        ("ifsar", "IFSAR-AK 5m Fairbanks", ifsar_h, ifsar_meta),
        ("copernicus", "Copernicus GLO-30 N32E110", cop_h, cop_meta),
    ]


def main() -> int:
    t0 = time.time()
    n = window_n()
    root = gpb_root()
    os.makedirs(CACHE, exist_ok=True)
    print("==[P-COMP-1 real-world] GPB-027 DEM diversity n=%d ==" % n)
    try:
        cases = load_cases(n)
    except RuntimeError as err:
        print("BLOCKED:", err)
        blocked = {
            "id": "GPB-027",
            "entry": "BLOCKED",
            "error": str(err),
            "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        with open(os.path.join(root, "metrics.json"), "w", encoding="utf-8") as fh:
            json.dump(blocked, fh, indent=2)
            fh.write("\n")
        return 2

    records = []
    all_ok = True
    for slug, name, h, meta in cases:
        rec = evaluate_case(slug, name, h, meta)
        records.append(rec)
        all_ok = all_ok and rec["entry"] == "PASS"

    print("---- manim ----")
    manim_info = maybe_manim(root)

    combined = {
        "id": "GPB-027",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "n": n,
        "cases": [
            {
                "slug": r["slug"],
                "entry": r["entry"],
                "n_pit": r["n_pit"],
                "n_term": r["n_term"],
                "uniq_out": r["uniq_out"],
                "longest": r["longest"],
                "sink_count": r["sink_count"],
                "ridgeline_frac": r["ridgeline_frac"],
                "drainage_density_per_m": r["drainage_density_per_m"],
                "zmin": r["meta"]["zmin"],
                "zmax": r["meta"]["zmax"],
                "cell_m": r["meta"]["cell_m"],
                "source": r["meta"]["source"],
                "synthetic": r["meta"]["synthetic"],
            }
            for r in records
        ],
        "manim": manim_info,
        "caption": (
            "Figure: RealWorldDiversity.mp4 — three public DEMs, same P-COMP-1 "
            "fill then D8. Panels report ridgeline fraction, drainage density, "
            "and sink count (paper §7.7)."
        ),
        "entry": "PASS" if all_ok else "FAIL",
        "note": (
            "task13: real products only. LiDAR/IFSAR = 3DEP ImageServer windows "
            "after staged S3 COG vsicurl failed (502/timeout). Copernicus = "
            "GLO-30 COG N32E110. No synthetic stand-ins."
        ),
    }
    mpath = os.path.join(root, "metrics.json")
    with open(mpath, "w", encoding="utf-8") as fh:
        json.dump(combined, fh, indent=2)
        fh.write("\n")
    print("metrics ->", mpath)
    print("GPB-027 ENTRY:", "PASS" if all_ok else "FAIL")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
