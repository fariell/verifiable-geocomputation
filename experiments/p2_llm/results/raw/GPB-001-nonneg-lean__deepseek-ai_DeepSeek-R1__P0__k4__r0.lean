import Mathlib.Data.Real.Basic

/-!
### Horn Slope-Square Nonnegativity Proof

For any 3×3 elevation window and positive grid spacing `w`, 
the Horn slope-square (SlopeSq) is nonnegative. This holds 
for arbitrary elevation values, not just planar surfaces.

The Horn (1981) finite-difference method defines:
- `dz/dx ≈ (c + 2f + i - a - 2d - g) / (8w)`
- `dz/dy ≈ (g + 2h + i - a - 2b - c) / (8w)`
- SlopeSq = (dz/dx)^2 + (dz/dy)^2

Since SlopeSq is a sum of squares, it must be ≥0.
-/

theorem horn_slope_sq_nonneg 
  (a b c d e f g h i w : ℝ)  -- Elevations a..i, spacing w
  (hw : w > 0) :              -- Grid spacing positive
  let dzdx := (c + 2*f + i - a - 2*d - g) / (8 * w);
  let dzdy := (g + 2*h + i - a - 2*b - c) / (8 * w);
  dzdx^2 + dzdy^2 ≥ 0 := by
  -- Define intermediate derivatives
  intro dzdx dzdy
  -- Sum of squares is nonnegative
  apply add_nonneg
  · apply pow_two_nonneg  -- (dzdx)^2 ≥ 0
  · apply pow_two_nonneg  -- (dzdy)^2 ≥ 0
