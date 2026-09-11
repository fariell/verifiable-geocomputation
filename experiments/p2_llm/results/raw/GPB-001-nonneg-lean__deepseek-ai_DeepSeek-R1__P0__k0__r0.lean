import Mathlib.Data.Real.Basic

def horn_slope_sq (a b c d e f g h i w : ℝ) : ℝ :=
  let dzdx := ((c + 2*f + i) - (a + 2*d + g)) / (8*w)
  let dzdy := ((g + 2*h + i) - (a + 2*b + c)) / (8*w)
  dzdx^2 + dzdy^2

theorem horn_slope_sq_nonneg (a b c d e f g h i : ℝ) {w : ℝ} (hw : w > 0) :
  horn_slope_sq a b c d e f g h i w ≥ 0 := by
  unfold horn_slope_sq
  apply add_nonneg
  · apply pow_two_nonneg
  · apply pow_two_nonneg
