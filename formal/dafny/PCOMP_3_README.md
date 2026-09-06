# P-COMP-3 · ZT ⇏ Horn(GPB-023)

> 对偶:`../lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean`(独立重述,不翻译 Dafny)
> 实验:`../../experiments/phase2/p_comp_3.py`
> 种子:`P003_curvature.dfy` · `P004_consistency.dfy`

## 它不是 bug,是 feature — 展示了组合命题的边界

P-003 与 P-004 各自为真。把它们拼成"ZT 曲率 ⇒ Horn 二次斜率"(或反过来)
会失败,因为两个算子根本不是同一函数族:一个读 Hessian,一个读一阶
Horn 差分(只是在二次面上精确)。失败本身是 Phase 2 的科学资产——
能机器组合的命题(P-COMP-1)和不能组合的命题(本条)必须并存,论文
§7.4.2 / §9 用这条当对照。

## 证了什么(否定式)

| 引理 | 说明 | 来源(import,不复制核) |
|---|---|---|
| `ztNotHorn` | 平面 z=Dx·x 上 Hxx=0 且 DzDx=Dx≠0 | P-003 `PlaneHessianZero` + P-004 `QuadraticExact` |
| `negResult` | 存在 witness(w=1,Dx=0.21) | 上一条 |
| `bothHaveSlopeGeZero` | Horn Dx²+Dy² ≥ 0(P-001 根,不 include P-001:文件级 Main 冲突) | P-004 `DzDx`/`DzDy` |

## 没证什么

- 不证"任意 C² 曲面上曲率与坡度无函数关系"的元定理。
- 不否定 P-003 二次面 Hessian 精确,也不否定 P-004 二次面斜率精确。
- 一般大小 DEM、浮点实现、GIS 剖面曲率符号公约,都不在范围内。

## 跑

```bash
dafny verify formal/dafny/PCOMP_3.dfy
cd formal/lean4 && lake build
python3 experiments/phase2/p_comp_3.py
# PCOMP3_MANIM=1 python experiments/phase2/p_comp_3.py
```
