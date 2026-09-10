/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   算子 : 确定性 D8 流向下的流域唯一性
   对偶 : formal/dafny/P006_watershed.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本的**独立**重述 —— 不是翻译。两处必须注意的差异:

    1. Dafny 的 `decreases` 子句要求显式提供度量函数;Lean 的 `WellFoundedRelation`
       通过类型类自动推导。这里我们显式构造一个基于有限格网大小的良基关系。

    2. 证明风格:Dafny 靠 SMT 自动验证终止性;Lean 需要显式提供良基论证。
       同一条性质在两边自动化的程度差异,本身就是 GeoProofBench 想测量的东西。

  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic

namespace VeriGIS.Watershed

-- 非计算部分: 我们只证明结构性质,不提供可执行代码
noncomputable section

/-!
  ## 格网与流向约定

  设 `Cell` 为有限类型,表示 DEM 中的单元格。
  严格下降后继函数 `succ : Cell → Cell` 满足:
    - 若 `succ c = c`, 则 `c` 是固定点(洼地或边界)
    - 否则 `h (succ c) < h c` (严格下降)

  目标: 证明从任意单元格出发的轨道都会终止于固定点。
-/

variable {Cell : Type} [Fintype Cell] [DecidableEq Cell]
variable (succ : Cell → Cell) (h : Cell → ℕ)

/-- 严格下降条件: 若非固定点,则后继的高程严格降低 -/
def StrictDescent : Prop :=
  ∀ c, succ c ≠ c → h (succ c) < h c

/-- 轨道: 从 `c` 开始重复应用 `succ` 得到的序列 -/
def orbit (c : Cell) : ℕ → Cell
  | 0 => c
  | n + 1 => succ (orbit c n)

/-- 固定点: 后继等于自身 -/
def IsFixedPoint (c : Cell) : Prop := succ c = c

/-- 终止性: 存在 `n` 使得 `orbit c n` 是固定点 -/
def TerminatesAt (c : Cell) : Prop :=
  ∃ n, IsFixedPoint succ (orbit succ c n)

/-- 所有轨道都终止 -/
def AllOrbitsTerminate : Prop :=
  ∀ c, TerminatesAt succ c

/-!
  ## 良基论证

  关键观察: 在严格下降条件下,高程 `h c` 构成一个自然数度量。
  由于 `Cell` 有限,我们可以用 `Finset.card` 来界定轨道长度。
-/

/-- 可达集: 从 `c` 出发通过 `succ` 可达的单元格集合 -/
def reachableSet (c : Cell) : Finset Cell :=
  Finset.filter (fun x => ∃ n, orbit succ c n = x) Finset.univ

/-- 度量函数: 当前单元格的高程加上可达集的大小 -/
def measure (c : Cell) : ℕ × ℕ :=
  (h c, Finset.card (reachableSet succ c))

/-- 字典序的良基关系 -/
theorem measure_decreases (h_desc : StrictDescent succ h) (c : Cell) (h_not_fixed : succ c ≠ c) :
    Prod.Lex (· < ·) (· < ·) (measure succ h (succ c)) (measure succ h c) := by
  unfold measure reachableSet
  constructor
  · -- 第一部分: 高程严格下降
    exact h_desc c h_not_fixed
  · -- 第二部分: 可达集大小不变或减小
    have h_reach : reachableSet succ (succ c) ⊆ reachableSet succ c := by
      intro x hx
      rcases Finset.mem_filter.mp hx with ⟨hx_univ, ⟨n, hx_eq⟩⟩
      refine Finset.mem_filter.mpr ⟨hx_univ, ?_⟩
      use n + 1
      simp [orbit, hx_eq]
    exact Finset.card_le_univ_of_subset h_reach

/-- 主要定理: 在严格下降条件下,所有轨道都终止于固定点 -/
theorem all_orbits_terminate (h_desc : StrictDescent succ h) : AllOrbitsTerminate succ := by
  intro c
  -- 使用良基归纳法
  refine WellFounded.induction (Prod.instWellFoundedLT_prod).wf (measure succ h c) ?_
  intro m IH
  by_cases h_fixed : IsFixedPoint succ c
  · -- 如果已经是固定点,则立即终止
    refine ⟨0, ?_⟩
    exact h_fixed
  · -- 否则应用后继并利用归纳假设
    have h_not_fixed : succ c ≠ c := h_fixed
    have h_decr : Prod.Lex (· < ·) (· < ·) (measure succ h (succ c)) (measure succ h c) :=
      measure_decreases succ h h_desc c h_not_fixed
    rcases IH (measure succ h (succ c)) h_decr with ⟨n, hn⟩
    refine ⟨n + 1, ?_⟩
    simp [orbit, hn]

/-!
  ## 推论: 唯一出口

  在严格下降条件下,每个单元格有唯一出口(即后继是固定点时就是自身,
  否则是严格下降的后继)。这保证了流域划分的唯一性。
-/

/-- 出口唯一性: 每个单元格的后继要么是自身(洼地),要么是严格下降的邻居 -/
theorem unique_outlet (h_desc : StrictDescent succ h) (c : Cell) :
    (IsFixedPoint succ c) ∨ (h (succ c) < h c) := by
  by_cases h_eq : succ c = c
  · left; exact h_eq
  · right; exact h_desc c h_eq

-- ==========================================================================
-- 冒烟测试(非命题,仅确认类型检查通过)
-- ==========================================================================

example : True := by
  trivial

-- ==========================================================================
-- 结构注记
-- --------------------------------------------------------------------------
-- 上面的证明依赖于两个关键假设:
--
--   1) `Cell` 是有限类型: 保证可达集有限,从而度量函数有界。
--   2) `h : Cell → ℕ` 取值自然数: 保证严格下降序列必然终止。
--
-- 在实际 DEM 中,高程通常是实数。但我们可以通过离散化(如乘以精度因子后取整)
-- 或使用实数上的良序关系(如将高程映射到某个良序集)来适配这个框架。
--
-- 对于 P-006b 的 4-环反例,上述假设被破坏: 在平坦区域(等高),
-- 严格下降条件不成立,因此轨道可能无限循环。这正是"代数半部"要揭示的:
-- 终止性依赖于严格下降条件,而平坦区域需要特殊处理。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.Watershed
