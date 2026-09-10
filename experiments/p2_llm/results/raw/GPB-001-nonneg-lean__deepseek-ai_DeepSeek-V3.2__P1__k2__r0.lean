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
  此性质对任意高程值成立，不仅限于平面表面。

  覆盖：
    GPB-001 的代数精确性（平面情形）
    GPB-019 的全局非负性（任意高程）
    Horn 坡度平方 = (dz/dx)² + (dz/dy)² 的有限差分近似
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下)，与 `Curvature` / Dafny P-003 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)
-/

/-- Horn (1981) 有限差分坡度平方算子 -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ :=
  let dzdx := (c + 2 * f + i - (a + 2 * d + g)) / (8 * w)
  let dzdy := (g + 2 * h + i - (a + 2 * b + c)) / (8 * w)
  dzdx ^ 2 + dzdy ^ 2

/-- 辅助引理：分母非零 -/
lemma eight_w_ne_zero {w : ℝ} (hw : w > 0) : 8 * w ≠ 0 := by
  linarith [show (0 : ℝ) < 8 from by norm_num, hw]

/-- 主要定理：Horn 坡度平方对任意高程值非负 -/
theorem horn_slope_sq_nonneg
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    0 ≤ slopeSq a b c d e f g h i w := by
  unfold slopeSq
  have hpos : 0 ≤ (c + 2 * f + i - (a + 2 * d + g)) ^ 2 := pow_two_nonneg _
  have hpos' : 0 ≤ (g + 2 * h + i - (a + 2 * b + c)) ^ 2 := pow_two_nonneg _
  have den_pos : 0 < (8 * w) ^ 2 := by
    have : 0 < 8 * w := by linarith
    exact pow_pos this 2
  have h1 : 0 ≤ ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 :=
    div_pow_nonneg (by linarith) (by linarith)
  have h2 : 0 ≤ ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 :=
    div_pow_nonneg (by linarith) (by linarith)
  nlinarith

/-- 平面表面的精确性：在平面 z = A·x + B·y + C 上，Horn 坡度平方等于 A² + B² -/
theorem horn_slope_sq_exact_on_plane
    (A B C w : ℝ) (hw : w > 0) :
    slopeSq
      (C - A * w - B * w)  -- a
      (C - B * w)          -- b
      (C + A * w - B * w)  -- c
      (C - A * w)          -- d
      C                    -- e
      (C + A * w)          -- f
      (C - A * w + B * w)  -- g
      (C + B * w)          -- h
      (C + A * w + B * w)  -- i
      w = A ^ 2 + B ^ 2 := by
  unfold slopeSq
  field_simp [eight_w_ne_zero hw]
  ring

/-- 非负性的直接推论：坡度平方的平方根（坡度大小）是实数 -/
theorem horn_slope_magnitude_real
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    Real.sqrt (slopeSq a b c d e f g h i w) ≥ 0 :=
  Real.sqrt_nonneg _

/-- 零坡度条件：当窗口完全平坦时，坡度平方为零 -/
theorem horn_slope_sq_zero_on_flat
    (z w : ℝ) (hw : w > 0) :
    slopeSq z z z z z z z z z w = 0 := by
  unfold slopeSq
  norm_num

/-- 对称性：坡度平方在旋转 90° 后不变 -/
theorem horn_slope_sq_rotate_90
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    slopeSq a b c d e f g h i w =
    slopeSq c f i b e h a d g w := by
  unfold slopeSq
  ring

end
end VeriGIS.HornSlope
