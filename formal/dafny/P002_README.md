# P-002 · Wang & Liu 填洼算子的 1D 特化

文件:`formal/dafny/P002_pit_filling.dfy`
对偶:P-001 (Horn 坡度算子的代数一致性) → P-002 (W&L 填洼的算法收敛性)
覆盖 GPB:`GPB-021` (单调性)、`GPB-022` (一遍扫描后非降)、`GPB-023` (不动点 / 幂等)

> **ID 对齐(2026-09-06)**:初稿借用了种子集里的 GPB-005/006/020,但那三条在
> `geoproofbench_v0.1_batch1` 里是**曲率**命题,留给 P-003。
> 填洼三条改挂 GPB-021/022/023,避免命题库撞号。

## 为什么这条是 P-001 的"对偶"

P-001 形式化了"什么是一致"(Horn 算子在平面上精确恢复梯度 —— **代数性质**)。
P-002 形式化"什么是收敛"(1D 填洼在有限步内达到非降剖面 —— **算法性质**)。

| 维度 | P-001 | P-002 |
|---|---|---|
| 类型 | 一阶差分代数性质 | 离散算法收敛性 |
| 工具 | Horn 1981 有限差分 | Wang & Liu 2006 在 1D 上退化为从出口向外扫描 |
| 关键引理 | `PlanarExact`、`SlopeSqNonneg` | `Monotone`、`FillCorrect`、`FillIdempotent` |
| 对应科学问题 | "为什么一阶算子 corr > 0.9999?" | "为什么填洼能消除伪坑?" |
| 对应工程后果 | Phase 1 用 Horn 而非 Evans 的形式化依据 | SRTM / ASTER GDEM 水文预处理的形式化依据 |

两条腿合起来,才是"可验证空间计算"对**计算结果可证性**的最小覆盖。

## 1D 特化在证什么

Wang & Liu 在 2D 上是边界入堆、弹出最低已处理像元、邻居抬到
`max(自身, 当前填后高程)`。左端为唯一出口的 1D 剖面把它变成一遍扫描:

```
Fill[0] = orig[0]
Fill[i] = max(orig[i], Fill[i-1])    for i = 1, 2, …
```

本文件对 `Fill` 证明三条**真**命题:

(a) **GPB-021 单调性 `Monotone` / `FillFromMonotone` / `FillCorrect`**:
    单点抬升与完整扫描都不降低任一像元。这是"填洼"这个动词的核心含义。

(b) **GPB-022 扫描后非降 `FillFromCorrect` / `FillCorrect`**:
    `NonDecreasing(Fill(a))`。1D 上这就是"结果无坑"。
    2D 终止性的充分条件需要 8 邻域 + 堆不变量,见 P-002-bis。

(c) **GPB-023 不动点 `SpillFixpoint` / `FillFixpoint` / `FillIdempotent`**:
    单点:若 `a[i] ≥ a[i-1]`,则 `Raise(a, i) = a`。
    全局:非降剖面是 `Fill` 的不动点,因而 `Fill(Fill(a)) = Fill(a)`。

另有一条具体例子 `ExamplePitFilled`:`Fill([3,1,4]) = [3,3,4]`,用来钉死定义。

## 初稿那条引理为什么被删掉

```
ensures NonDecreasing(a) || NonDecreasing(Raise(a, i))   // 假
```

反例:`a = [3, 1, 0]`, `i = 1` → `Raise` 得到 `[3, 3, 0]`,两侧都不是非降。
单点抬升只能修复**当前下标**,不能让整条剖面变非降。把这条交给 SMT,
超时是预期行为,不是 Z3 版本问题。本轮改证完整扫描 `Fill`,不再证假命题。

## 没有做的(留给 P-002-bis / P-003 / P-005)

- **2D 终止性**:严格证明 W&L 2D 算法在 `O(n log n)` 步内达到不动点。
  需要 Dijkstra-style 不变量——单独文件 `P002_pit_filling_2d.dfy`。
- **曲率**:Evans / Zevenbergen–Thorne,对应种子集 GPB-005/006/007/020 → **P-003**。
- **浮点精度边界**:实现用 float,本文件用 int。float32 下 Raise
  的舍入误差会不会破坏 SpillFixpoint?需要加 `requires abs ≤ ε`
  的近似版本 —— 见 P-005 "RDD 误差界"。
- **与 D8 的端到端合约**: 填洼 + D8 后流向图与真值有界一致 —— Phase 2。

## 验证命令

```bash
# 在 WSL 或 AutoDL 仓库根:
dafny verify formal/dafny/P002_pit_filling.dfy

# 期望输出结尾(函数 + 引理 + Main,数目以实际为准,errors 必须为 0):
# Dafny program verifier finished with N verified, 0 errors
```

若 SMT 仍超时,把完整 stderr 贴回来,优先在 `FillFromCorrect` /
`FillFromMonotone` 的归纳步加重 `assert`,不要再改命题陈述。

## 与 P-001 的对偶论证

P-001 证:"Horn 算子在平面上**精确**恢复梯度" —— 因为一阶差分是线性的、对中心元不依赖。
P-002 证:"1D 填洼是**单调且幂等**的" —— 因为 `Fill[i] = max(orig[i], Fill[i-1])`,
单调性与非降性从定义直接推出,幂等由"非降 ⇒ 恒等"得到。

两条命题都示范了 GeoProofBench 的方法论:
**形式化结论的形式化对象,不在数值而在结构**。
