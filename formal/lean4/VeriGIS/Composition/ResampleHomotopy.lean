/-
  ==========================================================================
   GeoProofBench · P-COMP-4 resampling homotopy
   文件 : formal/lean4/VeriGIS/Composition/ResampleHomotopy.lean
   命题 : 平面经 R_α(改格网间距)后 Horn 斜率不变,D8 平移不变
   对偶 : formal/dafny/PCOMP_4_homotopy.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.HornSlope
import VeriGIS.Consistency
import VeriGIS.D8

namespace VeriGIS.Composition

noncomputable section

open VeriGIS.HornSlope VeriGIS.Consistency VeriGIS.D8

/-- 重采样:格网间距 w ↦ α w。 -/
def R (alpha w : ℝ) : ℝ := alpha * w

theorem homotopy_planar_dx (A B C w alpha : ℝ) (hw : w ≠ 0) (ha : alpha ≠ 0) :
    dzdx
      (qTL A B C 0 0 0 (R alpha w))
      (qTC A B C 0 0 0 (R alpha w))
      (qTR A B C 0 0 0 (R alpha w))
      (qML A B C 0 0 0 (R alpha w))
      (qMR A B C 0 0 0 (R alpha w))
      (qBL A B C 0 0 0 (R alpha w))
      (qBC A B C 0 0 0 (R alpha w))
      (qBR A B C 0 0 0 (R alpha w)) (R alpha w) = A := by
  have hαw : R alpha w ≠ 0 := mul_ne_zero ha hw
  simpa [R] using quadratic_exact_dx A B C 0 0 0 (R alpha w) hαw

theorem homotopy_d8_offset (A B C w : ℝ) :
    d8 (planeWin A B C w) = d8 (planeWin A B 0 w) :=
  plane_constant A B C w

theorem homotopy_west :
    d8 (planeWin 1 0 0 1) = Flow.to Dir.W :=
  example_plane_west

theorem homotopy_slope_nonneg
    (a b c d f g h i w alpha : ℝ) :
    0 ≤ slopeSq a b c d f g h i (R alpha w) :=
  slopeSq_nonneg a b c d f g h i (R alpha w)

end

end VeriGIS.Composition
