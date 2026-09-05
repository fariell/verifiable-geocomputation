#!/usr/bin/env python3
"""VeriGIS Phase 1 experiment: verifiable DEM terrain operator baseline.

Generates a synthetic DEM composed of a sum of Gaussians plus a linear tilt,
for which the 1st/2nd derivatives are known in closed form. The SAME derivatives
are then computed numerically (finite differences) and compared against the closed
form to obtain verification metrics (MAE / RMSE / max / correlation).

This is the empirical core of the "operator layer" of the Verifiable
Geocomputation research program: before we can *prove* properties of terrain
operators, we must show our numeric operators reproduce analytic ground truth.
"""
import os
import json
import time
import numpy as np
from datetime import datetime

VERIGIS_HOME = os.environ.get("VERIGIS_HOME", "/root/verigis")
VERIGIS_LOG = os.environ.get("VERIGIS_LOG", os.path.join(VERIGIS_HOME, "logs"))
os.makedirs(VERIGIS_LOG, exist_ok=True)
RESULTS = os.path.join(VERIGIS_HOME, "results")
os.makedirs(RESULTS, exist_ok=True)
PROGRESS = os.path.join(VERIGIS_LOG, "progress.log")


def log(msg):
    line = "[%s] %s" % (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), msg)
    print(line, flush=True)
    with open(PROGRESS, "a") as f:
        f.write(line + "\n")


def build_synthetic_dem(nx=200, ny=200, dx=1.0, dy=1.0):
    """Sum-of-Gaussians + linear tilt DEM with closed-form 1st/2nd derivatives."""
    x = (np.arange(nx) - nx / 2) * dx
    y = (np.arange(ny) - ny / 2) * dy
    X, Y = np.meshgrid(x, y)
    h = 500.0 + 0.3 * X + 0.2 * Y
    # bumps: (amplitude, center_x, center_y, sigma)
    bumps = [(120.0, 30.0, 40.0, 15.0), (-80.0, -40.0, -20.0, 20.0)]
    for A, cx, cy, s in bumps:
        r2 = (X - cx) ** 2 + (Y - cy) ** 2
        h = h + A * np.exp(-r2 / (2 * s ** 2))
    return X, Y, h, dx, dy, bumps


def analytic_derivs(X, Y, bumps):
    dhdx = np.full_like(X, 0.3)
    dhdy = np.full_like(X, 0.2)
    hxx = np.zeros_like(X)
    hyy = np.zeros_like(X)
    hxy = np.zeros_like(X)
    for A, cx, cy, s in bumps:
        r2 = (X - cx) ** 2 + (Y - cy) ** 2
        g = A * np.exp(-r2 / (2 * s ** 2))
        dhdx = dhdx + g * (-(X - cx) / s ** 2)
        dhdy = dhdy + g * (-(Y - cy) / s ** 2)
        hxx = hxx + g * ((X - cx) ** 2 / s ** 4 - 1.0 / s ** 2)
        hyy = hyy + g * ((Y - cy) ** 2 / s ** 4 - 1.0 / s ** 2)
        hxy = hxy + g * ((X - cx) * (Y - cy)) / s ** 4
    return dhdx, dhdy, hxx, hyy, hxy


def numeric_derivs(h, dx, dy):
    """Horn (1981) gradient + Zevenbergen & Thorne (1987) 2nd derivatives."""
    hp = np.pad(h, 1, mode="edge")
    a = hp[:-2, :-2]; b = hp[:-2, 1:-1]; c = hp[:-2, 2:]
    d = hp[1:-1, :-2]; e = hp[1:-1, 1:-1]; f = hp[1:-1, 2:]
    g = hp[2:, :-2]; hh = hp[2:, 1:-1]; i = hp[2:, 2:]
    dzdx = ((c + 2 * f + i) - (a + 2 * d + g)) / (8.0 * dx)
    dzdy = ((g + 2 * hh + i) - (a + 2 * b + c)) / (8.0 * dy)
    d2zdx2 = (a - 2 * d + g) / dx ** 2
    d2zdy2 = (a - 2 * b + c) / dy ** 2
    d2zdxdy = (a - c - g + i) / (4.0 * dx * dy)
    return dzdx, dzdy, d2zdx2, d2zdy2, d2zdxdy


def metrics(truth, pred):
    err = pred - truth
    mae = float(np.mean(np.abs(err)))
    rmse = float(np.sqrt(np.mean(err ** 2)))
    mx = float(np.max(np.abs(err)))
    if np.std(truth) < 1e-12 or np.std(pred) < 1e-12:
        corr = float("nan")
    else:
        corr = float(np.corrcoef(truth.ravel(), pred.ravel())[0, 1])
    return {"mae": mae, "rmse": rmse, "max_abs": mx, "corr": corr}


def main():
    t0 = time.time()
    log("PHASE1-EXP: building synthetic DEM (200x200, closed-form ground truth)")
    X, Y, h, dx, dy, bumps = build_synthetic_dem()
    log("PHASE1-EXP: analytic derivatives")
    dhdx_t, dhdy_t, hxx_t, hyy_t, hxy_t = analytic_derivs(X, Y, bumps)
    slope_t = np.sqrt(dhdx_t ** 2 + dhdy_t ** 2)
    aspect_t = np.degrees(np.arctan2(-dhdy_t, -dhdx_t)) % 360.0
    denom_t = (dhdx_t ** 2 + dhdy_t ** 2) ** 1.5
    prof_t = np.where(denom_t > 1e-9,
                      (hxx_t * dhdx_t ** 2 + 2 * hxy_t * dhdx_t * dhdy_t + hyy_t * dhdy_t ** 2) /
                      np.where(denom_t > 1e-9, denom_t, 1.0), 0.0)

    log("PHASE1-EXP: numeric (finite-difference) derivatives")
    dzdx, dzdy, d2zdx2, d2zdy2, d2zdxdy = numeric_derivs(h, dx, dy)
    slope_n = np.sqrt(dzdx ** 2 + dzdy ** 2)
    aspect_n = np.degrees(np.arctan2(-dzdy, -dzdx)) % 360.0
    denom_n = (dzdx ** 2 + dzdy ** 2) ** 1.5
    prof_n = np.where(denom_n > 1e-9,
                      (d2zdx2 * dzdx ** 2 + 2 * d2zdxdy * dzdx * dzdy + d2zdy2 * dzdy ** 2) /
                      np.where(denom_n > 1e-9, denom_n, 1.0), 0.0)

    log("PHASE1-EXP: verification metrics (numeric vs analytic)")
    res = {
        "grid": {"nx": 200, "ny": 200, "dx": dx, "dy": dy},
        "slope_magnitude": metrics(slope_t, slope_n),
        "gradient_x": metrics(dhdx_t, dzdx),
        "gradient_y": metrics(dhdy_t, dzdy),
        "profile_curvature": metrics(prof_t, prof_n),
        "note": "Closed-form derivatives of a sum-of-Gaussians + linear-tilt DEM.",
    }
    log("PHASE1-EXP: rmse slope=%.3e grad_x=%.3e grad_y=%.3e prof=%.3e" % (
        res["slope_magnitude"]["rmse"], res["gradient_x"]["rmse"],
        res["gradient_y"]["rmse"], res["profile_curvature"]["rmse"]))

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, axs = plt.subplots(2, 2, figsize=(10, 9))
        axs[0, 0].imshow(h, cmap="terrain"); axs[0, 0].set_title("Synthetic DEM")
        axs[0, 1].imshow(slope_t, cmap="viridis"); axs[0, 1].set_title("Slope (truth)")
        axs[1, 0].imshow(slope_n, cmap="viridis"); axs[1, 0].set_title("Slope (numeric)")
        axs[1, 1].imshow(np.abs(slope_n - slope_t), cmap="magma")
        axs[1, 1].set_title("|numeric - truth| slope")
        plt.tight_layout()
        plt.savefig(os.path.join(RESULTS, "phase1_slope_compare.png"), dpi=110)
        log("PHASE1-EXP: plot -> results/phase1_slope_compare.png")
    except Exception as e:
        log("PHASE1-EXP: plotting skipped (%s)" % e)

    with open(os.path.join(RESULTS, "phase1_metrics.json"), "w") as f:
        json.dump(res, f, indent=2)
    log("PHASE1-EXP: metrics -> results/phase1_metrics.json")
    log("PHASE1-EXP: DONE in %.1fs" % (time.time() - t0))


if __name__ == "__main__":
    main()
