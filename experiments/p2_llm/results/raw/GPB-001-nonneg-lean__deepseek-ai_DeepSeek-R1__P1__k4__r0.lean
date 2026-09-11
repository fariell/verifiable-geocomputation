import Mathlib.Tactic

namespace VeriGIS.Slope

noncomputable section

/-!
  Horn (1981) finite-difference slope operator for 3×3 window:

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  Slope components defined as:
    dz/dx ≈ ( (c + 2*f + i) - (a + 2*d + g) ) / (8 * w)
    dz/dy ≈ ( (g + 2*h + i) - (a + 2*b + c) ) / (8 * w)
-/

def horn_dzdx (a b c d e f g h i w : ℝ) : ℝ := 
  (c + 2*f + i - (a + 2*d + g)) / (8 * w)

def horn_dzdy (a b c d e f g h i w : ℝ) : ℝ := 
  (g + 2*h + i - (a + 2*b + c)) / (8 * w)

def horn_slope_sq (a b c d e f g h i w : ℝ) : ℝ := 
  (horn_dzdx a b c d e f g h i w)^2 + (horn_dzdy a b c d e f g h i w)^2

/-!
  ==========================================================================
   GeoProofBench · P-019
   Horn slope-square nonnegativity for arbitrary elevations
  ==========================================================================

  Theorem: For any real-valued 3×3 elevation window (a,...,i) and positive 
  grid spacing w > 0, the Horn slope-square is nonnegative.

  Proof: The slope-square is sum of two real squares. Squares are always ≥0, 
  and sum of nonnegative terms is nonnegative. The w>0 precondition ensures 
  division is well-defined but doesn't affect nonnegativity.
  ==========================================================================
-/

theorem horn_slope_sq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) : 
    0 ≤ horn_slope_sq a b c d e f g h i w := by
  unfold horn_slope_sq
  apply add_nonneg
  · apply pow_two_nonneg  -- (dzdx)^2 ≥ 0
  · apply pow_two_nonneg  -- (dzdy)^2 ≥ 0

end
end VeriGIS.Slope
