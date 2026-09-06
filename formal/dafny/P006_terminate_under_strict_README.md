# P-006 第 6 条 · `TerminatesUnderStrictDescent`

> 对偶:`../lean4/VeriGIS/P006Terminate.lean`(独立重述,不翻译 Dafny)
> 核:`P006_watershed.dfy` 的 `stepN` / `StepNAdd`(include,不复制)
> 二次使用:P-COMP-1 `docs/phase2/PROP_CHAIN.md` §2.4 步骤 (iii)

## 证了什么

| 引理 | 说明 |
|---|---|
| `StrictDescent` | `succ(x) ≤ x`(卡住或高程下降) |
| `Bound` | 对当前 `c` 做 `decreases`;卡住则 0,否则 `1 + Bound(succ, succ(c))` |
| `BoundLe` | `Bound(succ, c) ≤ c` |
| `BoundIsFix` | `stepN(succ, c, Bound)` 是不动点 |
| `TerminatesUnderStrictDescent` | 存在 `n ≤ c` 使轨道到达不动点 |
| `HeightSucc` 实例 | `n ↦ n-1`(0 卡住),`Bound = c` |

Lean 侧走 `Nat.lt_wfRel.wf.induction`,与 Dafny `decreases c` 同一度量,不是翻译。

## 没证什么

- 格网坐标上的后继(P-006 `ChainSucc` 会升高下标)不必满足 `StrictDescent`;要把**高程**嵌进 `nat`。
- 未填洼的 flat 环(P-006b)没有严格下降,本条故意不覆盖,那是科学反例。
- 一般实数 DEM、浮点下溢、多出口优先队列填洼,都不在范围内。

## 跑

```bash
dafny verify formal/dafny/P006_terminate_under_strict.dfy
cd formal/lean4 && lake build
```
