# P-COMP-2 · 全平面闭包(GPB-022)

> 对偶:`../lean4/VeriGIS/Composition/PitFillingThenWatershedPlane.lean`(独立重述,不翻译 Dafny)
> 实验:`../../experiments/phase2/p_comp_2.py`
> 种子:`P002_pit_filling.dfy` · `P005_d8.dfy` · `P006_terminate_under_strict.dfy`

## 组合策略

```
P-005 PlaneConstant / PitNoFlow   流向在全平面上恒定(0 起伏 = 全 NoFlow)
        ↓
P-002 FillFixpoint                非降 / 常数带 Fill 恒等(无新坑)
        ↓
P-006 T6 HeightSucc + Bound       西向/行扰动 1D 后继有限步卡住
        ↓
P-006 BasinUnique                 两个不动点出口必相等
```

与 P-COMP-1 的差别:P-COMP-1 在 5×5 斜面上证「填洼 ⇒ 流域唯一」;
P-COMP-2 把同一接口拉到**全平面**(无局部起伏)和**行扰动** ε∈{1e-6,1e-4}。
形式化不写 256:定理对任意 `c:nat` 成立,数值端取 256²。

## 证了什么

| 步骤 | 引理 | 来源(import,不复制核) |
|---|---|---|
| 0 起伏 NoFlow | `FlatWindowNoFlow` | P-005 `PitNoFlow` + `Uphill` |
| 平面恒定 | `PlaneFlowIndependentOfOffset` | P-005 `PlaneConstant` |
| 西向实例 | `PlaneWestConstant` | P-005 `PlaneWest` |
| Fill 恒等 | `MonotoneStripFillIdentity` | P-002 `FillFixpoint` |
| 每格终止 | `WestPlaneEveryCellTerminates` | T6 `HeightSucc` + `TerminatesUnderStrictDescent` |
| 256-cell | `WestPlane256Terminates` | 上一条 c=255 |
| Bound=c | `WestPlaneBoundEq` | T6 `HeightBoundEq` |
| 出口唯一 | `WestPlaneOutletUnique` | P-006 `BasinUnique` |

## 没证什么

- 种子层没有整幅 256² `pitFill2D` / 格网 `basin`。256² 闭包是数值 driver 的门控,形式化落在窗口 D8 + 1D Fill + 抽象 `succ`。
- 浮点 ε=1e-6 行扰动不是 Dafny `real` 定理;它对应「加一个严格单调节奏」= `HeightSucc`。
- 填洼后等高平台上工业 flat-routing 仍不在范围内(与 P-COMP-1 同一缺口)。

## 跑

```bash
dafny verify formal/dafny/PCOMP_2.dfy
cd formal/lean4 && lake build
python3 experiments/phase2/p_comp_2.py
```
