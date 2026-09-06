# Dafny 形式化 · GeoProofBench

> 本目录存放 GeoProofBench 命题的 **Dafny** 形式化。Lean 4 版本见 `../lean4/`。
> 双形式化同一命题是本方向的硬要求:**同一个算子、两条独立证明链**,
> 任一条证明失败都说明命题陈述或算子定义有问题。

---

## 已形式化命题

| 文件 | 命题 ID | 算子 | 引理数 | 状态 |
|---|---|---|---|---|
| `P001_horn_slope.dfy` | GPB-001 / GPB-002 / GPB-019(一阶部分) | Horn 3×3 坡度 | 7 | ✅ 本机 WSL 19 verified / 0 errors |
| `P002_pit_filling.dfy` | GPB-021 / GPB-022 / GPB-023 | Wang & Liu 填洼(1D 特化) | 见 `P002_README.md` | ✅ AutoDL 2026-09-06 · 24 verified / 0 errors |

### P-001 · Horn 坡度算子的基本性质

覆盖的引理:

| 引理 | 性质 | 对应命题 |
|---|---|---|
| `FlatSlopeZero` | 平坦面坡度恒为 0 | GPB-001 |
| `SlopeSqNonneg` | 坡度(平方)非负 | GPB-001 |
| `PlanarExact` | **平面上精确恢复 A、B**(不是渐近,是恒等) | GPB-002 / GPB-019 |
| `TranslationInvariant` | 高程基准平移不改变坡度 | — |
| `MirrorDxAntisym` / `MirrorDyAntisym` | 镜像反射下的反对称性 | — |
| `ScaleLinear` | 高程整体缩放 → 梯度同比例缩放 | — |

`PlanarExact` 是本文件最硬的一条:**它说明一阶算子的一致性不是经验巧合,
而是可以从代数结构推出的**。

---

## 运行方式

```bash
# 在 WSL / Ubuntu 22.04 里
export PATH="$HOME/.elan/bin:$PATH"     # Lean 装好后才需要

# 验证(推荐,只做静态验证)
dafny verify formal/dafny/P001_horn_slope.dfy

# 或者编译 + 运行 Main
dafny run formal/dafny/P001_horn_slope.dfy
```

期望输出:

```
Dafny program verifier finished with 7 verified, 0 errors
```

---

## 为什么用 `real` 而不是 `float`

地形算子在工程实现里一律是浮点(`float32`/`float64`),但**浮点算术无法
直接承载"证明"**:`a + (b + c) != (a + b) + c`,结合律都不成立,更不用说
"平移不变"这类整体性质。

所以形式化分两层:

1. **规范层(本目录)**:在精确算术 `real` 上给出算子的数学定义与性质证明。
   这层回答"算子**应该**满足什么"。
2. **实现层(见 `experiments/`)**:用浮点实现 + 误差界分析,回答"实现
   **偏离**规范多少"。两层之间的差距就是可验证性缺口。

这个"规范—实现"二分,是 VeriGIS 的核心架构。

---

## 坡度平方而非坡度

`SlopeSq` 用 `dzdx² + dzdy²` 代替 `sqrt(dzdx² + dzdy²)`。原因:
`sqrt` 是超越函数,会让 SMT 求解器从可判定域掉出去。而"非负"和"为零"
这两个性质在平方层面已完全等价:

```
slope == 0  ⟺  slopeSq == 0
slope >= 0  ⟺  slopeSq >= 0   (slope 定义为 sqrt 时恒非负)
```

需要真实量值比较时(如 `slope < 0.5`)再单独引入 `sqrt` 的单调性引理。

---

## 路线图

- [x] P-001 Horn 坡度 — 已起草;本机 WSL 19 verified / 0 errors;云端作一致性锚
- [x] P-002 Wang & Liu 填洼 1D 特化 — Dafny 24 verified / 0 errors;Lean `VeriGIS.PitFilling` lake build 2026-09-06 10:29
- [ ] P-002-bis 填洼 2D + 堆不变量
- [ ] P-003 曲率算子(Evans / Zevenbergen–Thorne)— 对应 GPB-005/006/007/020,
      这是 Phase 1 `corr = 0.157` 的正面战场
- [ ] P-004 坡度算子在 `w → 0` 下的相容性(GPB-019 完整版,需实分析)
- [ ] P-005 D8 流向的确定性与闭合性(GPB-010/011)

---

_最后更新:2026-09-06 · P-002 改为可证的 Fill 扫描;曲率改挂 P-003_
