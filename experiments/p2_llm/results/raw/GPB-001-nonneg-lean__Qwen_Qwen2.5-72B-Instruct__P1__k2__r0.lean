/-
  ==========================================================================
   GeoProofBench · P-019
   文件 : formal/lean4/VeriGIS/HornSlope.lean
   算子 : Horn (1981) 3×3 Slope
   对偶 : formal/dafny/P001_horn_slope.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  独立重述,不是翻译。本文件证明 Horn (1981) 有限差分坡度算子在任意 3x3 高程窗口
  和正网格间距 w 下是非负的。这适用于任意高程，而不仅仅是平面。

  覆盖:
    GPB-019  Horn 坡度平方非负
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下),与 `HornSlope` / Dafny P-001 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1,  0)     e        f( 1,  0)
      g(-1,  1)   h( 0,  1)   i( 1,  1)
-/

def dzdx (a d e f : ℝ) (w : ℝ) : ℝ := (f - d) / (2 * w)
def dzdy (b e h : ℝ) (w : ℝ) : ℝ := (h - b) / (2 * w)

def slopeSq (a b c d e f g h i : ℝ) (w : ℝ) : ℝ :=
  (dzdx a d e f w) ^ 2 + (dzdy b e h w) ^ 2

lemma sq_ne_zero {w : ℝ} (hw : w ≠ 0) : w ^ 2 ≠ 0 :=
  pow_ne_zero 2 hw

lemma two_sq_ne_zero {w : ℝ} (hw : w ≠ 0) : (2 * w) ^ 2 ≠ 0 := by
  rw [sq, mul_ne_zero]
  exact two_ne_zero
  exact hw

theorem slopeSq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) :
    slopeSq a b c d e f g h i w ≥ 0 := by
  have h2w : (2 * w) ≠ 0 := by
    rw [mul_ne_zero]
    exact two_ne_zero
    exact (ne_of_gt hw)
  have h2w2 : (0 : ℝ) < (2 * w) ^ 2 := by
    rw [sq_pos_iff]
    exact (ne_of_gt hw)
  unfold slopeSq dzdx dzdy
  rw [sq, sq, add_div, div_nonneg]
  exact (add_nonneg (sq_nonneg _) (sq_nonneg _))
  exact (mul_pos (two_ne_zero) (two_ne_zero))
  exact (pow_pos (ne_of_gt hw) 2)

end
end VeriGIS.HornSlope
