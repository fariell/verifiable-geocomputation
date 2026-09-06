# P-COMP-3 · ZT 曲率 ⇏ Horn 二次斜率(GPB-023)

> 任务 8A。这是组合命题矩阵里**唯一的否定式**。阴性结果是素材,不是失败。

## 目标

同一 DEM 上,P-003 Zevenbergen–Thorne 剖面/Hessian 曲率与 P-004 Horn
二次精度斜率**不是同一函数族**,没有可形式化的互推。P-001 的 slope≥0
两边都还成立——反例不推翻种子层,只划组合边界。

## 边界

- 不复制 P-003 / P-004 核,只 `import` / `include` 已证引理。
- 不宣称"曲率没用"或"Horn 错了"。两个算子各自在自己的命题里为真。
- 不证一般 C² 曲面的互推不存在(那是元定理);本条给**可机器检验的 witness**。

## 产物清单

| # | 路径 | 类型 |
|---|---|---|
| 1 | `experiments/phase2/p_comp_3.py` | driver,三门控 + P-001 约束 |
| 2 | `experiments/phase2/p_comp_3.wl` | 4^4 穷举 ZT≠Horn |
| 3 | `experiments/phase2/p_comp_3_manim.py` | 左 ZT 热图 / 右 Horn 拟合 |
| 4 | `experiments/phase2/run_p_comp_3.sh` | `GPB-023 ENTRY: NEGATIVE-RESULT PASS` |
| 5 | `formal/dafny/PCOMP_3.dfy` | `Witness` + `ztNotHorn` |
| 6 | `formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean` | 独立重述 |
| 7 | `formal/dafny/PCOMP_3_README.md` | 台账 |

## 没证什么(开篇)

**它不是 bug,是 feature。** 组合命题有能拼的(P-COMP-1)也有不能拼的
(本条)。Sci Data / 论文 §7.4.2 要的就是这条边界案例。
