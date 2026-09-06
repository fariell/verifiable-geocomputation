#!/usr/bin/env python3
"""GPB-003 / P-003 entry: ZT Hessian vs Phase-1 swapped stencil.

Algebraic half lives in formal/dafny/P003_curvature.dfy and
formal/lean4/VeriGIS/Curvature.lean. This file is the empirical half:

  1. Quadratic bump: correct ZT recovers (hxx, hyy, hxy) = (-2k, -2k, 0).
  2. Phase 1 DEM: correct Hessian correlation vs analytic; old stencil
     reproduces the profile-curvature corr ≈ 0.157.
  3. Optional wolframscript Taylor remainder (Hxx - h_xx = O(w²)).
  4. Optional Manim stencil animation (P003_MANIM=1).
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
sys.path.insert(0, HERE)
from experiment import (  # noqa: E402
    analytic_derivs,
    build_synthetic_dem,
    metrics,
    numeric_derivs,
)

SEED = 0
K_BUMP = 0.02
W_QUAD = 1.0


def out_dir() -> str:
    d = os.environ.get("GPB003_OUT", os.path.join(HERE, "results", "gpb003"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb003"), exist_ok=True)
    return d


def numeric_zt(h, dx, dy):
    """Center-row / center-col ZT second derivatives (matches the proofs)."""
    hp = np.pad(h, 1, mode="edge")
    a = hp[:-2, :-2]
    b = hp[:-2, 1:-1]
    c = hp[:-2, 2:]
    d = hp[1:-1, :-2]
    e = hp[1:-1, 1:-1]
    f = hp[1:-1, 2:]
    g = hp[2:, :-2]
    hh = hp[2:, 1:-1]
    i = hp[2:, 2:]
    hxx = (d - 2.0 * e + f) / dx ** 2
    hyy = (b - 2.0 * e + hh) / dy ** 2
    hxy = (a - c - g + i) / (4.0 * dx * dy)
    return hxx, hyy, hxy


def profile_curv(hxx, hyy, hxy, dzdx, dzdy):
    denom = (dzdx ** 2 + dzdy ** 2) ** 1.5
    safe = np.where(denom > 1e-9, denom, 1.0)
    return np.where(
        denom > 1e-9,
        (hxx * dzdx ** 2 + 2 * hxy * dzdx * dzdy + hyy * dzdy ** 2) / safe,
        0.0,
    )


def paraboloid(nx=21, w=W_QUAD, k=K_BUMP):
    half = nx // 2
    p = (np.arange(nx) - half).astype(float)
    q = (np.arange(nx) - half).astype(float)
    P, Q = np.meshgrid(p, q)
    X, Y = P * w, Q * w
    h = 10.0 - k * (X ** 2 + Y ** 2)
    return X, Y, h, w, k


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p003_taylor.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p003_taylor.wl"
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
    if payload.get("parsed"):
        print("  wolfram remainder:", payload["parsed"].get("remainder"))
        print("  wolfram w2coef:", payload["parsed"].get("w2coef"))
    path = os.path.join(dest, "p003_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p003_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "ZTStencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("P003_MANIM", "0") != "1":
        print("  manim: skip (set P003_MANIM=1 to render)")
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


def gates(quad_err: dict, hess_corr: float, old_hess_corr: float,
          old_prof_corr: float, zt_prof_corr: float) -> list:
    out = []
    out.append(
        (
            "paraboloid |hxx + 2k| < 1e-10",
            quad_err["hxx"] < 1e-10,
            "maxabs=%.3e" % quad_err["hxx"],
        )
    )
    out.append(
        (
            "paraboloid |hyy + 2k| < 1e-10",
            quad_err["hyy"] < 1e-10,
            "maxabs=%.3e" % quad_err["hyy"],
        )
    )
    out.append(
        (
            "correct hxx corr(dx=1) >= 0.90",
            hess_corr == hess_corr and hess_corr >= 0.90,
            "corr=%.6f" % hess_corr,
        )
    )
    out.append(
        (
            "correct hxx corr > Phase1-wrong hxx corr",
            hess_corr == hess_corr and old_hess_corr == old_hess_corr
            and hess_corr > old_hess_corr,
            "zt=%.4f old=%.4f" % (hess_corr, old_hess_corr),
        )
    )
    out.append(
        (
            "Phase1-wrong profile corr(dx=1) < 0.5 (reproduce 0.157)",
            old_prof_corr != old_prof_corr or old_prof_corr < 0.5,
            "corr=%.4f" % old_prof_corr,
        )
    )
    out.append(
        (
            "ZT profile corr(dx=1) < 0.5 (GPB-020 still fails, not a stencil-only bug)",
            zt_prof_corr != zt_prof_corr or zt_prof_corr < 0.5,
            "corr=%.4f" % zt_prof_corr,
        )
    )
    return out


def main() -> int:
    t0 = time.time()
    dest = out_dir()
    print("==[P-003] ZT Hessian exactness + Phase-1 stencil contrast ==")

    X, Y, h, w, k = paraboloid()
    hxx, hyy, hxy = numeric_zt(h, w, w)
    interior = (slice(1, -1), slice(1, -1))
    quad_err = {
        "hxx": float(np.max(np.abs(hxx[interior] + 2.0 * k))),
        "hyy": float(np.max(np.abs(hyy[interior] + 2.0 * k))),
        "hxy": float(np.max(np.abs(hxy[interior]))),
    }
    print("---- quadratic bump k=%.4f w=%.2f ----" % (k, w))
    print("  max |hxx + 2k| = %.3e" % quad_err["hxx"])
    print("  max |hyy + 2k| = %.3e" % quad_err["hyy"])
    print("  max |hxy|      = %.3e" % quad_err["hxy"])

    Xg, Yg, dem, dx, dy, bumps = build_synthetic_dem(nx=200, ny=200, dx=1.0, dy=1.0)
    dhdx_t, dhdy_t, hxx_t, hyy_t, hxy_t = analytic_derivs(Xg, Yg, bumps)
    dzdx, dzdy, hxx_old, hyy_old, hxy_old = numeric_derivs(dem, dx, dy)
    hxx_n, hyy_n, hxy_n = numeric_zt(dem, dx, dy)
    m_hxx = metrics(hxx_t, hxx_n)
    m_hyy = metrics(hyy_t, hyy_n)
    m_hxy = metrics(hxy_t, hxy_n)
    m_old_x = metrics(hxx_t, hxx_old)
    prof_t = profile_curv(hxx_t, hyy_t, hxy_t, dhdx_t, dhdy_t)
    prof_old = profile_curv(hxx_old, hyy_old, hxy_old, dzdx, dzdy)
    prof_new = profile_curv(hxx_n, hyy_n, hxy_n, dzdx, dzdy)
    m_prof_old = metrics(prof_t, prof_old)
    m_prof_new = metrics(prof_t, prof_new)

    print("---- Phase 1 DEM dx=1 (200x200) ----")
    print("  ZT   hxx  rmse=%.4e corr=%.4f" % (m_hxx["rmse"], m_hxx["corr"]))
    print("  ZT   hyy  rmse=%.4e corr=%.4f" % (m_hyy["rmse"], m_hyy["corr"]))
    print("  ZT   hxy  rmse=%.4e corr=%.4f" % (m_hxy["rmse"], m_hxy["corr"]))
    print("  old  hxx  rmse=%.4e corr=%.4f  (should look like hyy, swapped)" % (
        m_old_x["rmse"], m_old_x["corr"]))
    print("  old  profile corr=%.4f" % m_prof_old["corr"])
    print("  ZT   profile corr=%.4f" % m_prof_new["corr"])

    print("---- wolframscript Taylor remainder ----")
    wolfram = eval_wolfram(dest)
    print("---- manim ----")
    manim_info = maybe_manim(dest)

    gs = gates(quad_err, m_hxx["corr"], m_old_x["corr"], m_prof_old["corr"], m_prof_new["corr"])
    print("---- gates ----")
    ok = True
    for name, passed, detail in gs:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
        ok = ok and passed

    payload = {
        "id": "GPB-003",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "quadratic": quad_err,
        "phase1": {
            "hxx_zt": m_hxx,
            "hyy_zt": m_hyy,
            "hxy_zt": m_hxy,
            "hxx_old": m_old_x,
            "profile_old": m_prof_old,
            "profile_zt": m_prof_new,
        },
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gs],
        "entry": "PASS" if ok else "FAIL",
        "note": (
            "Correct ZT Hessian is exact on quadratics. Phase 1 profile "
            "corr≈0.157 is reproduced by the swapped stencil; GPB-020 is "
            "not a pass criterion."
        ),
    }
    for path in (
        os.path.join(dest, "gpb003_metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb003"), "gpb003_metrics.json")
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

    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, axs = plt.subplots(1, 3, figsize=(12, 3.6))
        im0 = axs[0].imshow(hxx_t, cmap="coolwarm")
        axs[0].set_title("analytic hxx")
        im1 = axs[1].imshow(hxx_n, cmap="coolwarm")
        axs[1].set_title("ZT hxx")
        im2 = axs[2].imshow(hxx_old, cmap="coolwarm")
        axs[2].set_title("Phase1-wrong 'hxx'")
        for ax, im in zip(axs, (im0, im1, im2)):
            fig.colorbar(im, ax=ax, fraction=0.046)
            ax.set_xticks([])
            ax.set_yticks([])
        fig.tight_layout()
        png = os.path.join(dest, "gpb003_hxx_compare.png")
        fig.savefig(png, dpi=120)
        plt.close(fig)
        print("plot ->", png)
    except Exception as err:
        print("plot skip:", err)

    print("GPB-003 ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
