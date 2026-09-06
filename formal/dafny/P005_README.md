# P-005 · D8 流向确定性与闭合核

> 对偶:`../lean4/VeriGIS/D8.lean`
> 实验:`../../experiments/phase1/p005_d8.py`(numpy 门控;可选 `wolframscript` + Manim)

## 证了什么

| 引理 | 命题 | 说明 |
|---|---|---|
| `PitNoFlow` / `pit_no_flow` | GPB-010 | 八邻都不低于中心 ⇒ `NoFlow` |
| `PlaneConstant` / `plane_constant` | GPB-011 | 平面只差高程基准 C,流向不变 |
| `PlaneWest` / `example_plane_west` | GPB-011 | `A>0,B=0` ⇒ 西 |
| `PlaneNorthwest` / `example_plane_northwest` | GPB-011 | `A=B>0` ⇒ 西北 |
| `FlowDescent` | 闭合核 | 一旦选出方向,该邻格严格低于中心 |

并列时扫描序 `E,SE,S,SW,W,NW,N,NE` 里更早者胜。比较用 `drop²/dist2`,不用 √2。

## 没证什么

平坦处的全局无环(未填洼的 D8 可以在 flat 上转圈)。流域唯一是 GPB-015。

## 跑

```bash
dafny verify formal/dafny/P005_d8.dfy
cd formal/lean4 && lake build
python3 experiments/phase1/p005_d8.py
# P005_MANIM=1 python experiments/phase1/p005_d8.py
```
