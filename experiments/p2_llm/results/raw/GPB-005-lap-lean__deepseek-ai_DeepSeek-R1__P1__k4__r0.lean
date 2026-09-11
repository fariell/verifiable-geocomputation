/-
  ==========================================================================
   GeoProofBench · P-003 (local maximum and Laplacian)
   文件 : formal/lean4/VeriGIS/LocalMaxLaplacian.lean
   命题 : 局部极大值蕴含离散拉普拉斯非正
   环境 : Lean 4 + mathlib
   日期 : 2024
  ==========================================================================

  本文件证明: 在3x3窗口中,若中心元为四邻域局部极大值,则其离散拉普拉斯算子(5点格式)非正.

  离散拉普拉斯算子定义为: (b + d + f + h) - 4*e, 其中e为中心, b,d,f,h为四邻域(上,左,右,下).

  注意: 此定义对应于正方形网格,但结论的符号不依赖于网格间距(因分母为正).
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.LocalMaxLaplacian

noncomputable section

/-!
  ## 3×3 窗口约定(行偏移 q 向下为正,符合栅格惯例)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 的离散拉普拉斯算子使用四正交邻域(b,d,f,h)
-/

variable {a b c d e f g h i : ℝ}

/-- 离散拉普拉斯算子(5点格式)的分子部分 -/
def laplacian_num : ℝ := (b + d + f + h) - 4 * e

/--
  若中心元 e 是其四正交邻域(b,d,f,h)的局部极大值,
  则离散拉普拉斯算子分子部分 ≤ 0
-/
theorem local_max_imp_laplacian_nonpos
    (h_b : e ≥ b) (h_d : e ≥ d) (h_f : e ≥ f) (h_h : e ≥ h) :
    laplacian_num ≤ 0 := by
  -- 展开拉普拉斯算子定义
  unfold laplacian_num
  -- 将结论转化为 4*e ≥ b+d+f+h
  rw [sub_nonpos]
  -- 组合四个不等式: e≥b, e≥d, e≥f, e≥h
  have h_sum : b + d + f + h ≤ e + e + e + e := by
    repeat apply add_le_add <;> assumption
  -- 化简右侧为 4*e
  rw [show e + e + e + e = 4 * e by ring] at h_sum
  exact h_sum

end -- noncomputable section

end VeriGIS.LocalMaxLaplacian
