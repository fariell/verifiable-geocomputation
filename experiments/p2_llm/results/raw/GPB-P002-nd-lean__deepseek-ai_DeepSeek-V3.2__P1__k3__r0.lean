/-
  ==========================================================================
   GeoProofBench · P-COMP-1 (algebraic half)
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D left-outlet Fill (Wang & Liu 4-connected flood)
   对偶 : formal/dafny/PCOMP_1.dfy (Dafny 4.11)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件形式化 W&L 填洼算子的单调性: 对于任意输入高程序列 a,
  填洼结果 Fill(a) 是非递减序列。

  注意: 这是 1D 简化版本,对应 2D 中沿某一行/列的填洼结果。
  算子语义: 从最左侧单元(视为出口)开始,向右传播填洼高程。
  每个单元的高程被提升为 max(原始高程, 左侧相邻单元的填洼后高程)。

  与 Horn 坡度不同,这里处理的是离散序列而非连续函数,
  因此使用 `Fin n → ℝ` 表示长度为 n 的高程序列。
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic

namespace VeriGIS.Composition.PitFillingThenWatershed

noncomputable section

/-!
  ## 1D left-outlet Fill 算子定义

  给定长度为 n 的高程序列 a : Fin n → ℝ,
  定义填洼结果 fill : Fin n → ℝ 为:

    fill 0 = a 0
    fill (i+1) = max (a (i+1)) (fill i)

  这对应于 2D W&L 填洼在 1D 线性情况下的行为,
  其中最左侧单元视为边界出口。
-/

/-- 1D left-outlet Fill 算子 -/
def fill1D (a : Fin n → ℝ) : Fin n → ℝ :=
  match n with
  | 0 => Fin.elim0
  | n+1 =>
    let rec loop : Fin (n+1) → ℝ
      | ⟨0, _⟩ => a ⟨0, by omega⟩
      | ⟨i+1, hi⟩ =>
        let prev := loop ⟨i, by omega⟩
        max (a ⟨i+1, hi⟩) prev
    loop

/-- Fill 结果的递推关系 -/
theorem fill1D_zero (a : Fin (n+1) → ℝ) : fill1D a ⟨0, by omega⟩ = a ⟨0, by omega⟩ := by
  unfold fill1D
  simp

theorem fill1D_succ (a : Fin (n+1) → ℝ) (i : Fin n) :
    fill1D a ⟨i.1 + 1, by exact Nat.lt_succ_of_lt i.2⟩ =
      max (a ⟨i.1 + 1, by exact Nat.lt_succ_of_lt i.2⟩) (fill1D a ⟨i.1, i.2⟩) := by
  unfold fill1D
  simp

/-!
  ## 主要定理: Fill 结果是非递减序列

  对于所有 i < n-1, 有 fill[i] ≤ fill[i+1]
-/

theorem fill1D_nondecreasing (a : Fin n → ℝ) (i : Fin (n-1)) :
    fill1D a ⟨i.1, by
      have := i.2
      omega⟩ ≤
    fill1D a ⟨i.1 + 1, by
      have := i.2
      omega⟩ := by
  cases' n with n
  · exfalso; exact Nat.not_lt_zero _ i.2
  · have hi : i.1 < n := by
      have := i.2
      omega
    rw [fill1D_succ a ⟨i.1, hi⟩]
    exact le_max_right _ _

/-- 等价表述: 对于所有满足 i < j 的索引, fill[i] ≤ fill[j] -/
theorem fill1D_monotone (a : Fin n → ℝ) {i j : Fin n} (h : i ≤ j) :
    fill1D a i ≤ fill1D a j := by
  revert j
  refine Fin.inductionOn i ?_ ?_
  · intro j _
    have : j.1 = 0 := by omega
    subst this
    rfl
  · intro i ih j h
    have hij : i.1 + 1 ≤ j.1 := by
      have := h
      omega
    cases' lt_or_eq_of_le hij with hij hij
    · have : i.1 < j.1 := hij
      have hfill := fill1D_nondecreasing a ⟨i.1, by omega⟩
      have := ih ⟨j.1 - 1, by omega⟩ (by omega)
      calc
        fill1D a ⟨i.1 + 1, by omega⟩ ≤ fill1D a ⟨i.1 + 1, by omega⟩ := le_rfl
        _ ≤ fill1D a ⟨i.1 + 2, by omega⟩ := fill1D_nondecreasing a ⟨i.1 + 1, by omega⟩
        _ ≤ fill1D a ⟨j.1, j.2⟩ := ?_
      sorry  -- 需要归纳证明
    · subst hij
      rfl

/-!
  ## 辅助性质
-/

/-- Fill 结果不低于原始高程 -/
theorem fill1D_ge_original (a : Fin n → ℝ) (i : Fin n) : a i ≤ fill1D a i := by
  cases' n with n
  · exact Fin.elim0 i
  · induction' i using Fin.induction with i ih
    · rw [fill1D_zero]
    · rw [fill1D_succ]
      exact le_max_left _ _

/-- 最左侧单元保持不变 -/
theorem fill1D_leftmost (a : Fin (n+1) → ℝ) : fill1D a 0 = a 0 :=
  fill1D_zero a

/-- 平坦序列的 Fill 结果不变 -/
theorem fill1D_flat (c : ℝ) : fill1D (fun _ : Fin n => c) = fun _ => c := by
  ext i
  induction' i using Fin.induction with i ih
  · simp [fill1D_zero]
  · simp [fill1D_succ, ih, le_max_iff]
    left
    rfl

/-- 单调输入序列的 Fill 结果等于原序列 -/
theorem fill1D_of_monotone (a : Fin n → ℝ) (h : ∀ i j, i ≤ j → a i ≤ a j) :
    fill1D a = a := by
  ext i
  induction' i using Fin.induction with i ih
  · simp [fill1D_zero]
  · rw [fill1D_succ, ih]
    have := h ⟨i.1, i.2⟩ ⟨i.1 + 1, by omega⟩ (by omega)
    simp [this]

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

example : fill1D (fun i : Fin 3 => (i : ℝ)) 0 = 0 := by
  norm_num [fill1D]

example : fill1D (fun i : Fin 3 => (i : ℝ)) 1 = 1 := by
  norm_num [fill1D]

example : fill1D (fun i : Fin 3 => (i : ℝ)) 2 = 2 := by
  norm_num [fill1D]

example (a : Fin 3 → ℝ) : fill1D a 0 ≤ fill1D a 1 :=
  fill1D_nondecreasing a ⟨0, by decide⟩

example (a : Fin 3 → ℝ) : fill1D a 1 ≤ fill1D a 2 :=
  fill1D_nondecreasing a ⟨1, by decide⟩

-- ==========================================================================
-- 与 2D W&L 填洼的关系
-- --------------------------------------------------------------------------
-- 1D left-outlet Fill 是 2D W&L 填洼在以下特殊情况下的投影:
--
--   1. 只考虑单一行(或列)
--   2. 最左侧单元视为边界出口(高程固定)
--   3. 只向右传播填洼(对应 4-邻域中的右侧邻居)
--
-- 这个简化保留了填洼的核心单调性性质,同时避免了 2D 的复杂性。
-- 在完整的 P-COMP-1 中,这个性质用于证明:
--   (i) 填洼后,每个有 4-邻域的单元满足 min(邻居) ≤ 单元高程
-- ==========================================================================

end -- noncomputable section

end VeriGIS.Composition.PitFillingThenWatershed
