# GeoProofBench: Paper P2 草稿 — v1.5 NUM 补丁(文件名 v1.4_NUM)

> **目的**: 把 task9 / 10.5 / 11 / 12 / 13 的**实测数字**写入 v_final §7.6
> (multires + plane closure + homotopy + metaproperty + real-DEM diversity)。
> 本稿是 v1.3 NUM 的 additive supplement。文件名按 inbox A.9.5 保留
> `PAPER_P2_v1.4_NUM.md`;稿件末行签 **v1.5**。
>
> **诚实边界**(不得改写成更强口径):
> - task9 SRTM-30m / LiDAR-down 仍是**合成栅格**(公开 tile 本机 502)。
> - task11 重采样矩阵是 **8 PASS + 4 FAIL-TOLERANCE**(全部 45°),**不是** 12/12 σ≤1e-6。
> - task13 LiDAR/IFSAR 是 USGS 3DEP ImageServer 窗口(staged S3 COG vsicurl 502/timeout);
>   Copernicus 是 AWS eu-central-1 GLO-30 COG。三者 `synthetic=false`。窗口 256²,不是整幅产品。
>
> **PI push gate**:本文仅本地 commit,不 push。

数据源 commits(local only):

| task | commit | 工件 |
|---|---|---|
| 9 | `6a54d4c` | GPB-024 四套 DEM |
| 10.5 | `04571d5` | GPB-022 / P-COMP-2 256² 平面 |
| 11 | `624d131` | GPB-025 / P-COMP-4 12 cells |
| 12 | `10a9ebb` | GPB-026 / P-COMP-5 hash+幂等 |
| 13 | `a33159a` | GPB-027 三套真实 DEM |

---

## §7.6.1 task9 多分辨率(GPB-024)

同一 fill + D8 + terminate。形式化不绑定网格边长。权威表亦见 v_final §A.7。

| DEM | 网格 | 像元 | n_pit(填前,内部) | n_term | uniq_out | longest | verd |
|---|---|---|---|---|---|---|---|
| plane-5m | 5×5 | 5 m | 0 | 9 | 3 | 3 | PASS |
| terrain-A | 256² | 5 m | 53 | 64516 | 98 | 351 | PASS |
| SRTM-30m | 3601² | 30 m | 2519307 | 12952801 | 6027216 | 28 | PASS |
| LiDAR-down | 256² | ~4 m | 1782 | 64516 | 20137 | 13 | PASS |

口径 shorthand:`n_term / uniq_out / longest` =
plane 9/3/3; terrain-A 64516/98/351; SRTM 12.95M/6.03M/28; LiDAR 64516/20137/13。

**来源备注**:SRTM 行 = 同尺寸合成 `SYNTHETIC_3601`(N32E110 gzip 502);LiDAR 行 = 1024² 合成场 4×4 均值。不是 USGS 产品精度声明。

Wolfram 粗化:`pigeonholeAll=True`, `descentAllFix=True`, `ringHasFixedPoint=False`。
dafny PCOMP_1 17/0; T6 12/0; lake(当时) 2760 modules。

图:`experiments/phase2/figures/MultiresFillThenWatershed.mp4` (225006 B)。

---

## §7.6.2 task10.5 全平面闭包(GPB-022 / P-COMP-2)

256² 常值平面(0 起伏)与沿行斜率 ε∈{1e-6, 1e-4}。

| 套 | n_term(全图) | longest | uniq_out | visited(该套) | verd |
|---|---|---|---|---|---|
| PLANE 0-relief | 65536/65536 | 0 | 65536 (每格即出口,全 NoFlow) | 65536 | PASS |
| ROW ε=1e-6 | 65536/65536 | 255 | 256 (全 N) | 8421376 | PASS |
| ROW ε=1e-4 | 65536/65536 | 255 | 256 (全 N) | 8421376 | PASS |

三套 visited 合计 **16,908,288**(inbox 初估 4.5M 偏低,以本表为准)。

Wolfram:`pigeonholeAll=True`, `descentAllFix=True`, `chain256AllHit0=True`, `plane16x16AllTerm=True`。
dafny `PCOMP_2.dfy` **25 verified / 0 errors**; lake 2762 modules(当时)。

---

## §7.6.3 task11 重采样同伦(GPB-025 / P-COMP-4)

西倾平面,网格 `{0.5,1,2,4}× × {0°,45°,90°}` = 12 cells。默认 n=128。上采样必须双线性(`scipy.ndimage.zoom` order=1);最近邻重复制造平台,D8 混杂。

| scale \ rot | 0° | 45° | 90° |
|---|---|---|---|
| 0.5× | PASS σ=0 unique D8 | FAIL-TOLERANCE mixed D8 | PASS σ=0 |
| 1× | PASS σ=0 unique D8 | FAIL-TOLERANCE mixed D8 | PASS σ=0 |
| 2× | PASS σ=0 unique D8 | FAIL-TOLERANCE mixed D8 | PASS σ=0 |
| 4× | PASS σ=0 unique D8 | FAIL-TOLERANCE mixed D8 | PASS σ=0 |

**8 PASS + 4 FAIL-TOLERANCE。不要把 45° 改标 PASS。** 45° 旋转后双线性插值破坏严格单坡,D8 不再唯一,flow_ok=False。这是同伦边界,不是实现失败。

dafny `PCOMP_4_homotopy.dfy` **20 verified / 0 errors** (`R(α,w)=αw`)。lake 2763 modules(当时)。

---

## §7.6.4 task12 元一致(GPB-026 / P-COMP-5)

1D Fill(prefix-max = P-002)四实例,SHA-256(逗号连接整数):

| 实例 | 输入 → Fill | sha256 前 16 hex | Python=Dafny=Lean |
|---|---|---|---|
| plane | `[5,5,5,5]` → `[5,5,5,5]` | `8bf7125626de67c4…` | 是 |
| pit | `[3,1,4]` → `[3,3,4]` | `3fc2f480b5457660…` | 是 |
| slope | `[0,1,2,3]` → `[0,1,2,3]` | `84deff01f1994516…` | 是 |
| cascade | `[3,1,0]` → `[3,3,3]` | `b7d44aa6581b85f1…` | 是 |

**hash 12/12**(4 实例 × 3 语言)。

2D 幂等 `fill(fill(h))=fill(h)` σ=0,堆排序 tie `(r,c)` vs `(-r,-c)` σ=0:

| 套 | 网格 | idempotent | schedule |
|---|---|---|---|
| PLANE | 64² | σ=0 | σ=0 |
| ROW_1e-6 | 64² | σ=0 | σ=0 |
| WEST | 64² | σ=0 | σ=0 |
| PIT5 | 5×5 | σ=0 | σ=0 |

**idempotent 4/4, schedule 4/4**。

dafny `PCOMP_5_idempotent.dfy` **15 verified / 0 errors**; lake **2764 modules / 0 errors**。

---

## §7.6.5 task13 真实 DEM 多样性(GPB-027)

三套**真实公开产品**窗口,同一 P-COMP-1 四闸。禁止合成占位。

| 套 | 产品 | 网格 | 像元 | z 范围 (m) | n_pit | n_term | uniq_out | longest | ridge_frac | Dd (m⁻¹) | verd |
|---|---|---|---|---|---|---|---|---|---|---|---|
| lidar | USGS 3DEP 1 m LiDAR(Griffith Park / LA) | 256² | 1 m | 218–367 | 88 | 64516 | 234 | 157 | 0.1250 | 0.1063 | PASS |
| ifsar | USGS 3DEP 5 m Alaska IFSAR(Fairbanks 窗) | 256² | 5 m | 176–365 | 270 | 64516 | 253 | 142 | 0.2249 | 0.03630 | PASS |
| copernicus | Copernicus DEM GLO-30 tile N32E110 | 256² | 28.4 m | 244–1027 | 626 | 64516 | 4981 | 77 | 0.3180 | 0.006851 | PASS |

填后内部坑数均为 0;内部轨道 64516/64516 终止。

**获取路径**:staged USGS COG (`prd-tnm` S3) vsicurl 代理 CONNECT 502、直连 timeout。LiDAR/IFSAR 改走官方 3DEP ImageServer `exportImage`(nearest),同产品族窗口,不是合成。Copernicus 为 AWS `copernicus-dem-30m` eu-central-1 COG `/vsicurl/`。窗口 256² ≠ 整幅 1 km² / 100 km² 产品。

图:`experiments/phase2/figures/RealWorldDiversity.mp4` (148437 B),caption 见 v_final §7.7。

---

## §7.7 图题(RealWorldDiversity)

> Three public DEMs, same P-COMP-1 fill-then-D8. Panels report ridgeline fraction (D8 in-degree 0), drainage density (in-degree ≥ 2, channel-length/area), and sink count (interior 4-neighbour pits before fill). USGS 3DEP LiDAR 1 m / Alaska IFSAR 5 m / Copernicus GLO-30.

---

## §A.6b · v1.5 实测 profiling(增量)

| 端 | 工件 | 关键数字 | commit |
|---|---|---|---|
| Python | `p_comp_1_multires.py` | 4 DEM 四闸 PASS | `6a54d4c` |
| Python | `p_comp_2.py` | visited 16908288 | `04571d5` |
| Dafny | `PCOMP_2.dfy` | 25/0 | `04571d5` |
| Python | `p_comp_4.py` | 8 PASS + 4 FAIL-TOLERANCE | `624d131` |
| Dafny | `PCOMP_4_homotopy.dfy` | 20/0 | `624d131` |
| Python | `p_comp_5.py` | hash 12/12, idem 4/4 | `10a9ebb` |
| Dafny | `PCOMP_5_idempotent.dfy` | 15/0 | `10a9ebb` |
| Lean | `lake build` | 2764 modules 0 errors | `10a9ebb` |
| Python | `p_comp_realworld.py` | 3/3 real DEM PASS | `a33159a` |
| Manim | `RealWorldDiversity.mp4` | 148437 B | `a33159a` |

---

## §C.4 · v1.4 → v1.5 增量

```
+ §7.6.1  task9  多分辨率 4 行表(含合成 caveat)
+ §7.6.2  task10.5  256² 平面 + 行扰动
+ §7.6.3  task11  8+4 同伦矩阵(45° 不改标 PASS)
+ §7.6.4  task12  hash 12/12 + idempotent 4/4
+ §7.6.5  task13  3 套真实 DEM
+ §7.7    RealWorldDiversity 图题
+ §9.2.4  多样性从 future work 改为已测 + 窗口 caveat
```

_Cursor 起草 v1.5 NUM 2026-09-06 · push gate 永久 · 数字全部从 metrics.json 抄录,无手填_
