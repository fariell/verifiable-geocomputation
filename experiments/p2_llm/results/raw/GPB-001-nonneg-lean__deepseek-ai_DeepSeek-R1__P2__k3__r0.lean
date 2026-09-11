import Mathlib.Data.Real.Basic

theorem horn_slope_sq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) :
  let dzdx := (c + 2*f + i) - (a + 2*d + g)
  let dzdy := (g + 2*h + i) - (a + 2*b + c)
  0 ≤ (dzdx^2 + dzdy^2) / (64 * w^2) := by
  intro dzdx dzdy
  apply div_nonneg
  · apply add_nonneg
    · apply pow_two_nonneg
    · apply pow_two_nonneg
  · positivity
