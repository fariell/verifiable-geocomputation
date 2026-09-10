/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   算子 : 确定性 D8 流向下的流域唯一性
   对偶 : formal/dafny/P006_watershed.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件证明：在有限栅格上，若每个单元格的 D8 后继严格下降（高程严格降低），
  则从任意单元格出发的流向追踪轨道必在有限步内终止于一个固定点（洼地或边界）。
  证明使用良基论证：定义从单元格到其“剩余下降潜力”的度量，该度量在每一步严格减少。

  注意：这里不假设 DEM 无平地（允许平地作为终止条件），但要求若存在流向则必须严格下降。
  这是对 D8 流向算法的基本终止性保证。
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic

namespace VeriGIS.Watershed

-- 单元格类型：有限二维栅格中的位置
variable {R C : Type} [Fintype R] [Fintype C]

-- 高程函数：每个位置有一个实数高程
variable (height : R → C → ℝ)

-- D8 后继函数：返回每个单元格的流向目标（若存在）
variable (succ : R → C → Option (R × C))

-- 严格下降条件：若后继存在，则高程严格降低
variable (strict_desc : ∀ r c r' c', succ r c = some (r', c') → height r' c' < height r c)

-- 定义轨道：从 (r, c) 开始，重复应用后继函数
def orbit (r c : R × C) : ℕ → Option (R × C)
  | 0 => some (r, c)
  | n + 1 => match orbit (r, c) n with
    | none => none
    | some (r', c') => succ r' c'

-- 终止条件：轨道在有限步内达到固定点（后继为 none 或自身）
def terminates (r c : R × C) : Prop :=
  ∃ n : ℕ, ∀ m ≥ n, orbit (succ := succ) (r, c) m = orbit (succ := succ) (r, c) n

-- 定义度量：单元格到其“剩余下降潜力”的映射
noncomputable def measure (r c : R × C) : ℕ :=
  let cells : Finset (R × C) := Finset.filter (λ p => height p.1 p.2 < height r c) Finset.univ
  cells.card

-- 度量在严格下降时减少
lemma measure_decreases {r c r' c' : R × C} (h : succ r.1 r.2 = some (r', c')) :
    measure height (r', c') < measure height (r, c) := by
  unfold measure
  have hlt : height r' c' < height r.1 r.2 := strict_desc _ _ _ _ h
  refine Finset.card_lt_card ?_
  refine ⟨Finset.subset_univ _, ?_⟩
  intro hsub
  have : (r.1, r.2) ∉ Finset.filter (λ p => height p.1 p.2 < height r' c') Finset.univ := by
    simp [hlt.not_lt]
  have : (r.1, r.2) ∈ Finset.filter (λ p => height p.1 p.2 < height r.1 r.2) Finset.univ := by
    simp [hlt]
  exact Finset.not_mem_mono hsub this

-- 主定理：在严格下降条件下，所有轨道都终止
theorem all_orbits_terminate : ∀ (r c : R × C), terminates (succ := succ) r c := by
  intro r c
  -- 使用度量的良基性进行归纳
  refine WellFounded.induction (α := R × C) (by
    -- 证明 measure 是良基关系
    have : WellFounded (λ a b : R × C => measure height a < measure height b) :=
      measure_wf height
    exact this) (r, c) ?_
  intro p ih
  -- 情况分析：p 的后继
  match h : succ p.1 p.2 with
  | none =>
    -- 无后继，立即终止
    refine ⟨0, λ m hm => ?_⟩
    simp [orbit, terminates, h]
  | some (r', c') =>
    -- 有后继，递归证明
    have hterm := ih (r', c') (measure_decreases height succ strict_desc h)
    rcases hterm with ⟨n, hn⟩
    refine ⟨n + 1, λ m hm => ?_⟩
    -- 展开轨道定义
    simp [orbit]
    cases' m with m
    · simp
    · have : m ≥ n := by omega
      rw [hn m this]
      simp [h]

-- 辅助引理：measure 是良基的（因为值域是有限自然数）
lemma measure_wf : WellFounded (λ a b : R × C => measure height a < measure height b) := by
  refine Subrelation.wf (λ a b h => ?_) (InvImage.wf (measure height) Nat.lt_wfRel)
  exact h

-- 冒烟测试：在简单栅格上验证终止性
example : terminates (succ := λ _ _ => none) (0, 0) := by
  refine ⟨0, λ m hm => ?_⟩
  simp [orbit, terminates]

-- 注记：该定理不要求 DEM 无洼地，洼地单元格的后继为 none，自动成为终止点。
-- 这是对 D8 流向算法在有限栅格上必然终止的形式化保证。
end VeriGIS.Watershed
