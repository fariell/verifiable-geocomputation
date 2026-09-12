# -*- coding: utf-8 -*-
"""Read-only: recompute A.17.19.2 Dafny-track writing baseline."""
import json
from pathlib import Path
from collections import Counter

try:
    import yaml
except ImportError:
    yaml = None

ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / "experiments" / "p2_llm" / "tasks"
JSONL = ROOT / "experiments" / "p2_llm" / "results" / "raw" / "l1_full_w3_live.jsonl"


def load_targets():
    targets = {}
    for p in TASKS.glob("*.yaml"):
        if yaml:
            d = yaml.safe_load(p.read_text(encoding="utf-8"))
            targets[d["id"]] = d.get("target", "?")
        else:
            txt = p.read_text(encoding="utf-8")
            tid = None
            tgt = None
            for line in txt.splitlines():
                if line.startswith("id:"):
                    tid = line.split(":", 1)[1].strip()
                if line.startswith("target:"):
                    tgt = line.split(":", 1)[1].strip()
            if tid:
                targets[tid] = tgt or "?"
    return targets


targets = load_targets()
dafny_tasks = {tid for tid, t in targets.items() if t == "dafny"}
lean_tasks = {tid for tid, t in targets.items() if t == "lean"}
print("Dafny", len(dafny_tasks), sorted(dafny_tasks))
print("Lean", len(lean_tasks), sorted(lean_tasks))

rows = [
    json.loads(l)
    for l in JSONL.read_text(encoding="utf-8").splitlines()
    if l.strip()
]
last = {}
for r in rows:
    k = (r.get("model"), r.get("task_id"), r.get("prompt_id"), r.get("sample_index"))
    last[k] = r

models = [
    "deepseek-ai/DeepSeek-R1",
    "deepseek-ai/DeepSeek-V3.2",
    "Qwen/Qwen2.5-72B-Instruct",
    "THUDM/GLM-4-32B-0414",
]

print("\n=== Dafny track dedup last-wins ===")
all_sem = Counter()
for m in models:
    cells = [v for k, v in last.items() if k[0] == m and k[1] in dafny_tasks]
    # RAN: real toolchain evaluation (compile_rc not null) — excludes Lean TOOLCHAIN_MISSING
    ran = [v for v in cells if v.get("compile_rc") is not None]
    c0 = sum(1 for v in ran if v.get("compile_rc") == 0)
    # verify: real verify_rc, not TOOLCHAIN_MISSING / VERIFY_SKIPPED
    with_v = [
        v
        for v in cells
        if v.get("verify_rc") is not None
        and v.get("verify_status") not in (None, "TOOLCHAIN_MISSING", "VERIFY_SKIPPED")
    ]
    # Also count verify among RAN cells where verify_rc==0
    v0 = sum(1 for v in cells if v.get("verify_rc") == 0)
    # verify@1 denominator = RAN (same as compile denominator per A.17.19 table)
    # Inbox table: verify@1 = 20.7% for R1 with RAN=116 → 20.7% of 116 ≈ 24
    v0_of_ran = sum(1 for v in ran if v.get("verify_rc") == 0)
    sem = Counter(v.get("semantic") for v in cells)
    all_sem.update(sem)
    print(f"\n{m}")
    print(f"  cell={len(cells)} RAN(compile_rc!=null)={len(ran)}")
    print(
        f"  compile@1={c0}/{len(ran)}={100*c0/len(ran):.1f}%"
        if ran
        else "  no RAN"
    )
    print(
        f"  verify@1(v0/RAN)={v0_of_ran}/{len(ran)}={100*v0_of_ran/len(ran):.1f}%"
        if ran
        else ""
    )
    print(f"  verify_rc==0 total={v0} with_v={len(with_v)}")
    print(f"  semantic={dict(sem)}")

print("\nALL dafny semantic:", dict(all_sem))
lean_cells = [v for k, v in last.items() if k[1] in lean_tasks]
print("Lean unique cells:", len(lean_cells))
print(
    "Lean TOOLCHAIN_MISSING:",
    sum(1 for v in lean_cells if v.get("verify_status") == "TOOLCHAIN_MISSING"),
)
print(
    "Lean GENERATED/SKIP:",
    sum(1 for v in lean_cells if v.get("status") in ("GENERATED", "SKIP_EXISTING")),
)
print("jsonl", len(rows), "unique", len(last))
print(
    "Dafny unique total",
    sum(1 for k in last if k[1] in dafny_tasks),
    "RAN total",
    sum(
        1
        for k, v in last.items()
        if k[1] in dafny_tasks and v.get("compile_rc") is not None
    ),
)
