# P-COMP-1 多分辨率数值表(task9 / GPB-024)

同一套 fill + D8 + terminate(P-COMP-1),四套 DEM。形式化见
`formal/dafny/PCOMP_1_MULTIRES_README.md` — 引理不绑定网格边长。

跑:`python experiments/phase2/p_comp_1_multires.py`
Wolfram:`p_comp_1_multires.wl` → pigeonholeAll=True, descentAllFix=True, ringHasFixedPoint=False
Manim:`experiments/phase2/figures/MultiresFillThenWatershed.mp4`

| DEM | 网格 | 像元 | n_pit(填前,内部) | n_term | uniq_out | longest | verd |
|---|---|---|---|---|---|---|---|
| plane-5m | 5×5 | 5 m | 0 | 9 | 3 | 3 | PASS |
| terrain-A | 256² | 5 m | 53 | 64516 | 98 | 351 | PASS |
| SRTM-30m | 3601² | 30 m | 2519307 | 12952801 | 6027216 | 28 | PASS |
| LiDAR-down | 256² | ~4 m | 1782 | 64516 | 20137 | 13 | PASS |

n_pit = 填洼前内部 4 邻局部最低点。填后内部坑数均为 0。边界局部最低点仍可出现(离格网外排,不算内部坑)。

## 来源备注

| DEM | 实际栅格 |
|---|---|
| plane-5m | `plane_grid(A=1,B=0,C=12,n=5)`,与 GPB-021 基线相同 |
| terrain-A | 仓内无 phase1 栅格;合成丘陵 + 12 人工坑 + σ=5e-3,seed=20260906 |
| SRTM-30m | 公开 N32E110 `.hgt.gz` 本机代理 502 / 不完整 gzip;改用 **同尺寸合成** `SYNTHETIC_3601`(sin/cos + σ=1.6) |
| LiDAR-down | 仓内无 USGS TNM;1024² 高频场 4×4 均值 → 256²(inbox 允许 LiDAR 缺时 256² 套) |

## 其它闸

| 闸 | 结果 |
|---|---|
| 每套 4 门控 | 全 PASS |
| dafny `PCOMP_1.dfy` | 17 verified / 0 errors(AutoDL 19:48) |
| dafny `P006_terminate_under_strict.dfy` | 12 verified / 0 errors(AutoDL 19:48) |
| `lake build` | Build completed successfully(AutoDL 19:48) |
| Wolfram 4^4 | pigeon=True descent=True ringFixed=False |
| 粗化 CSV 4-邻坑 | 块均值**不是**无坑同态:PLANE_5 True, TERRAIN_A_8 / SRTM_16 / LIDAR_8 False。代数三判仍 True/True/False |
| manim | `MultiresFillThenWatershed.mp4` 225006 bytes |

未改:`docs/PAPER_P2_*.md` / `this-week.md` / `MEMORY.md` / `PROP_CHAIN.md`。未复制 phase1 gpb001–015 数字。
