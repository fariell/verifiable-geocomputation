import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Fin.VecNotation

open Matrix

/-- Horn's slope-square formula for a 3x3 window with spacing w.
    Given elevations z00..z22 and spacing w > 0, returns a nonnegative value. -/
def hornSlopeSq (z : Matrix (Fin 3) (Fin 3) ℝ) (w : ℝ) : ℝ :=
  let dx := ((z 0 2 + z 1 2 + z 2 2) - (z 0 0 + z 1 0 + z 2 0)) / (6 * w)
  let dy := ((z 2 0 + z 2 1 + z 2 2) - (z 0 0 + z 0 1 + z 0 2)) / (6 * w)
  dx ^ 2 + dy ^ 2

theorem hornSlopeSq_nonneg (z : Matrix (Fin 3) (Fin 3) ℝ) (w : ℝ) (hw : w > 0) :
    hornSlopeSq z w ≥ 0 := by
  unfold hornSlopeSq
  have h1 : 0 ≤ ((z 0 2 + z 1 2 + z 2 2) - (z 0 0 + z 1 0 + z 2 0)) / (6 * w) ^ 2 := by
    apply div_nonneg
    · exact sub_nonneg.mp ?_  -- This line is problematic: sub_nonneg requires a ≤ b, which we don't have.
    · exact pow_nonneg (by linarith [hw]) 2
  sorry

-- The above attempt fails because the numerator can be negative.
-- We need to realize that the square of any real is nonnegative, regardless of sign.

theorem hornSlopeSq_nonneg_corrected (z : Matrix (Fin 3) (Fin 3) ℝ) (w : ℝ) (hw : w > 0) :
    hornSlopeSq z w ≥ 0 := by
  unfold hornSlopeSq
  have hdx : 0 ≤ (((z 0 2 + z 1 2 + z 2 2) - (z 0 0 + z 1 0 + z 2 0)) / (6 * w)) ^ 2 :=
    pow_two_nonneg _
  have hdy : 0 ≤ (((z 2 0 + z 2 1 + z 2 2) - (z 0 0 + z 0 1 + z 0 2)) / (6 * w)) ^ 2 :=
    pow_two_nonneg _
  linarith
