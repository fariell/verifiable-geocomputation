/-
  ==========================================================================
   GeoProofBench · P-019
   文件 : formal/lean4/VeriGIS/HornSlopeNonneg.lean
   算子 : Horn (1981) 有限差分坡度平方
   对偶 : formal/dafny/P019_slope_nonnegative.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  命题：对于任意3×3高程窗口和正网格间距w，Horn坡度平方SlopeSq非负。
  此性质对任意高程值成立，不仅限于平面表面。

  覆盖：
    GPB-001 的推论：坡度平方在任意高程下非负
    与GPB-020（剖面曲率）形成对比：曲率可能为负，但坡度平方始终≥0
    噪声鲁棒性：即使有噪声，坡度平方仍保持非负
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

namespace VeriGIS.HornSlopeNonneg

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下)，与 `HornSlope` / Dafny P-001 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)
-/

/-- Horn (1981) 有限差分坡度平方算子 -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ :=
  let dzdx := (c + 2 * f + i - (a + 2 * d + g)) / (8 * w)
  let dzdy := (g + 2 * h + i - (a + 2 * b + c)) / (8 * w)
  dzdx ^ 2 + dzdy ^ 2

/-- 主定理：对于任意高程和正网格间距，坡度平方非负 -/
theorem slopeSq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) :
    0 ≤ slopeSq a b c d e f g h i w := by
  unfold slopeSq
  have h8w_pos : 0 < 8 * w := by linarith
  have h8w_ne_zero : 8 * w ≠ 0 := by linarith
  have hdzdx_sq_nonneg : 0 ≤ ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 :=
    pow_two_nonneg _
  have hdzdy_sq_nonneg : 0 ≤ ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 :=
    pow_two_nonneg _
  linarith

/-- 更强的版本：坡度平方是平方和，因此自动非负 -/
theorem slopeSq_eq_sum_squares (a b c d e f g h i w : ℝ) (hw : w ≠ 0) :
    slopeSq a b c d e f g h i w =
      ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 +
      ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 :=
  rfl

/-- 零坡度条件：当且仅当两个差分都为零时坡度平方为零 -/
theorem slopeSq_eq_zero_iff (a b c d e f g h i w : ℝ) (hw : w > 0) :
    slopeSq a b c d e f g h i w = 0 ↔
      c + 2 * f + i = a + 2 * d + g ∧
      g + 2 * h + i = a + 2 * b + c := by
  constructor
  · intro h
    unfold slopeSq at h
    have h1 : ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 = 0 := by
      have : 0 ≤ ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 := pow_two_nonneg _
      have : 0 ≤ ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 := pow_two_nonneg _
      linarith
    have h2 : ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 = 0 := by
      have : 0 ≤ ((c + 2 * f + i - (a + 2 * d + g)) / (8 * w)) ^ 2 := pow_two_nonneg _
      have : 0 ≤ ((g + 2 * h + i - (a + 2 * b + c)) / (8 * w)) ^ 2 := pow_two_nonneg _
      linarith
    have h8w_ne_zero : 8 * w ≠ 0 := by linarith
    constructor
    · have : (c + 2 * f + i - (a + 2 * d + g)) / (8 * w) = 0 :=
        pow_eq_zero h1
      field_simp [h8w_ne_zero] at this
      linarith
    · have : (g + 2 * h + i - (a + 2 * b + c)) / (8 * w) = 0 :=
        pow_eq_zero h2
      field_simp [h8w_ne_zero] at this
      linarith
  · rintro ⟨h1, h2⟩
    unfold slopeSq
    have h8w_ne_zero : 8 * w ≠ 0 := by linarith
    have hdiff1 : c + 2 * f + i - (a + 2 * d + g) = 0 := by linarith
    have hdiff2 : g + 2 * h + i - (a + 2 * b + c) = 0 := by linarith
    simp [hdiff1, hdiff2, h8w_ne_zero]

/-- 平移不变性：所有高程加上常数K，坡度平方不变 -/
theorem slopeSq_translation_invariant (a b c d e f g h i w K : ℝ) :
    slopeSq (a + K) (b + K) (c + K) (d + K) (e + K) (f + K) (g + K) (h + K) (i + K) w =
    slopeSq a b c d e f g h i w := by
  unfold slopeSq
  ring_nf

/-- 缩放不变性：网格间距w缩放，坡度平方按1/w²缩放 -/
theorem slopeSq_scaling (a b c d e f g h i w α : ℝ) (hα : α ≠ 0) :
    slopeSq a b c d e f g h i (α * w) = (1 / α ^ 2) * slopeSq a b c d e f g h i w := by
  unfold slopeSq
  field_simp [hα]
  ring

/-- 与平面表面的关系：在平面上，坡度平方等于解析坡度的平方 -/
theorem slopeSq_on_plane (A B C D E F w : ℝ) (hw : w > 0) :
    let z p q : ℝ := A * (p * w) + B * (q * w) + C * (p * w) * (q * w) + D * (p * w) + E * (q * w) + F
    slopeSq (z (-1) (-1)) (z 0 (-1)) (z 1 (-1))
            (z (-1) 0) (z 0 0) (z 1 0)
            (z (-1) 1) (z 0 1) (z 1 1) w = (A + C * w) ^ 2 + (B + C * w) ^ 2 := by
  intro z
  unfold slopeSq z
  field_simp [show w ≠ 0 from by linarith]
  ring

/-- 噪声鲁棒性：即使添加任意噪声，坡度平方仍非负 -/
theorem slopeSq_with_noise_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0)
    (δa δb δc δd δe δf δg δh δi : ℝ) :
    0 ≤ slopeSq (a + δa) (b + δb) (c + δc) (d + δd) (e + δe) (f + δf) (g + δg) (h + δh) (i + δi) w :=
  slopeSq_nonneg (a + δa) (b + δb) (c + δc) (d + δd) (e + δe) (f + δf) (g + δg) (h + δh) (i + δi) w hw

end
end VeriGIS.HornSlopeNonneg
