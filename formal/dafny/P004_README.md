# P-004 · Horn 坡度 w→0 相容性(GPB-019 代数核)

> 对偶:`../lean4/VeriGIS/Consistency.lean`
> 实验:`../../experiments/phase1/p004_consistency.py`(numpy 门控;可选 `wolframscript` + Manim)
> 状态:AutoDL 2026-09-06 13:08 · Dafny **22 verified / 0 errors**;Lean **Built VeriGIS.Consistency**;**GPB-019 ALGEBRA ENTRY: PASS**

## 证了什么

| 引理 | 命题 | 说明 |
|---|---|---|
| `QuadraticExact` / `quadratic_exact` | GPB-019 | 二次面上 Horn **恒等**恢复 `(A, B)` |
| `CubicXRemainder` / `cubicX_remainder` | GPB-019 | `z = G x³` 时 `DzDx = G w²`(原点真值 0) |
| Wolfram `p004_taylor.wl` | GPB-019 | 一般余项 `(2 hxxx + 3 hxyy) w² / 12` |
| `CubicErrorShrinks` | GPB-019 | `0 < w2 < w1` ⇒ 余项绝对值不增 |
| `cubic_error_tendsto_zero` | GPB-019 | Lean:`Tendsto (G w²) (nhds 0) (nhds 0)` |

## 没证什么

任意 C² 曲面的一致估计(需要余项公式 + 三阶导一致有界)。P-001 平面精确是本文件的次数-1 特例。GPB-020 曲率收敛仍不在范围内。

## 跑

```bash
dafny verify formal/dafny/P004_consistency.dfy
cd formal/lean4 && lake build
python3 experiments/phase1/p004_consistency.py
# 本机有 Wolfram / Manim 时:
#   自动 subprocess wolframscript -file p004_taylor.wl
#   P004_MANIM=1 python experiments/phase1/p004_consistency.py
```
