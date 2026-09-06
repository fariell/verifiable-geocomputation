# P-002-bis · Wang & Liu 2D 邻域抬升

> 对偶:`../lean4/VeriGIS/PitFilling2D.lean`
> 1D 特化:`P002_pit_filling.dfy`
> 状态:AutoDL 2026-09-06 · Dafny **19 verified / 0 errors**(12:54);Lean **Built VeriGIS.PitFilling2D**(12:53)

## 证了什么

| 引理 | ID | 说明 |
|---|---|---|
| `RaiseNbrMonotone` / `floodMax_ge_*` | GPB-024 | 从已处理格 p 抬邻居 n,不降低任何填高 |
| `RaiseNbrProcessedFrozen` | GPB-025 | 不改 p、不改第三格("弹出后不再回写") |
| `FillStripEq1D` / `fillStrip_eq_fill` | GPB-026 | 单行左出口扫描 ≡ P-002 `Fill` |
| `ExampleCenterPit` | — | 3×3 中心 0,北邻 1 → 中心填成 1 |

## 没证什么

完整优先队列上"弹出即终态 / O(n log n)"。那是 Dijkstra 全局最小路径,单独开题,避免再写假命题。

## 跑

```bash
dafny verify formal/dafny/P002_pit_filling_2d.dfy
cd formal/lean4 && lake build
```
