# 命题链与组合命题 · Prop Chain

> "可验证空间计算"研究体系在 Phase 2 的核心方法学:**已证的孤立命题如何机器组合出更高阶命题**。
> 起草:Luoshu,2026-09-06。

---

## 1. 命题链视角下 Phase 1 的产出

```
P-001  slope 非负        ──┐
                            ├── 一阶算子命题(每条独立成立)
P-002  填洼              ──┤
P-002-bis 2D 填洼 ──┤
P-003  剖面曲率 ZT      ──┤
P-004  Horn 二次精确    ──┤
P-005  D8 8 路          ──┘
P-006  流域唯一 [在证]  ──── (本周末应闭合)
```

每条独立机器检验 ≤ 25 verified,规模小,论文叙事意义有限 — Phase 1 是**种子层**,
不是发表层。

---

## 2. 第一条组合命题(P-COMP-1,Phase 2 旗舰)

### 2.1 命题陈述(自然语言)

> **如果在 DEM 上先做填洼(P-002),再跑 D8 流向分析(P-005 + P-006),那么每条
>  轨道必然终止于唯一出口;即"填洼后流域唯一性"成立。**

这条命题不是 P-002、P-005、P-006 的简单拼接 — 它要求 P-002 的输出满足 P-006 的
前提(无洼即无 flat 环),而 P-006 在没有该前提时**只部分成立**(背景一节明标 P-006b
flat 环反例)。

### 2.2 组合证明骨架

| 步骤 | 形式化义务 | 依赖 |
|---|---|---|
| (i) 填洼后每格相邻至少有一个不大于自身的高程(P-002 后置条件) | 已有 P-002 严格论证 | P-002_2d |
| (ii) 由 (i) 与 P-005 D8 确定性 ⇒ 每格下一步高程严格不增 | P-005 + (i) | P-005 |
| (iii) 由 (ii) 与 (iv) ⇒ 轨道长度受格数 n·m 严格上界 | 鸽笼(已有 `p006_watershed.wl` 验证) | P-COMP-1 自带 |
| (iv) (角点边界:出口集合非空) | 边界条件引理 | 待起草 |
| (v) 由 (iii)(iv) + P-006 层 A 唯一性 ⇒ 结论 | P-006 `BasinUnique` 直接复用 | P-006 |

**关键**:步骤 (v) 不重写 P-006 的"出口唯一"证明 —- 直接 import `BasinUnique`,
只在 P-COMP-1 里补**前提**(ii)(iii)(iv)的"通过填洼可达"语境。

### 2.3 三件套(沿用 P-006 七件套模板)

| # | 文件 | 内容要点 |
|---|---|---|
| 1 | `experiments/phase2/p_comp_1.py` | 在填洼后再跑 P-006 算子,验证三条门控 |
| 2 | `experiments/phase2/p_comp_1.wl` | 鸽笼在 4^k 网格上穷举终态 |
| 3 | `experiments/phase2/p_comp_1_manim.py` | 左:不填洼 → flat 环;右:填洼后 → 唯一出口动画 |
| 4 | `experiments/phase2/run_p_comp_1.sh` | 云端驱动,`GPB-021 ENTRY: PASS` 收尾 |
| 5 | `formal/dafny/PCOMP_1.dfy` | (i)~(v) 全 Dafny 翻译 |
| 6 | `formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean` | import P-002/P-005/P-006,**不翻译 Dafny** |
| 7 | `formal/dafny/PCOMP_1_README.md` | 组合策略图 + "没证什么" |

**这条组合证明本身就是 Phase 2 的方法论成果**:写法示范给"二阶命题如何机器证明",
后续 P-COMP-2..5 都是模板复用。

### 2.4 可执行规格(Cursor pre-spec;2026-09-06 17:55 洛书补)

#### P-COMP-1 import 接口面(不动 P-002/P-005/P-006 源)

```dafny
// 假定 P-002 已提供:
module P002 = PitFilling2D  // pitFill2D : DEM -> DEmFilled
// 假定 P-005 已提供:
module P005 = D8Flow         // D8 : Win -> Flow(Dir ∪ {NoFlow})
// 假定 P-006 已提供:
module P006 = Watershed      // BasinUnique、stepN、OrbitDeterministic
```

P-COMP-1 内部只声明以下谓词(骨架不动 P-002/P-005/P-006):

| 类型 | 签名 | 物理意义 |
|---|---|---|
| `lemma NoPitImpliesDescent` | `(h : DEmFilled) (c : Cell) (n : D8) :: D8Step h c n ≤ c` | (i): 填洼后每格邻接 ≤ 中心 |
| `lemma D8PreservesDescent` | `(h : DEmFilled) (c : Cell) :: ordOf(d8(h,c)) < ordOf(c)` | (ii): 与 P-005 一起 ⇒ 严格下降 |
| `lemma OrbitLengthBound` | `(h : DEmFilled) (c : Cell) :: ∃ n ≤ n*m, isFix(stepN(succ, c, n))` | (iii): 鸽笼上界 |
| `lemma BoundaryNonEmpty` | `(h : DEmFilled) :: ∃ c : Cell, d8(h, c) = NoFlow` | (iv): 矩形边界至少一格不动 |
| `theorem FillThenWatershed` | `(h : DEM) (c : Cell) :: ∃! o, basin(pitFill2D(h), c) = o` | (v): 主定理 |

P-COMP-1 允许的引用:
- `P002.PitFilled`(`DEM` → `DEmFilled`)
- `P005.D8` 流向函数
- `P006.BasinUnique`(主复)

严禁:**新加 Flow 类型 / 复制 Rate-of-Ascent 比较**。任何重复造轮子 OUTBOX 即报 BLOCKED。

#### Lean 端规格

```lean
import VeriGIS.PitFilling2D
import VeriGIS.D8
import VeriGIS.Watershed
namespace VeriGIS.Composition

theorem pit_fill_then_watershed (h : DEM) (c : Cell) :
    ∃! o, Watershed.basin (PitFilling2D.pitFill2D h) c = o := ...

-- § 2.4 (i)+(ii) 论证视情况独立写
end VeriGIS.Composition
```

注意 Lean 文件路径是 `formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean`
(`Composition` 是 VeriGIS 子目录,要 `mkdir` + `VeriGIS.lean` 加 import)。

#### Python driver(p_comp_1.py)

```python
from experiments.phase1.p005_d8 import DIRS, d8_at, plane_grid
from experiments.phase1.p006_watershed import follow_d8, RING, ...
from experiments.phase1.p002_pit_filling_2d import pitFill2D  # 待 P-002 公开
```

门控:
- (i) **NoPitImpliesDescent**:对每个 pit-fill 后的 DEM,任何邻接 vs 中心 ≤ 中心
- (ii) **StrictDescent**:平面 σ=0,每个 step 中心 d8 后继高程 ≤ 中心 - 1(快速衰减)
- (iii) **TerminatesUnderStrictDescent**:对 5×5 平面,所有 interior 轨道 ≤ 50 步终止

#### 第 6 条 `TerminatesUnderStrictDescent` 单独条款

独立 8 件套(可与 P-COMP-1 同次 session):

| 路径 | 类型 | 要点 |
|---|---|---|
| `formal/dafny/P006_terminate_under_strict.dfy` | Dafny 模块 | `decreases` chain 对 n 归纳 |
| `formal/lean4/VeriGIS/P006Terminate.lean` | Lean 模块 | mathlib `WellFounded`/`Nat.lt_wfRel` |
| `formal/dafny/P006_terminate_under_strict_README.md` | 台账 | 引用 P-COMP-1 §2.4 step (iii) 作为二次使用 |

如果第 6 条通过,**P-COMP-1 的 §2.4 step (iii) 改为 P006_terminate.bound(succ, c)`**,
否则保持 §2.3 step (iii) 的鸽笼证明不动。

#### 论文对接点(理顺 Outline)

`docs/PAPER_P2_OUTLINE.md` §7.4 把 P-COMP-1 当主案例,§9 Discussion 引用本节 §2.4 接口面
表 说明"组合命题的可机器证明性"。

---

## 3. 候选组合矩阵(Phase 2 全景)

| 组合 id | 左输入(已证) | 右输出(已证) | 组合命题自然语言 | 状态 |
|---|---|---|---|---|
| **P-COMP-1** | P-002 填洼 | P-006 流域唯一 | 填洼后流域唯一 | **首推** |
| P-COMP-2 | P-002 + P-005 平面恒定 | P-006 | 全平面轨道必终止于唯一出口 | 可证,但与 P-COMP-1 部分重叠 |
| P-COMP-3 | P-003 ZT 剖面曲率 | P-004 Horn 二次 | 二者不可互推,差分格式族内有线性依赖 | 伪命题/反例,标注后给"不对称的脆弱"做素材 |
| P-COMP-4 | GPB-018 平面 resampling | P-001 slope 非负 | 平面重采样后 slope 仍为零 | 弱同伦,简易 |
| P-COMP-5 | P-001..P-006 任意组合 | GPB-019 一致性 | 任何组合后整体算法仍收敛 | 元性质,留待 Phase 3 |

**节奏建议**:10 月 → 11 月 → 12 月,**每月闭 1 条**(优先 P-COMP-1→2→4);P-COMP-3
作为反例展示,有科学叙事价值但不需要"机器证明"。

---

## 4. 关键设计原则(避免重蹈覆辙)

1. **不重写已证的引理**。P-COMP-1 里绝不复制 P-002 的 `PitFilled` 定义,直接 `import`。
2. **不破坏 P-001..P-006 的现有成果**。P-006 的 `P006_README.md` 第 §"没证什么"
   段要被引用到 P-COMP-1 README 中,作为动机;反之 P-COMP-1 也回头声明
   "本命题依赖 P-006 的前提被 P-002 推导出"。
3. **新条目不要无脑扩 GPB-020+**。组合命题立新内部 id(P-COMP-N),在论文
   "Method §7.4 Composition" 一节里集中讲,而非混进 GPB 单命题表。
4. **Lean 与 Dafny 独立重述,但共享一个 Python driver 与一个 wolframscript 符号化**。
5. **每个 README 必带"没证什么"小节**。即使组合命题也有前提不达时的边界,
   写出来,不是漏证而是"已知缺口"。

---

## 5. 与 P2 论文叙事的对接点

`docs/PAPER_P2_OUTLINE.md` §7.4 Composition 一节应:

- 用 P-COMP-1 当主案例(全文章节中叙事强度最高的一段)
- 引用 P-002 + P-006 的 READMEs 作为素材,而不是重写它们
- 在 §9 Discussion"So what?"里点出:组合命题的**机器可检验性**才是"算子拼装流水线"
  在工业上可信的根 — 这是比 GeoMath-Agent 论文更工程化也更适合 P2(Scientific Data,
  数据/基准型)的卖点

---

_Phase 2 v0.2 executable pre-spec · 2026-09-06 17:55 · §2.4 新增可执行接口面;Luoshu pre-spec for Cursor._
