#!/usr/bin/env python3
"""P-004 / GPB-019 algebraic entry: Horn exact on quadratics, cubic O(w²).

Algebraic half: formal/dafny/P004_consistency.dfy and
formal/lean4/VeriGIS/Consistency.lean.

This file is the empirical half:

  1. Quadratic surface: Horn recovers (A, B) to ~1e-15.
  2. Cubic z = G x³: error = G w²; halving w quarters the error.
  3. Optional wolframscript Taylor remainder (HornDx - hx = O(w²)).
  4. Optional Manim stencil (P004_MANIM=1).

Wolfram / Manim missing does not fail the entry (AutoDL has no wolframscript).
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

A_QUAD, B_QUAD, C_QUAD = 0.3, -0.2, 5.0
D_QUAD, E_QUAD, F_QUAD = 0.05, -0.04, 0.02
G_CUBIC = 0.07
W_QUAD = 1.0
CUBIC_WS = (2.0, 1.0, 0.5, 0.25)


def out_dir() -> str:
    d = os.environ.get("GPB004_OUT", os.path.join(HERE, "results", "gpb004"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb004"), exist_ok=True)
    return d


def horn_dzdx(a, b, c, d, f, g, h, i, w):
    return ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w)


def horn_dzdy(a, b, c, d, f, g, h, i, w):
    return ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w)


def sample_quad(w, p, q):
    x, y = p * w, q * w
    return (
        A_QUAD * x
        + B_QUAD * y
        + C_QUAD
        + D_QUAD * x * x
        + E_QUAD * x * y
        + F_QUAD * y * y
    )


def window_quad(w):
    pts = {}
    for p, q, name in (
        (-1, -1, "a"),
        (0, -1, "b"),
        (1, -1, "c"),
        (-1, 0, "d"),
        (1, 0, "f"),
        (-1, 1, "g"),
        (0, 1, "h"),
        (1, 1, "i"),
    ):
        pts[name] = sample_quad(w, p, q)
    return pts


def cubic_x_window(G, w):
    def z(p):
        return G * (p * w) ** 3

    return {
        "a": z(-1),
        "b": 0.0,
        "c": z(1),
        "d": z(-1),
        "f": z(1),
        "g": z(-1),
        "h": 0.0,
        "i": z(1),
    }


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p004_taylor.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p004_taylor.wl"
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
    path = os.path.join(dest, "p004_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p004_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "HornStencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("P004_MANIM", "0") != "1":
        print("  manim: skip (set P004_MANIM=1 to render)")
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


def gates(dx_err: float, dy_err: float, cubic_rows: list[dict]) -> list:
    by_w = {r["w"]: r for r in cubic_rows}
    r1 = by_w[1.0]
    rhalf = by_w[0.5]
    out = []
    out.append(
        (
            "quadratic |DzDx - A| < 1e-10",
            dx_err < 1e-10,
            "abs=%.3e" % dx_err,
        )
    )
    out.append(
        (
            "quadratic |DzDy - B| < 1e-10",
            dy_err < 1e-10,
            "abs=%.3e" % dy_err,
        )
    )
    out.append(
        (
            "cubic w=1 |DzDx - G w^2| < 1e-12",
            abs(r1["dzdx"] - G_CUBIC * r1["w"] ** 2) < 1e-12,
            "dzdx=%.6e expect=%.6e" % (r1["dzdx"], G_CUBIC),
        )
    )
    ratio = rhalf["abs_err"] / r1["abs_err"] if r1["abs_err"] > 0 else float("nan")
    out.append(
        (
            "cubic |err|(w=0.5) / |err|(w=1) ≈ 1/4",
            abs(ratio - 0.25) < 1e-8,
            "ratio=%.6f" % ratio,
        )
    )
    return out


def main() -> int:
    t0 = time.time()
    dest = out_dir()
    print("==[P-004] Horn quadratic exactness + cubic O(w^2) remainder ==")

    pts = window_quad(W_QUAD)
    dx = horn_dzdx(pts["a"], pts["b"], pts["c"], pts["d"], pts["f"],
                   pts["g"], pts["h"], pts["i"], W_QUAD)
    dy = horn_dzdy(pts["a"], pts["b"], pts["c"], pts["d"], pts["f"],
                   pts["g"], pts["h"], pts["i"], W_QUAD)
    dx_err = abs(dx - A_QUAD)
    dy_err = abs(dy - B_QUAD)
    print("---- quadratic A=%.2f B=%.2f w=%.2f ----" % (A_QUAD, B_QUAD, W_QUAD))
    print("  DzDx=%.12e  |err|=%.3e" % (dx, dx_err))
    print("  DzDy=%.12e  |err|=%.3e" % (dy, dy_err))

    print("---- cubic z = G x^3, G=%.3f ----" % G_CUBIC)
    print("%8s %14s %14s %14s" % ("w", "DzDx", "G w^2", "|err| vs 0"))
    cubic_rows = []
    for w in CUBIC_WS:
        cw = cubic_x_window(G_CUBIC, w)
        val = horn_dzdx(cw["a"], cw["b"], cw["c"], cw["d"], cw["f"],
                        cw["g"], cw["h"], cw["i"], w)
        expect = G_CUBIC * w * w
        row = {
            "w": w,
            "dzdx": float(val),
            "expect": float(expect),
            "abs_err": float(abs(val)),
            "remainder_vs_formula": float(abs(val - expect)),
        }
        cubic_rows.append(row)
        print("%8.2f %14.6e %14.6e %14.6e" % (w, val, expect, abs(val)))

    print("---- wolframscript Taylor remainder ----")
    wolfram = eval_wolfram(dest)
    print("---- manim ----")
    manim_info = maybe_manim(dest)

    gs = gates(dx_err, dy_err, cubic_rows)
    print("---- gates ----")
    ok = True
    for name, passed, detail in gs:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
        ok = ok and passed

    payload = {
        "id": "GPB-019",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "quadratic": {"dzdx": dx, "dzdy": dy, "dx_err": dx_err, "dy_err": dy_err},
        "cubic": cubic_rows,
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gs],
        "entry": "PASS" if ok else "FAIL",
        "note": (
            "Horn is exact on degree <= 2. Cubic remainder is G w^2, so the "
            "estimator is consistent as w -> 0. Not a general C^2 proof."
        ),
    }
    for path in (
        os.path.join(dest, "gpb004_metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb004"), "gpb004_metrics.json")
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

        ws = [r["w"] for r in cubic_rows]
        fig, ax = plt.subplots(figsize=(6.2, 4.2))
        ax.loglog(ws, [r["abs_err"] for r in cubic_rows], "o-", label="Horn |DzDx| on G x^3")
        ax.loglog(ws, [abs(G_CUBIC) * w * w for w in ws], "s--", label=r"$|G| w^2$")
        ax.set_xlabel("grid spacing w")
        ax.set_ylabel("error vs analytic (0 at origin)")
        ax.set_title("P-004: cubic remainder O(w^2)")
        ax.invert_xaxis()
        ax.legend()
        ax.grid(True, which="both", ls=":")
        png = os.path.join(dest, "gpb004_cubic_remainder.png")
        fig.tight_layout()
        fig.savefig(png, dpi=120)
        plt.close(fig)
        print("plot ->", png)
    except Exception as err:
        print("plot skip:", err)

    print("GPB-019 ALGEBRA ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
