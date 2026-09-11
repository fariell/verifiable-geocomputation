import Mathlib.Tactic

namespace VeriGIS.Slope

noncomputable section

/-!
  Horn (1981) slope operator for 3×3 window:

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  Slope components defined per Horn's finite-difference scheme.
-/

/-- Horn slope in x-direction (dz/dx) -/
def horn_dzdx (a d g c f i w : ℝ) : ℝ := 
  ((c + 2*f + i) - (a + 2*d + g)) / (8 * w)

/-- Horn slope in y-direction (dz/dy) -/
def horn_dzdy (a b c g h i w : ℝ) : ℝ := 
  ((g + 2*h + i) - (a + 2*b + c)) / (8 * w)

/-- Squared slope magnitude (dz/dx)² + (dz/dy)² -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ := 
  (horn_dzdx a d g c f i w)^2 + (horn_dzdy a b c g h i w)^2

/-!
  ==========================================================================
   GeoProofBench · P-019
   算子 : Horn (1981) slope squared nonnegativity
   命题 : 任意 3×3 高程窗口下，Horn 坡度平方值非负
   环境 : Lean 4.18.0 + mathlib
  ==========================================================================

  核心性质：坡度平方作为实数的平方和必然非负。
  仅需 w > 0 保证分母非零（高程值任意有限实数）。
  ==========================================================================
-/

theorem horn_slopeSq_nonneg 
    (a b c d e f g h i w : ℝ) 
    (hw : w > 0) : 
    slopeSq a b c d e f g h i w ≥ 0 := by
  -- 展开 slopeSq 定义
  unfold slopeSq
  -- 平方和恒非负（无需高程约束）
  apply add_nonneg <;> apply pow_two_nonneg

end
end VeriGIS.Slope
