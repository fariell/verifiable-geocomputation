import Mathlib.Tactic

namespace HornSlope

noncomputable section

/-!
  Horn (1981) finite-difference slope operator for 3×3 windows:

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  Slope components defined per Horn's equations:
    dz/dx ≈ ( (c + 2*f + i) - (a + 2*d + g) ) / (8*w)
    dz/dy ≈ ( (g + 2*h + i) - (a + 2*b + c) ) / (8*w)
-/

def horn_dzdx (a b c d e f g h i w : ℝ) : ℝ := 
  (c + 2 * f + i - (a + 2 * d + g)) / (8 * w)

def horn_dzdy (a b c d e f g h i w : ℝ) : ℝ := 
  (g + 2 * h + i - (a + 2 * b + c)) / (8 * w)

def horn_slopeSq (a b c d e f g h i w : ℝ) : ℝ := 
  (horn_dzdx a b c d e f g h i w)^2 + (horn_dzdy a b c d e f g h i w)^2

/-!
  Theorem: For any 3×3 elevation window and positive grid spacing w, 
  the Horn slope-square is nonnegative. Holds universally for all real 
  elevations, not just planar surfaces.
-/
theorem horn_slopeSq_nonneg (a b c d e f g h i w : ℝ) (hw : w ≠ 0) :
    0 ≤ horn_slopeSq a b c d e f g h i w := by
  unfold horn_slopeSq
  apply add_nonneg
  · apply pow_two_nonneg  -- (dz/dx)^2 ≥ 0
  · apply pow_two_nonneg  -- (dz/dy)^2 ≥ 0

end
end HornSlope
