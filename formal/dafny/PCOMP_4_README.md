# P-COMP-4 · 重采样同伦(GPB-025)

> 对偶:`../lean4/VeriGIS/Composition/ResampleHomotopy.lean`
> 实验:`../../experiments/phase2/p_comp_4.py`

`R_α` 把格网间距 `w` 换成 `α w`。平面上 Horn 仍精确恢复 `(A,B)`,D8 平移不变。
45° 栅格旋转会混进多个 D8 码,数值端记 **FAIL-TOLERANCE**(不是实现 bug)。

不复制 P-001 / P-004 / P-005 核。不 include P-001(文件级 `Main` 冲突),走 P-004 `QuadraticExact`。
