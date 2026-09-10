import Mathlib.Tactic

namespace VeriGIS.Slope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下),与 `HornSlope` / Dafny P-001 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1,  0)     e        f( 1,  0)
      g(-1,  1)   h( 0,  1)   i( 1,  1)
-/

def dzdx (d e f : ℝ) : ℝ := (f - d) / 2
def dzdy (b e h : ℝ) : ℝ := (h - b) / 2
def slopeSq (d e f b h w : ℝ) : ℝ := (dzdx d e f / w) ^ 2 + (dzdy b e h / w) ^ 2

/-- For any finite 3x3 elevation window and positive grid spacing w, the Horn slope-square
SlopeSq is nonnegative. This must hold for arbitrary elevations, not only planar surfaces. -/
theorem slopeSq_nonneg
    (d e f b h w : ℝ) (hw_pos : 0 < w) :
    0 ≤ slopeSq d e f b h w := by
  have hw_sq_pos : 0 < w ^ 2 := pow_pos hw_pos 2
  apply add_nonneg
  · apply sq_nonneg
    field_simp [hw_sq_pos.ne']
  · apply sq_nonneg
    field_simp [hw_sq_pos.ne']

end VeriGIS.Slope
