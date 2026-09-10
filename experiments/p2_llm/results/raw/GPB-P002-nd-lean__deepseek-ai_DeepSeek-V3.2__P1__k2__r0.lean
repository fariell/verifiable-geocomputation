/-
  ==========================================================================
   GeoProofBench · P-COMP-1 (algebraic half)
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D 左出口填注 (left-outlet Fill)
   性质 : 填注后序列单调非减
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件形式化 W&L 填注算法在一维情况下的单调性：
  对于任意输入序列 a，填注结果 Fill(a) 满足 ∀ i, Fill(a)[i] ≤ Fill(a)[i+1]。

  注意：一维情况是二维 4-邻域填注的特例（仅考虑左右邻居）。
  填注规则：边界单元保持原高程，内部单元逐步抬升至 max(原高程, 已填注邻居高程)。
  左出口约定：填注从最左单元开始向右传播。
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic
import Mathlib.Data.List.Basic

namespace VeriGIS.Composition.PitFillingThenWatershed

noncomputable section

/-!
  ## 1D 左出口填注算子定义

  输入：实数列表 `a : List ℝ`，表示原始高程序列。
  输出：填注后的高程序列，与输入同长度。

  算法步骤：
    1. 最左单元（索引 0）保持原高程。
    2. 对于第 i 单元（i > 0），其填注高程为 max(a[i], fill[i-1])。
  这等价于累积最大值（cumulative max），但注意我们使用 max(原值, 左邻居填注值)。
-/

/-- 1D 左出口填注算子 -/
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
  ## 辅助引理：填注序列的单调性结构
-/

/-- 填注序列中每个元素不小于其前驱 -/
theorem fill1D_non_decreasing_aux (prev : ℝ) (ys : List ℝ) :
    ∀ (i : ℕ) (hi : i < (loop prev ys).length),
      (loop prev ys).get ⟨i, hi⟩ ≤ (loop prev ys).get ⟨i + 1, by
        have := Nat.lt_of_succ_lt_succ hi
        simpa [loop] using this⟩ := by
  induction ys generalizing prev with
  | nil => intro i hi; exfalso; linarith [List.length_loop_nil]  -- 空列表无索引
  | cons y ys ih =>
    intro i hi
    simp [loop] at hi ⊢
    cases i with
    | zero =>
      simp [loop]
      exact le_max_right _ _
    | succ i =>
      have hi' : i < (loop (max y prev) ys).length := by
        simpa [loop] using Nat.succ_lt_succ_iff.mp hi
      exact ih (max y prev) i hi'
where
  loop (prev : ℝ) : List ℝ → List ℝ
    | [] => []
    | y :: ys => max y prev :: loop (max y prev) ys

/-- 主定理：填注序列单调非减 -/
theorem fill1D_non_decreasing (a : List ℝ) (i : ℕ) (hi : i + 1 < (fill1D a).length) :
    (fill1D a).get ⟨i, by omega⟩ ≤ (fill1D a).get ⟨i + 1, hi⟩ := by
  cases a with
  | nil => exfalso; simpa [fill1D] using hi
  | cons x xs =>
    simp [fill1D]
    cases i with
    | zero =>
      simp [fill1D]
      exact le_max_right _ _
    | succ i =>
      have hi' : i + 1 < (loop x xs).length := by
        simpa [loop] using hi
      exact fill1D_non_decreasing_aux x xs i hi'
where
  loop (prev : ℝ) : List ℝ → List ℝ
    | [] => []
    | y :: ys => max y prev :: loop (max y prev) ys

/-!
  ## 冒烟测试：验证算子行为
-/

/-- 空序列填注后仍为空 -/
example : fill1D ([] : List ℝ) = [] := by
  rfl

/-- 单元素序列填注后不变 -/
example : fill1D [5.0] = [5.0] := by
  norm_num [fill1D]

/-- 单调序列填注后不变 -/
example : fill1D [1.0, 2.0, 3.0] = [1.0, 2.0, 3.0] := by
  norm_num [fill1D]

/-- 坑序列被填平 -/
example : fill1D [3.0, 1.0, 2.0] = [3.0, 3.0, 3.0] := by
  norm_num [fill1D]

/-- 验证单调性：对于上述例子，索引 0 ≤ 索引 1 -/
example : (fill1D [3.0, 1.0, 2.0]).get ⟨0, by decide⟩ ≤
          (fill1D [3.0, 1.0, 2.0]).get ⟨1, by decide⟩ := by
  norm_num [fill1D]

/-!
  ## 与二维填注的关系

  一维左出口填注是二维 4-邻域 W&L 填注在以下情况下的特例：
    - 网格只有一行（或一列）
    - 仅考虑水平邻居（左/右）
    - 边界为最左单元

  二维性质 "After W&L fill, every cell with a 4-neighbour has min(nbr) ≤ cell"
  在一维退化为 "每个单元（除最左）的左邻居填注值 ≤ 当前单元填注值"，
  这正是本定理所证明的。
-/

end -- noncomputable section

end VeriGIS.Composition.PitFillingThenWatershed
