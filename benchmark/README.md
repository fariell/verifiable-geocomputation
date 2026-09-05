# GeoProofBench · 可验证空间计算命题基准

> 首个面向 DEM 空间推理的形式化定理证明基准。

## 目标

把经典 DEM 地形分析任务(坡度、坡向、曲率、水文分析、可视域、变化检测)中**形式可陈述**的性质,翻译为 Lean 4 / Dafny 双形式化,建立可机器检验的标准化评测体系。

## 命题模板

每条命题采用如下结构:

```yaml
id: GPB-001
title: 坡度在平坦区域的零值性
category: 坡度算子
difficulty: ★   # 易
formal_languages: [lean4, dafny]
preconditions:
  - DEM 高程场 E 在 3x3 邻域内为常数
expected_properties:
  - 输出坡度 = 0
source: 经典地形分析教材 §3.2
verified_by: pending
```

## 状态

- [ ] v0.1:50 条候选命题(本周 sprint 0)
- [ ] v1.0:300 条形式化(2026 年底)
- [ ] v1.5:覆盖可视化、可跨模型评测(2027 年中)
- [ ] v2.0:跨域(矢量、点云、时空)

## 贡献

详见根目录的 `CONTRIBUTING.md`。提 issue 即可贡献命题素材。

---

_v0.1 · 2026-09-05_