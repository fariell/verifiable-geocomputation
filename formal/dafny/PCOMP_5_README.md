# P-COMP-5 · 填洼元一致(GPB-026)

> 对偶:`../lean4/VeriGIS/Composition/PitFillingIdempotent.lean`
> 实验:`../../experiments/phase2/p_comp_5.py`

- 幂等:`Fill(Fill(a)) = Fill(a)`(ℤ 严格;ℝ 上 ε_tol)
- 调度无关:双亲抬升 `max(orig, p1, p2)` 交换(堆 tie-break 数值对照)
- 三码 hash:四条 1D 实例 Python prefix-max / Dafny Fill / Lean fill 同值

不复制 Fill / RaiseNbr 核。
