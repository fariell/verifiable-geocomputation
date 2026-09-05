#!/usr/bin/env python3
"""GeoProofBench v0.1 — batch 1 proposition stubs (Phase 1 deliverable, M3 subset).

Generates 20 candidate propositions about DEM terrain operators, each with a
stable id, a natural-language statement, the operator it targets, a difficulty
estimate, and a formalization status. These are the raw material that the
GeoProofBench benchmark (P2 paper) will formalize in Lean 4 / Dafny.

Output: results/geoproofbench_v0.1_batch1.json  (+ .csv + .md summary)
"""
import os
import json
import csv

VERIGIS_HOME = os.environ.get("VERIGIS_HOME", "/root/verigis")
OUT_JSON = os.path.join(VERIGIS_HOME, "results", "geoproofbench_v0.1_batch1.json")
OUT_CSV = os.path.join(VERIGIS_HOME, "results", "geoproofbench_v0.1_batch1.csv")
OUT_MD = os.path.join(VERIGIS_HOME, "results", "geoproofbench_v0.1_batch1.md")

# id, operator, difficulty(1-5), statement
RAW = [
    ("GPB-001", "slope", 1, "For any DEM cell with finite elevation gradient, the slope magnitude is non-negative."),
    ("GPB-002", "slope", 2, "The slope magnitude of a constant-elevation surface is identically zero everywhere."),
    ("GPB-003", "aspect", 2, "Aspect is defined modulo 360 degrees and is undefined only where the gradient vanishes."),
    ("GPB-004", "aspect", 3, "For an east-facing planar slope, the computed aspect equals 90 degrees under the cartographic convention."),
    ("GPB-005", "curvature", 3, "Profile curvature is non-negative at a local elevation maximum of a smooth DEM."),
    ("GPB-006", "curvature", 3, "Plan (tangential) curvature is non-negative at a local elevation minimum of a smooth DEM."),
    ("GPB-007", "curvature", 4, "For a quadratic bump h = A - k*(x^2+y^2), the profile curvature at the apex equals -2k up to a sign convention."),
    ("GPB-008", "hillshade", 2, "Hillshade lies in [0,255] for any finite slope and any azimuth/altitude in their domains."),
    ("GPB-009", "hillshade", 3, "Hillshade of a flat surface equals 255 * sin(altitude) under the standard Horn shading model."),
    ("GPB-010", "flowdir", 3, "D8 flow direction at a local pit points to no downslope neighbor (undefined / no-flow)."),
    ("GPB-011", "flowdir", 4, "On a uniform planar slope the D8 flow direction is constant across all interior cells."),
    ("GPB-012", "viewshed", 4, "If point B is visible from A, then A is visible from B only when the line of sight is unobstructed in both directions (symmetry under mutual obstruction)."),
    ("GPB-013", "viewshed", 5, "Visibility is a reflexive relation only on the diagonal; for distinct points it is not guaranteed symmetric."),
    ("GPB-014", "contour", 3, "A closed contour encloses a region whose interior elevation is either entirely above or entirely below the contour level."),
    ("GPB-015", "watershed", 4, "Every interior cell belongs to exactly one watershed basin under a deterministic flow-routing rule."),
    ("GPB-016", "tpi", 2, "Topographic Position Index is zero on a planar (constant-curvature) surface."),
    ("GPB-017", "ruggedness", 2, "Terrain Ruggedness Index is non-negative and zero on a planar surface."),
    ("GPB-018", "resampling", 3, "Bilinear resampling of a planar surface at a coarser resolution preserves the plane (no introduced curvature)."),
    ("GPB-019", "slope", 4, "The Horn (1981) finite-difference slope operator is a consistent estimator of the analytic slope as the grid spacing tends to zero."),
    ("GPB-020", "curvature", 5, "The discrete profile-curvature operator converges to the analytic profile curvature of a C^2 surface in the limit of vanishing grid spacing."),
]

STATUS = "candidate"  # candidate -> drafted -> formalized -> proved


def main():
    records = []
    for pid, op, diff, stmt in RAW:
        records.append({
            "id": pid,
            "operator": op,
            "difficulty": diff,
            "statement": stmt,
            "status": STATUS,
            "formal_lang": None,
            "proved": False,
        })
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump({"version": "0.1", "batch": 1, "count": len(records),
                   "propositions": records}, f, indent=2, ensure_ascii=False)

    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "operator", "difficulty", "status", "statement"])
        for r in records:
            w.writerow([r["id"], r["operator"], r["difficulty"], r["status"], r["statement"]])

    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write("# GeoProofBench v0.1 — Batch 1 (Phase 1 seed set)\n\n")
        f.write("Total: %d candidate propositions. Status: `%s`.\n\n" % (len(records), STATUS))
        f.write("| ID | Operator | Difficulty | Statement |\n")
        f.write("|----|----------|-----------|-----------|\n")
        for r in records:
            f.write("| %s | %s | %d | %s |\n" % (r["id"], r["operator"], r["difficulty"], r["statement"]))

    print("GeoProofBench v0.1 batch1: wrote %d propositions ->" % len(records))
    print("  " + OUT_JSON)
    print("  " + OUT_CSV)
    print("  " + OUT_MD)


if __name__ == "__main__":
    main()
