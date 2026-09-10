/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   算子 : 严格下降 D8 后继下的轨道终止性
   对偶 : formal/dafny/P006_watershed.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件证明：在有限栅格上，若每个单元的后继严格下降（高程），则从任意单元出发的
  D8 流动轨道必然终止于一个不动点（出口或坑）。证明使用良基论证：定义从单元到
  剩余可访问单元数的度量，该度量在每一步严格递减。

  注意：这里不假设 DEM 无坑（允许 NoFlow），只要求后继关系是严格下降的偏函数。
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic

namespace VeriGIS.Watershed

noncomputable section

/-!
  ## 基本定义
  设 Cell 为有限类型（例如栅格坐标的有限集合）。
  后继关系 `succ : Cell → Option Cell` 表示 D8 流动方向：
    - `succ c = some c'` 表示 c 流向 c'（且高程严格下降）
    - `succ c = none` 表示 c 是坑（NoFlow）
  严格下降条件：若 `succ c = some c'`，则 `height c' < height c`。
  这里我们直接将该条件作为假设引入。
-/

variable {Cell : Type} [Fintype Cell] [DecidableEq Cell]
variable (height : Cell → ℕ)  -- 高程函数，取自然数以简化良基性
variable (succ : Cell → Option Cell)  -- D8 后继关系

/-- 严格下降条件：若后继存在，则高程严格下降。 -/
def StrictDescent : Prop :=
  ∀ c c', succ c = some c' → height c' < height c

/-- 轨道：从起点出发，反复应用后继，直到遇到 none 或重复。 -/
inductive Orbit : Cell → Cell → Prop where
  | start (c : Cell) : Orbit c c
  | step {c c' c'' : Cell} (hstep : succ c = some c') (horbit : Orbit c' c'') :
      Orbit c c''

/-- 不动点：单元是自身的后继，或无后继。 -/
def IsFixedPoint (c : Cell) : Prop :=
  succ c = none ∨ ∃ c', succ c = some c' ∧ c' = c

/-- 可达集：从 c 出发通过后继能到达的所有单元。 -/
def reachableSet (c : Cell) : Finset Cell :=
  { c' | Orbit succ c c' }

/-- 度量：剩余可访问单元数。 -/
def remainingSteps (c : Cell) : ℕ :=
  (reachableSet succ c).card

/-!
  ## 主要定理：严格下降后继下的轨道终止性
  证明思路：
    1. 若轨道进入循环，则存在 c 使得 `Orbit succ c c` 且 `succ c = some c'`。
    2. 由 StrictDescent，`height c' < height c`。
    3. 但由 Orbit.step 和循环性，又有 `Orbit succ c' c`，故 `height c ≤ height c'`，
       矛盾。
    4. 因此轨道无循环，又因 Cell 有限，故必终止于不动点。
  我们使用良基论证：定义度量 `remainingSteps`，证明每步严格递减。
-/

theorem orbit_terminates_at_fixed_point (hdesc : StrictDescent height succ) :
    ∀ (c : Cell), ∃ (fp : Cell), Orbit succ c fp ∧ IsFixedPoint succ fp := by
  intro c
  -- 定义度量函数
  set μ := remainingSteps succ with hμ_def
  have hμ_wf : WellFounded (InvImage (· < ·) μ) :=
    InvImage.wf μ (Nat.lt_wfRel.wf)
  refine WellFounded.induction hμ_wf c ?_
  intro c ih
  -- 情况分析：c 是否为不动点
  by_cases hfp : IsFixedPoint succ c
  · -- c 自身就是不动点
    refine ⟨c, Orbit.start c, hfp⟩
  · -- c 不是不动点，则必有严格下降的后继
    rcases not_isFixedPoint_iff.mp hfp with ⟨c', hsucc, hne⟩
    have hlt : height c' < height c := hdesc c c' hsucc
    -- 递归调用：从 c' 出发的轨道终止于某个不动点 fp
    rcases ih c' (by
        -- 证明度量严格递减：c' 的可达集是 c 的可达集的真子集
        have hsub : reachableSet succ c' ⊂ reachableSet succ c := by
          refine Finset.ssubset_of_subset_of_not_subset ?_ ?_
          · intro x hx
            rcases hx with ⟨hx_orbit⟩
            exact ⟨Orbit.step hsucc hx_orbit⟩
          · intro h
            have : c ∈ reachableSet succ c' := h ⟨Orbit.start c⟩
            rcases this with ⟨h_orbit⟩
            -- 由 Orbit 无循环（由 StrictDescent 保证）导出矛盾
            have : height c < height c := by
              apply lt_of_le_of_lt ?_ hlt
              clear hlt
              induction' h_orbit with d d _ d'' hstep' h_orbit' ih'
              · rfl
              · have := hdesc d d'' hstep'
                exact le_of_lt (ih'.trans_lt this)
            exact lt_irrefl _ this
        simp [μ, remainingSteps, hμ_def]
        exact Finset.card_lt_card hsub) with ⟨fp, h_orbit, h_fp⟩
    -- 组合轨道：c → c' → ... → fp
    refine ⟨fp, Orbit.step hsucc h_orbit, h_fp⟩

/-- 辅助引理：非不动点的刻画。 -/
theorem not_isFixedPoint_iff {c : Cell} :
    ¬ IsFixedPoint succ c ↔ ∃ c', succ c = some c' ∧ c' ≠ c := by
  constructor
  · intro h
    simp [IsFixedPoint] at h
    rcases em (succ c = none) with (hnone | hsome)
    · exfalso; exact h (Or.inl hnone)
    · rcases Option.ne_none_iff_exists'.mp hsome with ⟨c', hc'⟩
      refine ⟨c', hc', ?_⟩
      intro heq
      subst heq
      exact h (Or.inr ⟨c', hc', rfl⟩)
  · rintro ⟨c', hsucc, hne⟩ ⟨hnone | ⟨c'', hsucc', heq⟩⟩
    · rw [hsucc] at hnone; contradiction
    · rw [hsucc] at hsucc'; injection hsucc' with heq'; subst heq'
      exact hne rfl

-- ==========================================================================
-- 冒烟测试：在具体有限集上验证
-- ==========================================================================

section SmokeTest

-- 定义一个简单的 2×2 栅格
@[derive [Fintype, DecidableEq]]
inductive TestCell
  | c00 | c01 | c10 | c11

open TestCell

def testHeight : TestCell → ℕ
  | c00 => 3
  | c01 => 2
  | c10 => 1
  | c11 => 0

def testSucc : TestCell → Option TestCell
  | c00 => some c01
  | c01 => some c11
  | c10 => some c11
  | c11 => none

theorem testStrictDescent : StrictDescent testHeight testSucc := by
  intro c c' h
  simp [testSucc] at h
  repeat (cases c <;> try cases c' <;> try contradiction)
  all_goals { simp [testHeight]; decide }

example : ∃ (fp : TestCell), Orbit testSucc c00 fp ∧ IsFixedPoint testSucc fp := by
  have := orbit_terminates_at_fixed_point testHeight testSucc testStrictDescent c00
  exact this

end SmokeTest

-- ==========================================================================
-- 注记
-- --------------------------------------------------------------------------
-- 1. 本证明不依赖 DEM 的具体形状（平面、坑或人工平坦面），只要求严格下降条件。
-- 2. 度量 `remainingSteps` 的递减性基于可达集真子集关系，这由 StrictDescent
--    保证的无循环性推导得出。
-- 3. 在 Lean 中，我们使用 `WellFounded` 和 `InvImage` 来包装自然数度量的良基性，
--    这是处理有限集上终止性证明的标准方法。
-- 4. 对比 Dafny 版本：Dafny 使用 `decreases` 子句和 SMT 自动证明终止；
--    Lean 需要显式构造度量并证明其递减性，但推理更透明。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.Watershed
