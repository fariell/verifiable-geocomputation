/-
  ==========================================================================
   GeoProofBench · P-COMP-1 (algebraic half)
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D 左出口填充 (Wang & Liu 简化版)
   对偶 : formal/dafny/PCOMP_1.dfy (Dafny 4.11)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

   本文件形式化 1D 左出口填充算子的单调性：
   对于任意输入序列 a，填充结果 Fill(a) 是非递减序列。
   ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic
import Mathlib.Data.List.Basic

namespace VeriGIS.Composition.PitFillingThenWatershed

noncomputable section

/-!
  ## 1D 左出口填充算子定义

  给定高程序列 a : List ℝ，从左向右扫描：
    - 边界条件：左端点保持原值
    - 递推规则：Fill[i] = max(a[i], Fill[i-1])

  这对应于 2D Wang & Liu 填充在 1D 线性情况下的简化，
  其中“4-邻域”退化为左邻域。
-/

/-- 1D 左出口填充算子 -/
def fill1D : List ℝ → List ℝ
  | [] => []
  | x :: xs =>
    let rec loop : ℝ → List ℝ → List ℝ
      | prev, [] => []
      | prev, y :: ys =>
        let cur := max y prev
        cur :: loop cur ys
    x :: loop x xs

/-!
  ## 主要定理：填充结果是非递减序列

  定理陈述：对于任意 i < length(fill1D a) - 1，
  有 fill1D a[i] ≤ fill1D a[i+1]。

  注意：这里使用 List.get 访问元素，需要处理索引边界。
-/

theorem fill1D_nondecreasing (a : List ℝ) :
    ∀ (i : ℕ) (hi : i + 1 < (fill1D a).length),
      (fill1D a).get ⟨i, by omega⟩ ≤ (fill1D a).get ⟨i + 1, hi⟩ := by
  intro a
  -- 情况分析：空序列平凡成立
  cases a with
  | nil =>
    intro i hi
    exfalso
    simp [fill1D] at hi
  | cons x xs =>
    -- 展开 fill1D 定义
    simp [fill1D] at *
    -- 定义辅助函数和不变式
    let rec loop_prop (prev : ℝ) (xs : List ℝ) :
        ∀ (i : ℕ) (hi : i + 1 < (loop prev xs).length),
          (loop prev xs).get ⟨i, by omega⟩ ≤ (loop prev xs).get ⟨i + 1, hi⟩ := by
      intro prev xs
      induction xs with
      | nil =>
        intro i hi
        exfalso
        simp [loop] at hi
      | cons y ys ih =>
        intro i hi
        simp [loop] at *
        -- 当前填充值 cur = max y prev
        let cur := max y prev
        cases i with
        | zero =>
          -- 比较第一个元素和第二个元素
          simp [List.get]
          exact le_max_right _ _
        | succ i =>
          -- 递归情况
          have hi' : i + 1 < (loop cur ys).length := by
            simpa using hi
          exact ih hi'
    -- 应用辅助引理
    intro i hi
    cases i with
    | zero =>
      -- 比较第一个元素(x)和第二个元素
      simp [List.get]
      cases xs with
      | nil => exfalso; simp at hi
      | cons y ys =>
        simp [loop]
        exact le_max_right _ _
    | succ i =>
      -- 递归情况
      have hi' : i + 1 < (loop x xs).length := by
        simpa using hi
      exact loop_prop x xs i hi'

/-!
  ## 冒烟测试：验证定义和定理
-/

-- 测试1：空序列
example : fill1D ([] : List ℝ) = [] := by
  rfl

-- 测试2：单元素序列
example : fill1D [3.0] = [3.0] := by
  norm_num [fill1D]

-- 测试3：简单递增序列
example : fill1D [1.0, 2.0, 3.0] = [1.0, 2.0, 3.0] := by
  norm_num [fill1D]

-- 测试4：有坑的序列
example : fill1D [3.0, 1.0, 2.0] = [3.0, 3.0, 3.0] := by
  norm_num [fill1D]

-- 测试5：定理应用示例
example : ∀ (i : ℕ) (hi : i + 1 < (fill1D [3.0, 1.0, 2.0]).length),
    (fill1D [3.0, 1.0, 2.0]).get ⟨i, by omega⟩ ≤
    (fill1D [3.0, 1.0, 2.0]).get ⟨i + 1, hi⟩ := by
  apply fill1D_nondecreasing

/-!
  ## 结构注记

  1D 左出口填充的单调性证明相对直接，因为递推规则
    Fill[i] = max(a[i], Fill[i-1])
  保证了 Fill[i] ≥ Fill[i-1]。

  这对应于 2D Wang & Liu 填充性质 (i) 的特例：
    "After W&L fill, every cell with a 4-neighbour has min(nbr) ≤ cell."
  在 1D 中，"4-neighbour" 退化为左邻域，"min(nbr)" 就是 Fill[i-1]。

  该性质是 P-COMP-1 代数部分的基础，保证了填充后的地形
  在流向计算中不会产生局部极小值（除了边界）。
-/

end -- noncomputable section

end VeriGIS.Composition.PitFillingThenWatershed
