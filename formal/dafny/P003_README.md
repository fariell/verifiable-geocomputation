# P-003 · Zevenbergen–Thorne Hessian

> 对偶:`../lean4/VeriGIS/Curvature.lean`
> 实验:`../../experiments/phase1/p003_curvature.py`(numpy 门控;可选 `wolframscript` + Manim)

## 证了什么

| 引理 | 命题 | 说明 |
|---|---|---|
| `QuadraticExact` / `quadratic_hxx` 等 | GPB-007 | 二次面上海森矩阵**恒等**恢复 `(2A, 2B, C)` |
| `ParaboloidApex` | GPB-007 特例 | `h = F0 - k(x²+y²)` 顶点 `Hxx = Hyy = -2k` |
| `LaplacianAtDiscreteMax` | GPB-005 的可证核 | 离散局部极大 ⇒ Laplacian ≤ 0 |
| `CenterPerturbHxx` | 噪声机制 | `e ↦ e+δ` ⇒ `ΔHxx = -2δ/w²` |
| `Phase1StencilSwapsAxes` | Phase 1 诊断 | 旧模板在二次面上恢复的是对轴 |

## 没证什么

- **GPB-020**(一般 C² 上剖面曲率 w→0 收敛):入口实验在 dx=1 上 corr≈0.157,不能当第一引理。
- 剖面曲率在驻点的符号:公式是 0/0,GIS 符号公约还分裂。

## 跑

```bash
dafny verify formal/dafny/P003_curvature.dfy
# AutoDL
python3 scripts/autodl/jupyter_progress.py \
  'bash /root/verigis/repo/experiments/phase1/run_p003.sh'
```

本机若有 Wolfram:`p003_curvature.py` 会 `subprocess` 调 `wolframscript -file p003_taylor.wl`。
本机若有 Manim:`P003_MANIM=1` 渲染 `p003_manim.py`。缺这两样不挡门控。
