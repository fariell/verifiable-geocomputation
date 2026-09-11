import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic

theorem horn_slope_sq_nonneg (w : ℝ) (hw : w > 0) (z : Fin 3 → Fin 3 → ℝ) :
  let numx := (z 0 2 + 2 * z 1 2 + z 2 2) - (z 0 0 + 2 * z 1 0 + z 2 0)
  let numy := (z 2 0 + 2 * z 2 1 + z 2 2) - (z 0 0 + 2 * z 0 1 + z 0 2)
  let denom := 8 * w
  0 ≤ (numx / denom)^2 + (numy / denom)^2 := by
  let numx := (z 0 2 + 2 * z 1 2 + z 2 2) - (z 0 0 + 2 * z 1 0 + z 2 0)
  let numy := (z 2 0 + 2 * z 2 1 + z 2 2) - (z 0 0 + 2 * z 0 1 + z 0 2)
  let denom := 8 * w
  have denom_pos : 0 < denom := mul_pos (by norm_num) hw
  have h : (numx / denom)^2 + (numy / denom)^2 = (numx^2 + numy^2) / denom^2 := by
    field_simp; ring
  rw [h]
  apply div_nonneg
  · apply add_nonneg <;> apply pow_two_nonneg
  · exact le_of_lt (pow_pos denom_pos 2)
