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
    Horn (1981) 有限差分公式的符号确定性
    网格间距w > 0 的假设
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下)，与 `HornSlope` / Dafny P-001 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)
-/

/-- Horn (1981) 有限差分坡度公式的x方向分量 -/
def dzdx (a b c d e f g h i w : ℝ) : ℝ :=
  ((c + 2 * f + i) - (a + 2 * d + g)) / (8 * w)

/-- Horn (1981) 有限差分坡度公式的y方向分量 -/
def dzdy (a b c d e f g h i w : ℝ) : ℝ :=
  ((g + 2 * h + i) - (a + 2 * b + c)) / (8 * w)

/-- Horn 坡度平方 = (dz/dx)² + (dz/dy)² -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ :=
  (dzdx a b c d e f g h i w) ^ 2 + (dzdy a b c d e f g h i w) ^ 2

/-- 辅助引理：分母非零 -/
lemma eight_w_ne_zero {w : ℝ} (hw : w > 0) : 8 * w ≠ 0 := by
  linarith [show (0:ℝ) < 8 from by norm_num, hw]

/-- 主要定理：对于任意高程值和正网格间距，Horn坡度平方非负 -/
theorem horn_slope_sq_nonneg
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    0 ≤ slopeSq a b c d e f g h i w := by
  -- 展开定义
  unfold slopeSq dzdx dzdy
  -- 坡度平方是两个实数的平方和，总是非负的
  have h1 : 0 ≤ (((c + 2 * f + i) - (a + 2 * d + g)) / (8 * w)) ^ 2 :=
    pow_two_nonneg _
  have h2 : 0 ≤ (((g + 2 * h + i) - (a + 2 * b + c)) / (8 * w)) ^ 2 :=
    pow_two_nonneg _
  -- 两个非负数的和仍然非负
  nlinarith

/-- 更强的形式：坡度平方是平方和，因此非负性直接来自平方的非负性 -/
theorem horn_slope_sq_nonneg_alt
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    slopeSq a b c d e f g h i w ≥ 0 :=
  horn_slope_sq_nonneg a b c d e f g h i w hw

/-- 当且仅当两个坡度分量都为零时，坡度平方为零 -/
theorem horn_slope_sq_eq_zero_iff
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    slopeSq a b c d e f g h i w = 0 ↔
      dzdx a b c d e f g h i w = 0 ∧ dzdy a b c d e f g h i w = 0 := by
  constructor
  · intro h
    unfold slopeSq at h
    have hx : dzdx a b c d e f g h i w = 0 := by
      unfold dzdx
      have : (dzdx a b c d e f g h i w) ^ 2 = 0 := by
        linarith [show (dzdy a b c d e f g h i w) ^ 2 ≥ 0 from pow_two_nonneg _]
      exact pow_eq_zero this
    have hy : dzdy a b c d e f g h i w = 0 := by
      unfold dzdy
      have : (dzdy a b c d e f g h i w) ^ 2 = 0 := by
        linarith [show (dzdx a b c d e f g h i w) ^ 2 ≥ 0 from pow_two_nonneg _]
      exact pow_eq_zero this
    exact ⟨hx, hy⟩
  · intro ⟨hx, hy⟩
    unfold slopeSq
    rw [hx, hy]
    norm_num

/-- 坡度平方在任意高程平移下不变 -/
theorem slope_sq_translation_invariant
    (a b c d e f g h i w K : ℝ) (hw : w > 0) :
    slopeSq (a + K) (b + K) (c + K) (d + K) (e + K) (f + K) (g + K) (h + K) (i + K) w
    = slopeSq a b c d e f g h i w := by
  unfold slopeSq dzdx dzdy
  ring_nf

/-- 坡度平方在缩放下具有齐次性：w → λw 时，坡度平方按 1/λ² 缩放 -/
theorem slope_sq_scaling
    (a b c d e f g h i w λ : ℝ) (hw : w > 0) (hλ : λ > 0) :
    slopeSq a b c d e f g h i (λ * w) = (1 / λ ^ 2) * slopeSq a b c d e f g h i w := by
  unfold slopeSq dzdx dzdy
  field_simp [ne_of_gt hλ, ne_of_gt hw]
  ring

end

end VeriGIS.HornSlope
