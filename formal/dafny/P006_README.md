# P-006 · 流域唯一性(GPB-015)

> 对偶:`../lean4/VeriGIS/Watershed.lean`(独立重述,不翻译 Dafny)
> 实验:`../../experiments/phase1/p006_watershed.py`(numpy 门控;可选 `wolframscript` + Manim)
> D8 核:Python `from p005_d8 import`;Dafny `include "P005_d8.dfy"`;Lean `import VeriGIS.D8`

## 跨命题链条(第一次)

```
填洼 (P-002) → 无洼 / 无 flat 环 → D8 轨道终止 (P-006 层 B 前提)
             → 流域归属唯一 (P-006 层 A)
```

P-005 的 `FlowDescent` 保证**一旦选出方向,邻格严格低于中心**。P-002 填洼消去洼地与
残留 flat 之后,这条下降链在有限格网上才会给出层 B 的终止前提。本文件把层 A
(函数性 ⇒ 出口唯一)与层 B(终止性)拆开:唯一性在「轨道到达不动点出口」的假设下
机器检验;未填洼时的 flat 环写成 **P-006b 反例**,不是漏证。

## 证了什么

| 引理 | 层 | 说明 |
|---|---|---|
| `FlowSuccessorUnique` / `flow_successor_unique` | A | D8 是函数,窗口上后继唯一(复用 P-005 核) |
| `OrbitDeterministic` / `orbit_deterministic` | A | `stepN(succ,c,n)` 对 n 展开,同起点同 n 步必相等 |
| `TerminatesImpliesBasin` / `terminates_implies_basin` | A | 若某步到达不动点,则 `basin(c)` 有定义 |
| `BasinUnique` / `basin_unique` | A | **主定理**:两个出口都是不动点 ⇒ 出口相同(`∃!`) |
| `FlatCycleNoTermination` / `flat_cycle_no_termination` | B / P-006b | Fin 4 上 `i ↦ i+1` 永无不动点 |
| `TerminatesUnderStrictDescent` / `terminates_under_strict_descent` | B / T6 | 高程 `nat` 严格下降 ⇒ 终止(`P006_terminate_under_strict.dfy`) |

并列扫描序与 `drop²/dist2` 比较仍以 P-005 为准,本文件不重写 8 路核。

## 没证什么

- **P-006b 是科学资产。** 未填洼、又允许「等高也可走」的 naive 路由时,flat 上可以转圈;
  形式化里用 4-环后继作 witness。P-005 的 D8 要求 `drop>0`,它自己不会在真平坦上选方向
  (全 `NoFlow`),环来自**另一条**平坦路由,用来钉住「无条件终止」为假。
- **第 6 条 `TerminatesUnderStrictDescent` = 云端 PASS(2026-09-06 18:30)。**
  `dafny verify P006_terminate_under_strict.dfy` → 12 verified / 0 errors;
  `lake build` → `VeriGIS.P006Terminate` + `VeriGIS.Composition.PitFillingThenWatershed` OK。
  高程嵌进 `nat` 良基(`ghost predicate` + `decreases c` / Lean `Nat.lt_wfRel`)。
  见 `P006_terminate_under_strict.dfy` 与 `VeriGIS.P006Terminate`;P-COMP-1 §2.4 (iii)
  引用 `Bound`。坐标后继(如 `ChainSucc`)不必下降,那种轨道仍走鸽笼。
- 一般符号 DEM、任意大小格网、多出口竞争的算法实现(优先队列填洼等)都不在范围内。

## 跑

```bash
dafny verify formal/dafny/P006_watershed.dfy
dafny verify formal/dafny/P006_terminate_under_strict.dfy
cd formal/lean4 && lake build
python3 experiments/phase1/p006_watershed.py
# P006_MANIM=1 python experiments/phase1/p006_watershed.py
```
