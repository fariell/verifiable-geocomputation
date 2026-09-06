#!/usr/bin/env python3
"""GPB-019 entry: Horn slope consistency as grid spacing → 0, plus noise contrast.

Proposition (GeoProofBench v0.1):
  The Horn (1981) finite-difference slope operator is a consistent estimator
  of the analytic slope as the grid spacing tends to zero.

This is the *empirical* half. The algebraic half (exact on planes) is P-001
(Dafny 19 verified / Lean lake build). Here we keep a smooth non-planar DEM
(sum of Gaussians + tilt, same generator as Phase 1) and sweep spacing w.

Control: naive profile curvature on the same grids — Phase 1 corr ≈ 0.157 —
must *not* pass the same consistency gates. That is GPB-020's empirical gap.

Noise panel: i.i.d. elevation noise at w=1 m. Slope error grows ~σ/w;
curvature ~σ/w². Documents why first-order is provable and second-order is not.
"""
from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime, timezone

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from experiment import (  # noqa: E402
    analytic_derivs,
    build_synthetic_dem,
    metrics,
    numeric_derivs,
)

SPACINGS = (4.0, 2.0, 1.0, 0.5)
EXTENT_CELLS_AT_1M = 200
NOISE_SIGMAS = (0.0, 1.0, 2.0, 5.0)
SEED = 0


def out_dir() -> str:
    d = os.environ.get("GPB019_OUT", os.path.join(HERE, "results", "gpb019"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb019"), exist_ok=True)
    return d


def profile_curv(hxx, hyy, hxy, dzdx, dzdy):
    denom = (dzdx ** 2 + dzdy ** 2) ** 1.5
    safe = np.where(denom > 1e-9, denom, 1.0)
    return np.where(
        denom > 1e-9,
        (hxx * dzdx ** 2 + 2 * hxy * dzdx * dzdy + hyy * dzdy ** 2) / safe,
        0.0,
    )


def eval_grid(dx: float, sigma: float = 0.0, rng: np.random.Generator | None = None):
    nx = max(16, int(round(EXTENT_CELLS_AT_1M / dx)))
    X, Y, h, dx, dy, bumps = build_synthetic_dem(nx=nx, ny=nx, dx=dx, dy=dx)
    if sigma > 0:
        rng = rng or np.random.default_rng(SEED)
        h = h + rng.normal(0.0, sigma, size=h.shape)
    dhdx_t, dhdy_t, hxx_t, hyy_t, hxy_t = analytic_derivs(X, Y, bumps)
    slope_t = np.sqrt(dhdx_t ** 2 + dhdy_t ** 2)
    prof_t = profile_curv(hxx_t, hyy_t, hxy_t, dhdx_t, dhdy_t)
    dzdx, dzdy, hxx_n, hyy_n, hxy_n = numeric_derivs(h, dx, dy)
    slope_n = np.sqrt(dzdx ** 2 + dzdy ** 2)
    prof_n = profile_curv(hxx_n, hyy_n, hxy_n, dzdx, dzdy)
    return {
        "nx": nx,
        "dx": dx,
        "sigma": sigma,
        "slope": metrics(slope_t, slope_n),
        "gradient_x": metrics(dhdx_t, dzdx),
        "profile_curvature": metrics(prof_t, prof_n),
    }


def gates(spacing_rows: list[dict]) -> list[tuple[str, bool, str]]:
    by_dx = {r["dx"]: r for r in spacing_rows}
    r1 = by_dx[1.0]
    r_coarse = by_dx[4.0]
    r_fine = by_dx[0.5]
    g = []
    c = r1["slope"]["corr"]
    g.append(
        (
            "slope_corr(dx=1) >= 0.999",
            c == c and c >= 0.999,
            "corr=%.6f" % c,
        )
    )
    g.append(
        (
            "slope_rmse(dx=0.5) < slope_rmse(dx=4)",
            r_fine["slope"]["rmse"] < r_coarse["slope"]["rmse"],
            "fine=%.3e coarse=%.3e" % (r_fine["slope"]["rmse"], r_coarse["slope"]["rmse"]),
        )
    )
    cc = r1["profile_curvature"]["corr"]
    g.append(
        (
            "curvature_corr(dx=1) < 0.5 (control, must NOT look consistent)",
            cc != cc or cc < 0.5,
            "corr=%.4f" % cc,
        )
    )
    return g


def main() -> int:
    t0 = time.time()
    rng = np.random.default_rng(SEED)
    dest = out_dir()
    print("==[GPB-019] Horn slope consistency + noise contrast ==")
    print("extent ≈ %d m at dx=1; spacings=%s" % (EXTENT_CELLS_AT_1M, SPACINGS))

    spacing_rows = []
    print("---- spacing sweep (sigma=0) ----")
    print("%8s %6s %12s %10s %12s %10s" % ("dx", "nx", "slope_rmse", "slope_r", "curv_rmse", "curv_r"))
    for dx in SPACINGS:
        row = eval_grid(dx, sigma=0.0, rng=rng)
        spacing_rows.append(row)
        print(
            "%8.2f %6d %12.4e %10.6f %12.4e %10.4f"
            % (
                dx,
                row["nx"],
                row["slope"]["rmse"],
                row["slope"]["corr"],
                row["profile_curvature"]["rmse"],
                row["profile_curvature"]["corr"],
            )
        )

    print("---- noise sweep (dx=1) ----")
    noise_rows = []
    print("%8s %12s %12s" % ("sigma", "slope_rmse", "curv_rmse"))
    for sig in NOISE_SIGMAS:
        row = eval_grid(1.0, sigma=sig, rng=rng)
        noise_rows.append(row)
        print("%8.1f %12.4e %12.4e" % (sig, row["slope"]["rmse"], row["profile_curvature"]["rmse"]))

    gatelist = gates(spacing_rows)
    print("---- gates ----")
    ok = True
    for name, passed, detail in gatelist:
        flag = "PASS" if passed else "FAIL"
        ok = ok and passed
        print("  [%s] %s  (%s)" % (flag, name, detail))

    payload = {
        "id": "GPB-019",
        "utc": datetime.now(timezone.utc).isoformat(),
        "seed": SEED,
        "spacings": spacing_rows,
        "noise": noise_rows,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gatelist],
        "entry_pass": ok,
        "elapsed_s": round(time.time() - t0, 3),
        "note": (
            "Empirical half of GPB-019. Algebraic half = P-001 planar exactness. "
            "Curvature panel is a control (GPB-020 gap), not a pass criterion for Horn."
        ),
    }
    out_json = os.path.join(dest, "gpb019_metrics.json")
    with open(out_json, "w") as f:
        json.dump(payload, f, indent=2)
    print("metrics ->", out_json)
    wb = os.path.expanduser("~/.workbuddy/gpb019/gpb019_metrics.json")
    if os.path.isdir(os.path.expanduser("~/.workbuddy")):
        os.makedirs(os.path.dirname(wb), exist_ok=True)
        with open(wb, "w") as f:
            json.dump(payload, f, indent=2)
        print("metrics ->", wb)

    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        xs = [r["dx"] for r in spacing_rows]
        fig, ax = plt.subplots(figsize=(6.2, 4.2))
        ax.loglog(xs, [r["slope"]["rmse"] for r in spacing_rows], "o-", label="Horn slope RMSE")
        ax.loglog(
            xs,
            [r["profile_curvature"]["rmse"] for r in spacing_rows],
            "s--",
            label="profile curvature RMSE",
        )
        ax.set_xlabel("grid spacing w (m)")
        ax.set_ylabel("RMSE vs analytic")
        ax.set_title("GPB-019: consistency in w (synthetic DEM)")
        ax.invert_xaxis()
        ax.legend()
        ax.grid(True, which="both", ls=":")
        png = os.path.join(dest, "gpb019_rmse_vs_w.png")
        fig.tight_layout()
        fig.savefig(png, dpi=120)
        print("plot ->", png)
    except Exception as exc:
        print("plot skipped (%s)" % exc)

    print("GPB-019 ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
