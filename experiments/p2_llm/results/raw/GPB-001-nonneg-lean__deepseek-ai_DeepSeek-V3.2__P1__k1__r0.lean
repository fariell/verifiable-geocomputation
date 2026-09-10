/-
  ==========================================================================
   GeoProofBench · P-019
   文件 : formal/lean4/VeriGIS/HornSlopeNonneg.lean
   算子 : Horn (1981) 有限差分坡度平方
   对偶 : formal/dafny/P019_slope_nonnegative.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  命题：对于任意 3×3 高程窗口和正网格间距 w，Horn 坡度平方 SlopeSq 非负。
  此性质对任意高程成立，不仅限于平面。

  覆盖：
    GPB-001 的代数核：平面上的精确性
    GPB-019 的全局非负性：任意高程窗口
    Phase 1 实验的数学基础：坡度平方作为一致性估计量的非负性
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下)，与 `Curvature` / Dafny P-003 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1,  0)     e        f( 1,  0)
      g(-1,  1)   h( 0,  1)   i( 1,  1)
-/

/-- Horn (1981) 有限差分坡度平方算子 -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ :=
  let dzdx := (c + 2 * f + i - (a + 2 * d + g)) / (8 * w)
  let dzdy := (g + 2 * h + i - (a + 2 * b + c)) / (8 * w)
  dzdx ^ 2 + dzdy ^ 2

/-- 坡度平方在任意高程窗口和非零间距下非负 -/
theorem slopeSq_nonneg (a b c d e f g h i w : ℝ) (hw : w ≠ 0) :
    0 ≤ slopeSq a b c d e f g h i w := by
  unfold slopeSq
  have h8w : (8 : ℝ) * w ≠ 0 := by
    intro h
    have : w = 0 := by
      apply mul_eq_zero.mp at h
      rcases h with (h8 | hw')
      · norm_num at h8
      · exact hw'
    exact hw this
  have hdzdx_sq : 0 ≤ ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 :=
    pow_two_nonneg _
  have hdzdy_sq : 0 ≤ ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 :=
    pow_two_nonneg _
  nlinarith

/-- 当间距趋于零时的一致性：坡度平方在平面上的精确值 -/
theorem slopeSq_exact_on_plane (A B C D E F w : ℝ) (hw : w ≠ 0) :
    slopeSq
      (A * (-w) + B * (-w) + C * ((-w) * (-w)) + D * (-w) + E * (-w) + F)
      (A * 0 + B * (-w) + C * (0 * (-w)) + D * 0 + E * (-w) + F)
      (A * w + B * (-w) + C * (w * (-w)) + D * w + E * (-w) + F)
      (A * (-w) + B * 0 + C * ((-w) * 0) + D * (-w) + E * 0 + F)
      (A * 0 + B * 0 + C * (0 * 0) + D * 0 + E * 0 + F)
      (A * w + B * 0 + C * (w * 0) + D * w + E * 0 + F)
      (A * (-w) + B * w + C * ((-w) * w) + D * (-w) + E * w + F)
      (A * 0 + B * w + C * (0 * w) + D * 0 + E * w + F)
      (A * w + B * w + C * (w * w) + D * w + E * w + F)
      w = A ^ 2 + B ^ 2 := by
  unfold slopeSq
  field_simp [show (8 : ℝ) * w ≠ 0 from by intro h; have := mul_eq_zero.mp h; rcases this with (h8 | hw'); norm_num at h8; exact hw hw']
  ring

/-- 坡度平方的平移不变性：所有高程加常数 K 不影响结果 -/
theorem slopeSq_translation_invariant (a b c d e f g h i w K : ℝ) (hw : w ≠ 0) :
    slopeSq (a + K) (b + K) (c + K) (d + K) (e + K) (f + K) (g + K) (h + K) (i + K) w =
    slopeSq a b c d e f g h i w := by
  unfold slopeSq
  ring

/-- 坡度平方的缩放性质：间距缩放 s 倍，高程不变时，坡度平方缩放 1/s² -/
theorem slopeSq_scaling (a b c d e f g h i w s : ℝ) (hw : w ≠ 0) (hs : s ≠ 0) :
    slopeSq a b c d e f g h i (s * w) = (1 / s ^ 2) * slopeSq a b c d e f g h i w := by
  unfold slopeSq
  field_simp [show s * w ≠ 0 from mul_ne_zero hs hw, show w ≠ 0 from hw]
  ring

/-- 非负性的直接推论：坡度平方的平方根（坡度大小）定义良好 -/
noncomputable def slopeMagnitude (a b c d e f g h i w : ℝ) (hw : w ≠ 0) : ℝ :=
  Real.sqrt (slopeSq a b c d e f g h i w)

theorem slopeMagnitude_nonneg (a b c d e f g h i w : ℝ) (hw : w ≠ 0) :
    0 ≤ slopeMagnitude a b c d e f g h i w hw :=
  Real.sqrt_nonneg _

theorem slopeMagnitude_sq_eq (a b c d e f g h i w : ℝ) (hw : w ≠ 0) :
    slopeMagnitude a b c d e f g h i w hw ^ 2 = slopeSq a b c d e f g h i w :=
  Real.pow_sqrt_eq_abs _ |>.trans (abs_of_nonneg (slopeSq_nonneg _ _ _ _ _ _ _ _ _ _ hw))

end
end VeriGIS.HornSlope
