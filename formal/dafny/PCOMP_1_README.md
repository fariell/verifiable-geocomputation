# P-COMP-1 · 填洼 ⇒ 流域唯一(GPB-021)

> 对偶:`../lean4/VeriGIS/Composition/PitFillingThenWatershed.lean`(独立重述,不翻译 Dafny)
> 实验:`../../experiments/phase2/p_comp_1.py`
> 第 6 条:`P006_terminate_under_strict.dfy`(步骤 (iii) 的良基上界)

## 组合策略

```
P-002 Fill / RaiseNbr          (i)  填后有不高的邻接
        ↓
P-005 FlowDescent              (ii) 选出方向 ⇒ 邻格严格更低
        ↓
P-006 T6 Bound  或  鸽笼        (iii) 轨道长度 ≤ 格数 / 高程
P-006 ChainSucc(2)=2 / PitNoFlow (iv) 出口集合非空
        ↓
P-006 BasinUnique              (v)  不重写:两个不动点出口必相等
```

反向引用:`P006_README.md` 的「没证什么」把第 6 条标成缺口;本命题用 T6 补上终止前提,再用层 A 的 `BasinUnique`。P-006b(flat 环)仍是未填洼时的科学反例,见实验左栏。

## 证了什么

| 步骤 | 引理 | 来源(import,不复制核) |
|---|---|---|
| (i) | `NoPitImpliesDescent` | P-002 `FillCorrect` 非降 |
| (i) 2D | `NoPitImpliesDescent2D` | P-002-bis `RaiseNbr` 冻结 + 单调 |
| (ii) | `D8PreservesDescent` | P-005 `FlowDescent` |
| (iii) | `OrbitLengthBound` | T6 `TerminatesUnderStrictDescent` |
| (iii') | `OrbitLengthBoundPigeon` | P-006 链 `TerminatesImpliesBasin`(T6 不适用坐标后继时) |
| (iv) | `BoundaryNonEmpty` | P-005 `ExamplePit` |
| (v) | `FillThenWatershed` | P-006 `BasinUnique` |

## 没证什么

- 种子层没有整幅 2D `pitFill2D` / 格网 `basin`。主定理落在已 export 的 Fill、RaiseNbr、D8 窗口、抽象 `succ` 上,不是新的 Dijkstra 堆。
- `ChainSucc` 升高下标,不满足 T6 的 `StrictDescent`;那种轨道走鸽笼,不走良基高程。
- 填洼产生的**等高平台**上,P-005 D8(`drop>0`)会给出 `NoFlow`,不等于工业上的 flat-routing。
- 一般大小 DEM、多出口竞争、浮点实现,都不在范围内。

## 跑

```bash
dafny verify formal/dafny/PCOMP_1.dfy
cd formal/lean4 && lake build
python3 experiments/phase2/p_comp_1.py
# PCOMP1_MANIM=1 python experiments/phase2/p_comp_1.py
```
