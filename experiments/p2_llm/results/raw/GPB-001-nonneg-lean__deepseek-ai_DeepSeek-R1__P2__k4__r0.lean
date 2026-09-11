import Mathlib.Data.Real.Basic

def horn_dx (a b c d e f g h i w : ℝ) : ℝ :=
  ((c + 2*f + i) - (a + 2*d + g)) / (8 * w)

def horn_dy (a b c d e f g h i w : ℝ) : ℝ :=
  ((g + 2*h + i) - (a + 2*b + c)) / (8 * w)

def slope_sq (a b c d e f g h i w : ℝ) : ℝ :=
  (horn_dx a b c d e f g h i w)^2 + (horn_dy a b c d e f g h i w)^2

theorem slope_sq_nonneg (a b c d e f g h i w : ℝ) (h : w > 0) : 
  slope_sq a b c d e f g h i w ≥ 0 := by
  unfold slope_sq
  apply add_nonneg
  · apply pow_two_nonneg
  · apply pow_two_nonneg
