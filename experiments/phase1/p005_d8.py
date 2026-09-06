#!/usr/bin/env python3
"""P-005 / GPB-010+011 entry: D8 pit has no flow; plane flow is constant.

Algebraic half: formal/dafny/P005_d8.dfy and formal/lean4/VeriGIS/D8.lean.

  1. 3×3 pit: rim 1, centre 0 → NoFlow.
  2. Plane A>0 B=0: every interior cell flows west.
  3. Plane A=B>0: every interior cell flows northwest.
  4. Optional wolframscript argmax; optional Manim (P005_MANIM=1).
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

DIRS = (
    ("E", 1, 0, 1.0),
    ("SE", 1, 1, 2.0),
    ("S", 0, 1, 1.0),
    ("SW", -1, 1, 2.0),
    ("W", -1, 0, 1.0),
    ("NW", -1, -1, 2.0),
    ("N", 0, -1, 1.0),
    ("NE", 1, -1, 2.0),
)


def out_dir() -> str:
    d = os.environ.get("GPB005_OUT", os.path.join(HERE, "results", "gpb005"))
    os.makedirs(d, exist_ok=True)
    wb = os.path.expanduser("~/.workbuddy")
    if os.path.isdir(wb):
        os.makedirs(os.path.join(wb, "gpb005"), exist_ok=True)
    return d


def d8_at(h: np.ndarray, r: int, c: int) -> str:
    e = float(h[r, c])
    best, best_p = "NoFlow", 0.0
    for name, dp, dq, dist2 in DIRS:
        rr, cc = r + dq, c + dp
        if not (0 <= rr < h.shape[0] and 0 <= cc < h.shape[1]):
            continue
        drop = e - float(h[rr, cc])
        if drop <= 0:
            continue
        p = (drop * drop) / dist2
        if best == "NoFlow" or p > best_p:
            best, best_p = name, p
    return best


def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl = os.path.join(HERE, "p005_d8.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:
        print("  wolframscript: skip (%s)" % payload["reason"])
        return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing p005_d8.wl"
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
        print("  wolfram west:", payload["parsed"].get("planeWest"))
        print("  wolfram nw:", payload["parsed"].get("planeNorthwest"))
    path = os.path.join(dest, "p005_wolfram.txt")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
        if proc.stderr:
            fh.write("--- stderr ---\n")
            fh.write(proc.stderr)
    return payload


def maybe_manim(dest: str) -> dict:
    info = {"rendered": False, "cmd": None}
    scene = os.path.join(HERE, "p005_manim.py")
    cmd = [
        sys.executable,
        "-m",
        "manim",
        "-ql",
        "--disable_caching",
        "--media_dir",
        dest,
        scene,
        "D8Stencil",
    ]
    info["cmd"] = " ".join(cmd)
    if os.environ.get("P005_MANIM", "0") != "1":
        print("  manim: skip (set P005_MANIM=1 to render)")
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


def gates(pit: str, west: list[str], nw: list[str]) -> list:
    return [
        ("pit centre is NoFlow", pit == "NoFlow", "got=%s" % pit),
        (
            "plane A>0 B=0 interior all W",
            all(x == "W" for x in west) and len(west) > 0,
            "n=%d uniq=%s" % (len(west), sorted(set(west))),
        ),
        (
            "plane A=B>0 interior all NW",
            all(x == "NW" for x in nw) and len(nw) > 0,
            "n=%d uniq=%s" % (len(nw), sorted(set(nw))),
        ),
    ]


def plane_grid(A: float, B: float, C: float, n: int = 7, w: float = 1.0) -> np.ndarray:
    p = (np.arange(n) - n // 2).astype(float)
    q = (np.arange(n) - n // 2).astype(float)
    P, Q = np.meshgrid(p, q)
    return A * P * w + B * Q * w + C


def interior_flows(h: np.ndarray) -> list[str]:
    out = []
    for r in range(1, h.shape[0] - 1):
        for c in range(1, h.shape[1] - 1):
            out.append(d8_at(h, r, c))
    return out


def main() -> int:
    t0 = time.time()
    dest = out_dir()
    print("==[P-005] D8 pit NoFlow + planar constant direction ==")

    pit = np.ones((3, 3))
    pit[1, 1] = 0.0
    pit_flow = d8_at(pit, 1, 1)
    print("---- pit 3x3 ----")
    print("  centre flow:", pit_flow)

    h_west = plane_grid(0.4, 0.0, 12.0)
    west = interior_flows(h_west)
    h_nw = plane_grid(0.4, 0.4, -3.0)
    nw = interior_flows(h_nw)
    print("---- plane interiors ----")
    print("  A>0 B=0 :", sorted(set(west)), "n=%d" % len(west))
    print("  A=B>0   :", sorted(set(nw)), "n=%d" % len(nw))

    print("---- wolframscript D8 argmax ----")
    wolfram = eval_wolfram(dest)
    print("---- manim ----")
    manim_info = maybe_manim(dest)

    gs = gates(pit_flow, west, nw)
    print("---- gates ----")
    ok = True
    for name, passed, detail in gs:
        print("  [%s] %s  (%s)" % ("PASS" if passed else "FAIL", name, detail))
        ok = ok and passed

    payload = {
        "id": "GPB-010/011",
        "utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "elapsed_s": round(time.time() - t0, 3),
        "pit": pit_flow,
        "plane_west": sorted(set(west)),
        "plane_nw": sorted(set(nw)),
        "wolfram": {k: wolfram[k] for k in wolfram if k not in ("stdout", "stderr")},
        "manim": manim_info,
        "gates": [{"name": n, "pass": p, "detail": d} for n, p, d in gs],
        "entry": "PASS" if ok else "FAIL",
        "note": (
            "D8 is NoFlow on a pit. On a plane the interior direction is "
            "constant (translation in C). Not a global DAG on flats."
        ),
    }
    for path in (
        os.path.join(dest, "gpb005_metrics.json"),
        os.path.join(os.path.expanduser("~/.workbuddy/gpb005"), "gpb005_metrics.json")
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

    print("GPB-010/011 ENTRY:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
