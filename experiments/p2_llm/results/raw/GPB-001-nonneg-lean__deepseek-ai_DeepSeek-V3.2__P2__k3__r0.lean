import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

/-- Horn's slope-square formula for a 3x3 window with grid spacing w.
    Given elevations z00..z22 (center at z11) and spacing w > 0,
    SlopeSq = ((z20 + 2*z10 + z00) - (z22 + 2*z12 + z02))^2 / (16*w^2)
            + ((z02 + 2*z01 + z00) - (z22 + 2*z21 + z20))^2 / (16*w^2) -/
def SlopeSq (z : Matrix (Fin 3) (Fin 3) ℝ) (w : ℝ) : ℝ :=
  let num1 := (z 2 0 + 2 * z 1 0 + z 0 0) - (z 2 2 + 2 * z 1 2 + z 0 2)
  let num2 := (z 0 2 + 2 * z 0 1 + z 0 0) - (z 2 2 + 2 * z 2 1 + z 2 0)
  (num1^2 + num2^2) / (16 * w^2)

theorem horn_slope_nonneg (z : Matrix (Fin 3) (Fin 3) ℝ) (w : ℝ) (hw : w > 0) :
    SlopeSq z w ≥ 0 := by
  unfold SlopeSq
  have h16 : 0 < 16 * w^2 := by
    have : w^2 > 0 := pow_pos hw 2
    linarith
  have num1_sq_nonneg : 0 ≤ ((z 2 0 + 2 * z 1 0 + z 0 0) - (z 2 2 + 2 * z 1 2 + z 0 2))^2 :=
    pow_two_nonneg _
  have num2_sq_nonneg : 0 ≤ ((z 0 2 + 2 * z 0 1 + z 0 0) - (z 2 2 + 2 * z 2 1 + z 2 0))^2 :=
    pow_two_nonneg _
  have numerator_nonneg : 0 ≤ _ := by linarith
  exact div_nonneg numerator_nonneg (by linarith)
