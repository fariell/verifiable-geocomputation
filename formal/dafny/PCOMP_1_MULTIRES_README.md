# P-COMP-1 多分辨率 · 形式化与网格尺寸无关(GPB-024)

> 对偶实验:`../../experiments/phase2/p_comp_1_multires.py`
> 种子证明:`PCOMP_1.dfy` + `P006_terminate_under_strict.dfy`(task7.5 已云端 17/0 + 12/0)
> Lean:`VeriGIS.Composition.PitFillingThenWatershed` + `VeriGIS.P006Terminate`

## 为什么形式化不用改

P-COMP-1 / T6 的量词都不绑定网格边长:

| 引理 | 量化对象 | 与 n 的关系 |
|---|---|---|
| `NoPitImpliesDescent` / `NoPitImpliesDescent2D` | `seq` / `Grid` + `RaiseNbr` | `Rect(orig)` 任意行列 |
| `D8PreservesDescent` | 3×3 `Win` | 与整幅 DEM 无关 |
| `OrbitLengthBound` | `succ : nat → nat` + `Bound` | 终止上界是高程/鸽笼,不是 5×5 |
| `FillThenWatershed` | `BasinUnique` | 出口相等性不提分辨率 |

因此 5×5、256²、3601² 共用同一份 `dafny verify` / `lake build`。数值实验只是把同一算法实例化到更大的数组,不是新命题。

## 四套 DEM

| slug | 网格 | 像元 | 来源 |
|---|---|---|---|
| PLANE | 5×5 | 5 m | `plane_grid(A=1,B=0)` 与 P-COMP-1 基线相同 |
| TERRAIN_A | 256² | 5 m | 合成丘陵 + 12 坑 + σ=5e-3(仓内无 phase1 栅格) |
| SRTM_30M | 3601² | 30 m | 优先 `data/cache/N32E110.hgt`;缺则同尺寸合成占位 |
| LIDAR | 256² | ~4 m | 1024² 高频场 4×4 均值(仓内无 USGS TNM 点云) |

Inbox 允许 LiDAR 缺省时用 256²×3 套;本实验保留 4 行,LiDAR 行是降采样合成而非真实点云。

## 没证什么

- 不把 USGS 产品精度、大地水准面、空洞填补写进引理。
- 不证工业 flat-routing:填洼后等高台上 D8 仍给 `NoFlow`。
- 不把 3601² 的 Python 堆实现与 Dafny `RaiseNbr` 逐步互模拟。

## 跑

```bash
dafny verify formal/dafny/PCOMP_1.dfy
dafny verify formal/dafny/P006_terminate_under_strict.dfy
cd formal/lean4 && lake build
python3 experiments/phase2/p_comp_1_multires.py
# PCOMP1_MULTIRES_MANIM=1 python experiments/phase2/p_comp_1_multires.py
```

表:`docs/phase2/MULTIRES_TABLE.md`
