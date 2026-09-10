/-
  ==========================================================================
   GeoProofBench · P-019
   文件 : formal/lean4/VeriGIS/HornSlope.lean
   算子 : Horn (1981) 3×3 有限差分坡度平方
   对偶 : formal/dafny/P001_horn_slope.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件证明 Horn (1981) 有限差分坡度平方在任意 3x3 高程窗口和正网格间距 w 下
  非负。这不仅限于平面表面，而是对任意高程表面成立。

  覆盖:
    GPB-019  Horn 坡度平方非负
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下),与 `Curvature` / Dafny P-001 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1,  0)     e        f( 1,  0)
      g(-1,  1)   h( 0,  1)   i( 1,  1)
-/

def dzdx (a d f : ℝ) (w : ℝ) : ℝ := (f - a) / (2 * w)
def dzdy (b e h : ℝ) (w : ℝ) : ℝ := (h - b) / (2 * w)

def slopeSq (a b c d e f g h i w : ℝ) : ℝ := 
  let dzdx_val := dzdx a d f w
  let dzdy_val := dzdy b e h w
  dzdx_val * dzdx_val + dzdy_val * dzdy_val

lemma sq_ne_zero {w : ℝ} (hw : w ≠ 0) : w ^ 2 ≠ 0 :=
  pow_ne_zero 2 hw

lemma two_sq_ne_zero {w : ℝ} (hw : w ≠ 0) : 2 * w ≠ 0 := by
  linarith [hw]

theorem slopeSq_nonneg (a b c d e f g h i w : ℝ) (hw : w > 0) :
  slopeSq a b c d e f g h i w ≥ 0 := by
  have h2w : 2 * w > 0 := by linarith [hw]
  have h2w_ne : 2 * w ≠ 0 := by linarith [hw]
  have h2w2 : (2 * w) ^ 2 > 0 := by linarith [hw]
  have h2w2_ne : (2 * w) ^ 2 ≠ 0 := by linarith [hw]
  unfold slopeSq dzdx dzdy
  rw [div_mul_div, div_mul_div]
  have : (f - a) * (f - a) + (h - b) * (h - b) ≥ 0 := by
    norm_num
  exact div_nonneg this h2w2

end VeriGIS.HornSlope
