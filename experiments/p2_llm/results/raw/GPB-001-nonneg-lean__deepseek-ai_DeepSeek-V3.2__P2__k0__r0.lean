import Mathlib

-- Define a 3x3 window of elevations as a 3×3 matrix of real numbers
abbrev Window := Matrix (Fin 3) (Fin 3) ℝ

-- Horn's slope-square formula for a 3x3 window with grid spacing w
-- Reference: Horn, B.K.P., "Hill Shading and the Reflectance Map", 1981.
-- The formula computes (dz/dx)^2 + (dz/dy)^2 using finite differences.
noncomputable def SlopeSq (E : Window) (w : ℝ) : ℝ :=
  let dx := ((E 0 2 + 2 * E 1 2 + E 2 2) - (E 0 0 + 2 * E 1 0 + E 2 0)) / (8 * w)
  let dy := ((E 2 0 + 2 * E 2 1 + E 2 2) - (E 0 0 + 2 * E 0 1 + E 0 2)) / (8 * w)
  dx ^ 2 + dy ^ 2

-- The theorem: for any 3x3 elevation window and positive grid spacing w,
-- the Horn slope-square is nonnegative.
theorem horn_slope_nonneg (E : Window) (w : ℝ) (hw : w > 0) : SlopeSq E w ≥ 0 := by
  unfold SlopeSq
  have h1 : ((E 0 2 + 2 * E 1 2 + E 2 2) - (E 0 0 + 2 * E 1 0 + E 2 0)) / (8 * w) ^ 2 ≥ 0 := by
    nlinarith? [div_nonneg_of_nonneg_of_pos (by nlinarith) (by nlinarith)]
  have h2 : ((E 2 0 + 2 * E 2 1 + E 2 2) - (E 0 0 + 2 * E 0 1 + E 0 2)) / (8 * w) ^ 2 ≥ 0 := by
    nlinarith? [div_nonneg_of_nonneg_of_pos (by nlinarith) (by nlinarith)]
  nlinarith [sq_nonneg _]
