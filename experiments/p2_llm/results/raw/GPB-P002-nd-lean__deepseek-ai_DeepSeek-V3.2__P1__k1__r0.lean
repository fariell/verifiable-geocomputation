/-
  ==========================================================================
   GeoProofBench · P-COMP-1 (1D left-outlet fill monotonicity)
   文件 : formal/lean4/VeriGIS/Composition/LeftOutletFillMonotone.lean
   算子 : 1D 左出口填注 (Wang & Liu 一维简化)
   对偶 : formal/dafny/PCOMP_1.dfy (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本 PCOMP_1 的**独立**重述 —— 不是翻译。
  核心定理: 一维左出口填注算子产生的序列是非递减的。

  注意: 一维左出口填注是二维 W&L 填注在单行上的特化:
    - 边界种子: 最左侧单元格 (索引 0) 为出口
    - 传播方向: 从左向右
    - 更新规则: fill[i] = max(orig[i], fill[i-1])
  这等价于累积最大值算子,但我们需要从算法描述出发形式化。
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic
import Mathlib.Data.List.Basic

namespace VeriGIS.Composition.LeftOutletFill

noncomputable section

/-!
  ## 1D 左出口填注算子定义

  给定原始高程序列 `orig : List ℝ`, 返回填注后的序列 `fill : List ℝ`.
  算法步骤:
    1. 初始化 `fill[0] = orig[0]` (左边界种子)
    2. 对 i = 1 到 n-1:
        `fill[i] = max (orig[i]) (fill[i-1])`
-/

/-- 一维左出口填注算子 -/
def leftOutletFill (orig : List ℝ) : List ℝ :=
  match orig with
  | [] => []
  | h :: t =>
      let rec loop (prev : ℝ) (rest : List ℝ) : List ℝ :=
        match rest with
        | [] => []
        | x :: xs =>
            let cur := max x prev
            cur :: loop cur xs
      h :: loop h t

/-!
  ## 辅助引理
-/

/-- `leftOutletFill` 输出长度等于输入长度 -/
theorem length_leftOutletFill (orig : List ℝ) :
    (leftOutletFill orig).length = orig.length := by
  induction' orig with h t ih
  · simp [leftOutletFill]
  · simp [leftOutletFill]
    cases t
    · simp
    · simp [ih]

/-- 递归步骤中 `cur` 的定义性质 -/
lemma loop_def (prev x : ℝ) (xs : List ℝ) :
    leftOutletFill.loop prev (x :: xs) = max x prev :: leftOutletFill.loop (max x prev) xs :=
  rfl

/-- 循环不变式: 每一步的 `prev` 是已处理部分的最大值 -/
lemma loop_monotone_aux (prev : ℝ) (xs : List ℝ) :
    ∀ y ∈ leftOutletFill.loop prev xs, prev ≤ y := by
  induction' xs with h t ih
  · simp
  · intro y hy
    rw [loop_def] at hy
    rcases hy with (rfl | hy)
    · exact le_max_right _ _
    · exact (ih hy).trans (le_max_right _ _)

/-- 填注序列中相邻元素满足 `fill[i] ≤ fill[i+1]` -/
theorem leftOutletFill_non_decreasing (orig : List ℝ) :
    ∀ i : ℕ, i + 1 < (leftOutletFill orig).length →
      (leftOutletFill orig).get ⟨i, by omega⟩ ≤ (leftOutletFill orig).get ⟨i+1, by omega⟩ := by
  intro i hi
  have hlen := length_leftOutletFill orig
  have hi' : i + 1 < orig.length := by
    rwa [hlen] at hi
  induction' orig with h t ih generalizing i
  · simp at hi'
  · simp [leftOutletFill] at hi ⊢
    cases' t with h2 t
    · simp at hi'
    · by_cases hi0 : i = 0
      · subst hi0
        simp [leftOutletFill.loop]
        exact le_max_right _ _
      · have : i - 1 + 1 < (h2 :: t).length := by
          have := Nat.sub_lt (by omega) (by omega)
          omega
        specialize ih (i - 1) this
        simp at ih ⊢
        exact ih.trans (le_max_right _ _)

/-- 更直观的表述: 对于所有有效索引 i, fill[i] ≤ fill[i+1] -/
theorem leftOutletFill_monotone (orig : List ℝ) :
    ∀ i, i < (leftOutletFill orig).length - 1 →
      (leftOutletFill orig)[i] ≤ (leftOutletFill orig)[i+1] := by
  intro i hi
  have := leftOutletFill_non_decreasing orig i (by omega)
  simp [List.getElem_eq_get] at this ⊢
  exact this

/-!
  ## 冒烟测试
-/

example : leftOutletFill [1, 3, 2, 5, 4] = [1, 3, 3, 5, 5] := by
  native_decide

example : leftOutletFill ([] : List ℝ) = [] := by
  simp [leftOutletFill]

example : leftOutletFill [5] = [5] := by
  simp [leftOutletFill]

/-!
  ## 结构注记

  一维左出口填注的单调性源于其累积最大值结构:
    fill[i] = max_{j ≤ i} orig[j]
  因此自然有 fill[i] ≤ fill[i+1].

  在二维 W&L 填注中,单调性只在传播方向上成立(4-邻域洪水),
  且需要更复杂的不变式证明。这里的一维特化是理解二维算法
  单调性质的基础构件。
-/

end -- noncomputable section

end VeriGIS.Composition.LeftOutletFill
