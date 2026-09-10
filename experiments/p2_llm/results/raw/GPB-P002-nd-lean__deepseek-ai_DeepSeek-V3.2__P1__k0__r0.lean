/-
  ==========================================================================
   GeoProofBench · P-COMP-1 (algebraic half)
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D 左出口填洼 (Wang & Liu 简化版)
   对偶 : formal/dafny/PCOMP_1.dfy (Dafny 4.11)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件形式化 1D 左出口填洼算子的单调性：
  对于任意输入序列 a，填洼结果 Fill(a) 是非递减序列。

  注意：这是 2D Wang & Liu 填洼在 1D 线性情况下的特化。
  边界条件：左端为出口（索引 0），水只能向左流。
  填洼规则：每个单元格的高程被提升到 max(原始高程, 左侧邻居的填洼后高程)。
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic

namespace VeriGIS.Composition.PitFillingThenWatershed

noncomputable section

/-!
  ## 1D 左出口填洼算子定义

  输入：实数序列 a : ℕ → ℝ
  输出：填洼后序列 fill : ℕ → ℝ，满足：
    fill 0 = a 0
    fill (i+1) = max (a (i+1)) (fill i)

  这对应于 2D Wang & Liu 填洼在 1D 线性网格上的特例，
  其中每个单元格只考虑左侧邻居（左出口）。
-/

/-- 1D 左出口填洼算子 -/
def fill1D (a : ℕ → ℝ) : ℕ → ℝ :=
  Nat.rec (a 0) (fun i fill_i => max (a (i+1)) fill_i)

/-!
  ## 单调性定理

  定理：对于任意输入序列 a，填洼结果 fill1D a 是非递减序列。
  即对于所有 i，有 (fill1D a) i ≤ (fill1D a) (i+1)。

  证明思路：
    1. 基本情况 i=0：由定义 fill1D a 0 = a 0，且 fill1D a 1 = max (a 1) (a 0) ≥ a 0。
    2. 归纳步骤：假设对于 i 成立，证明对于 i+1 也成立。
       利用 max 的性质和归纳假设。
-/

theorem fill1D_nondecreasing (a : ℕ → ℝ) (i : ℕ) :
    fill1D a i ≤ fill1D a (i+1) := by
  induction' i with k IH
  · -- 基本情况 i = 0
    unfold fill1D
    simp [Nat.rec]
    exact le_max_right (a 1) (a 0)
  · -- 归纳步骤 i = k+1
    unfold fill1D at *
    simp [Nat.rec] at IH ⊢
    -- 此时需要证明：max (a (k+1)) (fill1D a k) ≤ max (a (k+2)) (max (a (k+1)) (fill1D a k))
    have h1 : fill1D a k ≤ max (a (k+1)) (fill1D a k) := le_max_right _ _
    have h2 : a (k+1) ≤ max (a (k+1)) (fill1D a k) := le_max_left _ _
    -- 由归纳假设 IH: fill1D a k ≤ max (a (k+1)) (fill1D a k)
    -- 且 max (a (k+1)) (fill1D a k) ≤ max (a (k+2)) (max (a (k+1)) (fill1D a k))
    exact le_max_of_le_right (by
      -- 需要证明：max (a (k+1)) (fill1D a k) ≤ max (a (k+2)) (max (a (k+1)) (fill1D a k))
      refine le_max_right _ _)

-- 更简洁的证明版本，利用 `le_max_right` 直接得到
theorem fill1D_nondecreasing' (a : ℕ → ℝ) (i : ℕ) :
    fill1D a i ≤ fill1D a (i+1) := by
  unfold fill1D
  induction' i with k IH
  · simp [Nat.rec]
    exact le_max_right (a 1) (a 0)
  · simp [Nat.rec]
    exact le_max_right (a (k+2)) (max (a (k+1)) (Nat.rec (a 0) (fun i fill_i => max (a (i+1)) fill_i) k))

/-!
  ## 冒烟测试：验证算子在具体输入上的行为
-/

-- 测试1：常数序列
example : fill1D (fun _ => 5) = (fun _ => 5) := by
  ext i
  induction' i with k IH
  · rfl
  · unfold fill1D at *
    simp [Nat.rec, IH]

-- 测试2：递增序列
example (i : ℕ) : fill1D (fun n => (n : ℝ)) i = (i : ℝ) := by
  induction' i with k IH
  · rfl
  · unfold fill1D
    simp [Nat.rec, IH]
    have : (k : ℝ) ≤ (k+1 : ℝ) := by simp
    simp [max_eq_left this]

-- 测试3：递减序列（填洼后变为常数）
example : fill1D (fun n => 10 - (n : ℝ)) 0 = 10 := rfl
example : fill1D (fun n => 10 - (n : ℝ)) 1 = 10 := by
  unfold fill1D
  simp [Nat.rec]
example : fill1D (fun n => 10 - (n : ℝ)) 2 = 10 := by
  unfold fill1D
  simp [Nat.rec]

/-!
  ## 与 2D Wang & Liu 填洼的关系

  1D 左出口填洼是 2D 填洼在以下配置下的特例：
    - 网格：1×n 的单行网格
    - 出口：最左侧单元格 (0,0)
    - 邻居关系：只考虑左侧邻居（4-连通中的左邻居）

  2D Wang & Liu 填洼的规则：
    fill(r,c) = max(orig(r,c), min_{n∈N4(r,c)} fill(n))
  在 1D 左出口情况下简化为：
    fill(i) = max(orig(i), fill(i-1))  对于 i>0
    fill(0) = orig(0)

  这正是我们定义的 `fill1D`。
-/

/-- 1D 填洼保持边界值不变 -/
theorem fill1D_boundary (a : ℕ → ℝ) : fill1D a 0 = a 0 := rfl

/-- 1D 填洼是原始高程的下界 -/
theorem fill1D_ge_original (a : ℕ → ℝ) (i : ℕ) : a i ≤ fill1D a i := by
  induction' i with k IH
  · rfl
  · unfold fill1D
    simp [Nat.rec]
    exact le_max_left _ _

/-- 1D 填洼的递推关系 -/
theorem fill1D_rec (a : ℕ → ℝ) (i : ℕ) :
    fill1D a (i+1) = max (a (i+1)) (fill1D a i) := rfl

end -- noncomputable section

end VeriGIS.Composition.PitFillingThenWatershed
