import Mathlib.Tactic

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 window (p right, q down) - Horn (1981) slope operator.

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)
-/

/-- Horn slope in x-direction -/
def dzdx (a d g c f i w : ℝ) : ℝ := (c + 2*f + i - (a + 2*d + g)) / (8 * w)

/-- Horn slope in y-direction -/
def dzdy (a b c g h i w : ℝ) : ℝ := (g + 2*h + i - (a + 2*b + c)) / (8 * w)

/-- Squared slope magnitude -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ := 
  (dzdx a d g c f i w)^2 + (dzdy a b c g h i w)^2

/-!
  ==========================================================================
   GeoProofBench · P-019
   算子 : Horn (1981) slope magnitude squared
   命题 : 任意 3×3 窗口和正网格间距下，SlopeSq ≥ 0
   环境 : Lean 4.18.0 + mathlib
  ==========================================================================

  核心证明: 平方和结构保证非负性
  ==========================================================================
-/

theorem horn_slopeSq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) : 
    slopeSq a b c d e f g h i w ≥ 0 := by
  -- 展开定义
  unfold slopeSq dzdx dzdy
  -- 平方项自动非负
  apply add_nonneg
  · apply pow_two_nonneg  -- ∀ (r : ℝ), 0 ≤ r^2
  · apply pow_two_nonneg

end
end VeriGIS.HornSlope
```

This Lean formalization:
1. Defines the Horn (1981) slope operators `dzdx` and `dzdy` exactly as specified
2. Defines `slopeSq` as the sum of squared slopes
3. Proves the key theorem `horn_slopeSq_nonneg`:
   - For any 9 elevation values (a-i) 
   - With positive grid spacing `w > 0`
   - The squared slope magnitude is nonnegative
4. Proof leverages the mathematical property that squares are always nonnegative
5. Maintains the 3x3 window convention from the specification
6. Uses only essential imports matching the style guide
7. Includes documentation headers in the GeoProofBench format

The proof is concise because the nonnegativity follows directly from the sum-of-squares structure, requiring only:
- Unfolding definitions
- Applying the mathematical fact that squares are nonnegative (`pow_two_nonneg`)
- Using the additive property of nonnegativity (`add_nonneg`)
