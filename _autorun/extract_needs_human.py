# -*- coding: utf-8 -*-
"""秘书辅助工具:把 VERIFIED_NEEDS_HUMAN 记录整理成 PI 可判定的对照表。

只读,不改任何实验结果。输出 _autorun/needs_human_review.md。
用法: PYTHONIOENCODING=utf-8 python _autorun/extract_needs_human.py
"""
import json
import os
import re
from datetime import datetime, timezone

ROOT = r"E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation"
RAW = os.path.join(ROOT, "experiments", "p2_llm", "results", "raw")
TASKS = os.path.join(ROOT, "experiments", "p2_llm", "tasks")
JSONL = os.path.join(RAW, "l1_full_w3_live.jsonl")
OUT = os.path.join(ROOT, "_autorun", "needs_human_review.md")

last = {}
with open(JSONL, encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        try:
            r = json.loads(line)
        except Exception:
            continue
        key = (r.get("model"), r.get("task_id"), r.get("prompt_id"), r.get("sample_index"))
        last[key] = r

nh = [(k, v) for k, v in last.items() if v.get("semantic") == "VERIFIED_NEEDS_HUMAN"]
nh.sort(key=lambda x: (x[0][1], x[0][2], x[0][3] or 0))

DECL = re.compile(r"^\s*(lemma|method|function|predicate|twostate\s+lemma|least\s+predicate)\s")
SPEC = ("requires", "ensures", "modifies", "reads", "decreases", "returns", "free requires", "free ensures")


def natural_spec(task_id):
    p = os.path.join(TASKS, task_id + ".yaml")
    if not os.path.exists(p):
        return "(未找到 task yaml)"
    txt = open(p, encoding="utf-8").read()
    m = re.search(r"natural_spec:\s*\|\n((?:[ \t]+.*\n?)+)", txt)
    if m:
        return " ".join(l.strip() for l in m.group(1).splitlines() if l.strip())
    m = re.search(r"natural_spec:\s*(.+)", txt)
    return m.group(1).strip() if m else "(未找到 natural_spec)"


def specs_of(path):
    try:
        txt = open(path, encoding="utf-8", errors="replace").read()
    except Exception:
        return "(读不到 .dfy)", 0, 0, 0
    lines = txt.splitlines()
    blocks = []
    i = 0
    while i < len(lines):
        if DECL.match(lines[i]):
            blk = [lines[i].strip()]
            j = i + 1
            while j < len(lines) and not re.match(r"^\s*\{", lines[j]):
                s = lines[j].strip()
                if s.startswith(SPEC):
                    # multi-line spec clause: keep consuming until parens balance
                    buf = s
                    while buf.count("(") > buf.count(")"):
                        if j + 1 >= len(lines):
                            break
                        nxt = lines[j + 1].strip()
                        if nxt.startswith("{"):
                            break
                        j += 1
                        buf += " " + nxt
                    blk.append("    " + buf)
                j += 1
            blocks.append("\n".join(blk))
            i = j
        else:
            i += 1
    n_assume = len(re.findall(r"\bassume\b", txt))
    n_axiom = len(re.findall(r"\baxiom\b", txt))
    n_lines = len(lines)
    return ("\n\n".join(blocks) if blocks else "(未提取到声明)"), n_assume, n_axiom, n_lines


groups = {}
for (model, task_id, prompt_id, sample_index), v in nh:
    groups.setdefault(task_id, []).append((model, prompt_id, sample_index, v))

ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
out = []
out.append("# VERIFIED_NEEDS_HUMAN 人工判定表\n")
out.append(
    "> **本表共 %d 条**,生成于 **%s**。"
    "重跑会使条数变化,以最新版为准。\n" % (len(nh), ts)
)
out.append("由 `_autorun/extract_needs_human.py` 自动生成,只读,不改实验数据。\n")
out.append("共 **%d 条**,来自 %d 个题目。\n" % (len(nh), len(groups)))

out.append("\n## 判定方法(照着做)\n")
out.append("对每一条,只回答一个问题:**它证明的还是原来那个命题吗?**\n")
out.append("看三处,按这个顺序:\n")
out.append("1. **`ensures` 是否等价于 gold 结论**。弱化(把 `== 0` 写成 `>= 0`)、"
           "加限定(只在某分支成立)、换成另一个量,都算漂移。\n")
out.append("2. **`requires` 是否引入了 gold 没有的假设**。多加一个前提让命题变简单,算漂移;")
out.append("   只是把 gold 里隐含的条件(如 `w > 0`)写明,**不算**漂移。\n")
out.append("3. **有没有作弊**。下表的红旗列标了 `assume` / `axiom` 出现次数。")
out.append("   只要证明体里用 `assume` 断言了结论本身,无论机器是否通过,一律判 DRIFT。\n")
out.append("\n判定写 ALIGNED / DRIFT / UNDECIDABLE 三者之一,填进每条的「判定」栏。\n")
out.append("**UNDECIDABLE 是合法答案**,不要为了凑数硬判。\n")

for task_id in sorted(groups):
    rows = groups[task_id]
    out.append("\n---\n")
    out.append("\n## %s  (%d 条)\n" % (task_id, len(rows)))
    out.append("\n**gold 命题(natural_spec):**\n")
    out.append("\n> %s\n" % natural_spec(task_id))
    for model, prompt_id, sample_index, v in rows:
        src = v.get("raw_source") or ""
        base = os.path.basename(src) if src else "(无路径)"
        full = os.path.join(RAW, base)
        spec, n_assume, n_axiom, n_lines = specs_of(full) if os.path.exists(full) else ("(文件不在盘上)", 0, 0, 0)
        flags = []
        if n_assume:
            flags.append("assume ×%d" % n_assume)
        if n_axiom:
            flags.append("axiom ×%d" % n_axiom)
        out.append("\n### %s · %s · k%s\n" % (model.split("/")[-1], prompt_id, sample_index))
        out.append("\n- 文件:`%s`(%d 行)" % (base, n_lines))
        out.append("- 红旗:**%s**" % ("、".join(flags) if flags else "无"))
        out.append("- **判定**:____________\n")
        out.append("\n```dafny\n%s\n```\n" % spec)

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write("\n".join(out))

print("wrote", OUT)
print("records:", len(nh), "tasks:", len(groups))
for t in sorted(groups):
    print("  %s: %d" % (t, len(groups[t])))
