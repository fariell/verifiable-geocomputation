# P-002 · Wang & Liu 填洼算子的三条性质

文件:`formal/dafny/P002_pit_filling.dfy`
对偶:P-001 (Horn 坡度算子的代数一致性) → P-002 (W&L 填洼的算法收敛性)
覆盖 GPB:`GPB-005` (单调性)、`GPB-006` (终止性必要条件)、`GPB-020` (不动点)

## 为什么这条是 P-001 的"对偶"

P-001 形式化了"什么是一致"(Horn 算子在平面上精确恢复梯度 —— **代数性质**)。
P-002 形式化"什么是收敛"(Wang & Liu 填洼在有限步内达到不动点 —— **算法性质**)。

| 维度 | P-001 | P-002 |
|---|---|---|
| 类型 | 一阶差分代数性质 | 离散算法收敛性 |
| 工具 | Horn 1981 有限差分 | Wang & Liu 2006 min-heap |
| 关键引理 | `PlanarExact`、`SlopeSqNonneg` | `Monotone`、`SpillFixpoint`、`RaisePreservesOrImproves` |
| 对应科学问题 | "为什么一阶算子 corr > 0.9999?" | "为什么填洼能消除伪坑?" |
| 对应工程后果 | Phase 1 用 Horn 而非 Evans 的形式化依据 | SRTM / ASTER GDEM 水文预处理的形式化依据 |

两条腿合起来,才是"可验证空间计算"对**计算结果可证性**的最小覆盖。

## 本文件做了哪三件事

(a) **GPB-005 单调性 `Monotone`**: 经任意次抬升,任一像素的新高程 ≥ 原值。
    这条是"填洼"这个动词的**核心含义** —— 任何填洼操作都不应**降低**任何像素的高程。
    SMT 自动证明,Dafny 4.11 的触发器足以让 Z3 找到 `forall j` 的 case 切分。

(b) **GPB-020 透水点不动点 `SpillFixpoint`**: 若像素 i 已经 ≥ 其邻居,
    `Raise(a, i) = a`。这形式化"W&L 的无洼即停"原则。
    证明需要 calc 块手写一步,让 SMT 看见 if 分支被选择。

(c) **GPB-006 一遍 Raise 至少修复一处单调性 `RaisePreservesOrImproves`**:
    1D 上 Raise 一遍,**任一像素都不比其左侧邻居低**(NonDecreasing),
    或者 Raise 之前就已经 NonDecreasing。这是 2D 终止性证明的
    **必要条件**(充分条件需要 2D 8-邻居 + 堆不变量)。

## 没有做的(留给 P-002-bis / P-003)

- **2D 终止性**:严格证明 W&L 2D 算法在 `O(n log n)` 步内达到不动点。
  需要 Dijkstra-style 不变量(已处理的像素高程单调,未处理的单调
  不可降解)—— 篇幅关系,单独文件 `P002_pit_filling_2d.dfy`。
- **浮点精度边界**:实现用 float,本文件用 int。float32 下 Raise
  的舍入误差会不会破坏 SpillFixpoint?需要加 `requires abs ≤ ε`
  的近似版本 —— 见 P-005 "RDD 误差界"。
- **与 D8 的端到端合约**: 填洼 + D8 后流向图与真值有界一致 —— 这是
  Phase 2 的目标。

## 验证命令

```bash
# 在 WSL bash 里,仓库根:
dafny verify formal/dafny/P002_pit_filling.dfy

# 期望输出结尾:
# Dafny program verifier finished with 4 verified, 0 errors
# (3 lemmas + 1 method Main)
```

## 与 P-001 的对偶论证

P-001 证:"Horn 算子在平面上**精确**恢复梯度" —— 这条性质之所以能证,
是因为一阶差分是线性的、对中心元不依赖。
P-002 证:"W&L 填洼是**单调**的" —— 这条性质之所以能证,是因为 Raise
的定义就是 `max(old, neighbor)`,单调性从定义直接推出。

两条命题都示范了 GeoProofBench 的方法论:
**形式化结论的形式化对象,不在数值而在结构**。

## 已知未决(SMT 可能求助的边界情形)

- `RaisePreservesOrImproves` 中的 `exists i0 :: ...` 抽取,
  SMT 在某些版本下需要 `assert ... by { Monotone(a, i) }` 显式引,
  否则直接超时。PI 跑完后若是超时,把 stderr 贴回来,我针对性加重 calc。
- 1D SafeGet 的边界 `i = 0` 时 `i - 1 = -1`,我们保证返回 0;
  这条边界不破坏 SpillFixpoint,但 Dafny 可能在 j = 0 时多触发一次 split,
  是可接受的调试信息。
