import Mathlib.Data.Real.Basic

def horn_slope_sq (a b c d e f g h i w : ℝ) : ℝ :=
  let dx := (c + 2*f + i - (a + 2*d + g)) / (8*w)
  let dy := (g + 2*h + i - (a + 2*b + c)) / (8*w)
  dx^2 + dy^2

theorem horn_slope_sq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) :
  horn_slope_sq a b c d e f g h i w ≥ 0 := by
  unfold horn_slope_sq
  apply add_nonneg <;> apply pow_two_nonneg
