#!/usr/bin/env python3
"""P-COMP-3 / GPB-023 entry: ZT curvature does not entail Horn slope.

Negative result (feature, not a bug): P-003 Zevenbergen–Thorne Hessian /
profile curvature and P-004 Horn quadratic-exact slope are not the same
function family. Same DEM, two operators, numerically divergent outputs.

Algebraic half: formal/dafny/PCOMP_3.dfy and
formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean.

Kernels are imported from phase1 P-003 / P-004 — not copied.

  grid-A: mild x^2 + slope 0.21  → ZT Hxx ~ 1.41e-2, Horn Dx = 0.21
  grid-B: stronger x^2 + slope 0.07 → ZT Hxx ~ 6.97e-2, Horn Dx = 0.07
  stream: z = f(x) only (invariant along y) → both Hyy and Horn Dy drop to 0
  P-001: slopeSq >= 0 still holds on both grids (shared root, not a counterexample)
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

from p003_curvature import numeric_zt
from p004_consistency import horn_dzdx, horn_dzdy

W = 1.0
# Hxx = 2 D on z = D x^2 + A x. Target Hxx = 1.41e-2 / 6.97e-2.
GRID_A = {"A": 0.21, "D": 0.00705, "nx": 9}
GRID_B = {"A": 0.07, "D": 0.03485, "nx": 9}


def out_dir() -> str:
    d = os.environ.get("GPB023_OUT", os.path.join(HERE, "results", "gpb023"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb023"), exist_ok=True)
    return d


def grid_quad(nx: int, w: float, A: float, D: float) -> np.ndarray:
    half = nx // 2
    p = (np.arange(nx) - half).astype(float)
    P, Q = np.meshgrid(p, p)
    X = P * w
    return D * X * X + A * X


def stream_grid(nx: int = 9, w: float = W, k: float = 0.05) -> np.ndarray:
    """Channel invariant along y (stream direction)."""
    half = nx // 2
    p = (np.arange(nx) - half).astype(float)
    P, _Q = np.meshgrid(p, p)
    X = P * w
    return k * X * X


def horn_fields(h: np.ndarray, w: float) -> tuple[np.ndarray, np.ndarray]:
    rows, cols = h.shape
    dx = np.full((rows, cols), np.nan)
    dy = np.full((rows, cols), np.nan)
    for r in range(1, rows - 1):
        for c in range(1, cols - 1):
            a, b, cc = h[r - 1, c - 1], h[r - 1, c], h[r - 1, c + 1]
            d, f = h[r, c - 1], h[r, c + 1]
            g, hh, i = h[r + 1, c - 1], h[r + 1, c], h[r + 1, c + 1]
            dx[r, c] = horn_dzdx(a, b, cc, d, f, g, hh, i, w)
            dy[r, c] = horn_dzdy(a, b, cc, d, f, g, hh, i, w)
    return dx, dy


def zt_curv_signedmax(h: np.ndarray, w: float = W) -> float:
    hxx, _hyy, _hxy = numeric_zt(h, w, w)
    interior = hxx[1:-1, 1:-1]
    return float(np.max(interior))


def horn_d2_compress(h: np.ndarray, w: float = W) -> float:
    """Horn Dx of the centre 3x3 (quadratic-exact slope; not max over the grid)."""
    dx, _dy = horn_fields(h, w)
    r = h.shape[0] // 2
    c = h.shape[1] // 2
    return float(abs(dx[r, c]))


def slope_sq_min(h: np.ndarray, w: float = W) -> float:
    dx, dy = horn_fields(h, w)
    sq = dx[1:-1, 1:-1] ** 2 + dy[1:-1, 1:-1] ** 2
    return float(np.nanmin(sq))


def along_stream_drop(h: np.ndarray, w: float = W) -> tuple[bool, str]:
    _hxx, hyy, _hxy = numeric_zt(h, w, w)
    _dx, dy = horn_fields(h, w)
    hyy_i = hyy[1:-1, 1:-1]
    dy_i = dy[1:-1, 1:-1]
    zt_ok = float(np.max(np.abs(hyy_i))) < 1e-12
    horn_ok = float(np.nanmax(np.abs(dy_i))) < 1e-12
    ok = zt_ok and horn_ok
    return ok, "zt_Hyy=%.3e horn_Dy=%.3e" % (
        float(np.max(np.abs(hyy_i))),
        float(np.nanmax(np.abs(dy_i))),
    )


def fmt_zt(x: float) -> str:
    return ("%.2e" % x).replace("e-0", "e-").replace("e+0", "e+")


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p_comp_3.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p_comp_3.wl"
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    try:
        proc = subprocess.run(
            [exe, "-file", wl],
            capture_output=True,
            text=True,
            timeout=120,
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
    print("  wolfram foundDiff:", parsed.get("foundDiff"))
    print("  wolfram nDiff:", parsed.get("nDiff"))
    print("  wolfram alongStreamZero:", parsed.get("alongStreamZero"))
    path = os.path.join(dest, "p_comp_3_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p_comp_3_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "ZTNotHornStencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("PCOMP3_MANIM", "0") != "1":
        print("  manim: skip (set PCOMP3_MANIM=1 to render)")
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
            dest, "videos", "p_comp_3_manim", "480p15", "ZTNotHornStencil.mp4"
        )
        fig_dir = os.path.join(HERE, "figures")
        fig = os.path.join(fig_dir, "ZTNotHornStencil.mp4")
        if os.path.isfile(src):
            os.makedirs(fig_dir, exist_ok=True)
            shutil.copy2(src, fig)
            info["figure"] = fig
            print("  manim copied ->", fig)
    return info


def gates(a: tuple[float, float], b: tuple[float, float], stream: tuple[bool, str],
          slope_ok: bool) -> list:
    zt_a, horn_a = a
    zt_b, horn_b = b
    return [
        (
            "zt_curv_signedmax vs horn_d2_compress on grid-A",
            abs(zt_a - 1.41e-2) < 5e-5 and abs(horn_a - 0.21) < 1e-9,
            "ZT %s, Horn %.2f" % (fmt_zt(zt_a), horn_a),
        ),
        (
            "zt_curv_signedmax vs horn_d2_compress on grid-B",
            abs(zt_b - 6.97e-2) < 5e-5 and abs(horn_b - 0.07) < 1e-9,
            "ZT %s, Horn %.2f" % (fmt_zt(zt_b), horn_b),
        ),
        (
            "geometric_persistence:both-sides drop to 0 along stream direction",
            stream[0],
            stream[1],
        ),
        (
            "P-001 slopeSq>=0 on both grids (shared root; not a P-001 counterexample)",
            slope_ok,
            "min_slopeSq>=0",
        ),
    ]


def main() -> int:
    t0 = time.time()
    dest = out_dir()
    print("==[P-COMP-3] GPB-023 ZT curvature does not entail Horn slope ==")

    h_a = grid_quad(GRID_A["nx"], W, GRID_A["A"], GRID_A["D"])
    h_b = grid_quad(GRID_B["nx"], W, GRID_B["A"], GRID_B["D"])
    h_s = stream_grid()

    zt_a = zt_curv_signedmax(h_a)
    horn_a = horn_d2_compress(h_a)
    zt_b = zt_curv_signedmax(h_b)
    horn_b = horn_d2_compress(h_b)
    stream = along_stream_drop(h_s)
    slope_ok = slope_sq_min(h_a) >= -1e-15 and slope_sq_min(h_b) >= -1e-15

    print("---- grid-A A=%.2f D=%.5f ----" % (GRID_A["A"], GRID_A["D"]))
    print("  ZT signedmax Hxx=%s  Horn |Dx|=%.4f" % (fmt_zt(zt_a), horn_a))
    print("---- grid-B A=%.2f D=%.5f ----" % (GRID_B["A"], GRID_B["D"]))
    print("  ZT signedmax Hxx=%s  Horn |Dx|=%.4f" % (fmt_zt(zt_b), horn_b))
    print("---- stream (invariant along y) ----")
    print("  %s" % stream[1])
    print("  P-001 min slopeSq A=%.3e B=%.3e" % (slope_sq_min(h_a), slope_sq_min(h_b)))

    print("---- wolframscript exhaustive ZT vs Horn ----")
    wolfram = eval_wolfram(dest)
    print("---- manim ----")
    manim_info = maybe_manim(dest)

    gs = gates((zt_a, horn_a), (zt_b, horn_b), stream, slope_ok)
    print("---- gates ----")
    ok = True
    for name, passed, detail in gs:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
        ok = ok and passed

    parsed = wolfram.get("parsed") or {}
    if wolfram.get("available"):
        w_ok = parsed.get("foundDiff") is True and parsed.get("alongStreamZero") is True
        print(
            "  [%s] wolfram foundDiff + alongStreamZero  (diff=%s n=%s stream=%s)"
            % (
                "PASS" if w_ok else "FAIL",
                parsed.get("foundDiff"),
                parsed.get("nDiff"),
                parsed.get("alongStreamZero"),
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

    diverged = abs(zt_a - horn_a) > 1e-3 and abs(zt_b - horn_b) > 1e-4
    ok = ok and diverged

    payload = {
        "id": "GPB-023",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "grid_a": {"zt": zt_a, "horn": horn_a},
        "grid_b": {"zt": zt_b, "horn": horn_b},
        "stream": {"ok": stream[0], "detail": stream[1]},
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gs],
        "entry": "NEGATIVE-RESULT PASS" if ok else "FAIL",
        "note": (
            "P-COMP-3: ZT Hessian and Horn slope are not mutually entailed. "
            "Negative result is a feature — composition boundary, not a kernel bug."
        ),
    }
    for path in (
        os.path.join(dest, "gpb023_metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb023"), "gpb023_metrics.json")
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

        hxx_a, _hyy_a, _ = numeric_zt(h_a, W, W)
        dx_a, _dy_a = horn_fields(h_a, W)
        fig, axs = plt.subplots(1, 2, figsize=(9.2, 3.8))
        im0 = axs[0].imshow(hxx_a[1:-1, 1:-1], cmap="coolwarm")
        axs[0].set_title("ZT Hxx  grid-A")
        im1 = axs[1].imshow(dx_a[1:-1, 1:-1], cmap="viridis")
        axs[1].set_title("Horn Dx  grid-A")
        for ax, im in zip(axs, (im0, im1)):
            fig.colorbar(im, ax=ax, fraction=0.046)
            ax.set_xticks([])
            ax.set_yticks([])
        fig.suptitle("P-COMP-3: ZT curvature vs Horn slope (not mutually entailed)")
        fig.tight_layout()
        png = os.path.join(dest, "gpb023_zt_vs_horn.png")
        fig.savefig(png, dpi=120)
        plt.close(fig)
        print("plot ->", png)
    except Exception as err:
        print("plot skip:", err)

    print("GPB-023 ENTRY:", "NEGATIVE-RESULT PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
