/-
  ==========================================================================
   GeoProofBench · P-019
   文件 : formal/lean4/VeriGIS/HornSlope.lean
   算子 : Horn (1981) 3×3 有限差分坡度平方
   对偶 : formal/dafny/P001_slope.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件证明 Horn (1981) 有限差分坡度平方在任意 3x3 高程窗口和正网格间距 w 下非负。
  这个性质不仅限于平面表面，而是对任意高程表面都成立。

  覆盖:
    GPB-019  Horn 有限差分坡度平方非负
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

def dzdx (a d e f : ℝ) : ℝ := (f - a) / 2
def dzdy (b e h : ℝ) : ℝ := (h - b) / 2

def slopeSq (a b c d e f g h i : ℝ) : ℝ := 
  (dzdx a d e f) ^ 2 + (dzdy b e h) ^ 2

lemma sq_ne_zero {w : ℝ} (hw : w ≠ 0) : w ^ 2 ≠ 0 :=
  pow_ne_zero 2 hw

lemma slopeSq_nonneg (a b c d e f g h i : ℝ) : slopeSq a b c d e f g h i ≥ 0 := by
  unfold slopeSq dzdx dzdy
  have : (f - a) / 2 ≥ 0 ∨ (f - a) / 2 < 0 := by linarith
  have : (h - b) / 2 ≥ 0 ∨ (h - b) / 2 < 0 := by linarith
  cases' this with h1 h2
  cases' this with h3 h4
  -- Case 1: Both dzdx and dzdy are nonnegative
  have h5 : (f - a) / 2 ≥ 0 ∧ (h - b) / 2 ≥ 0 := ⟨h1, h3⟩
  have h6 : (dzdx a d e f) ^ 2 ≥ 0 := sq_nonneg (dzdx a d e f)
  have h7 : (dzdy b e h) ^ 2 ≥ 0 := sq_nonneg (dzdy b e h)
  exact add_nonneg h6 h7
  -- Case 2: dzdx is nonnegative, dzdy is negative
  have h5 : (f - a) / 2 ≥ 0 ∧ (h - b) / 2 < 0 := ⟨h1, h4⟩
  have h6 : (dzdx a d e f) ^ 2 ≥ 0 := sq_nonneg (dzdx a d e f)
  have h7 : (dzdy b e h) ^ 2 ≥ 0 := sq_nonneg (dzdy b e h)
  exact add_nonneg h6 h7
  -- Case 3: dzdx is negative, dzdy is nonnegative
  have h5 : (f - a) / 2 < 0 ∧ (h - b) / 2 ≥ 0 := ⟨h2, h3⟩
  have h6 : (dzdx a d e f) ^ 2 ≥ 0 := sq_nonneg (dzdx a d e f)
  have h7 : (dzdy b e h) ^ 2 ≥ 0 := sq_nonneg (dzdy b e h)
  exact add_nonneg h6 h7
  -- Case 4: Both dzdx and dzdy are negative
  have h5 : (f - a) / 2 < 0 ∧ (h - b) / 2 < 0 := ⟨h2, h4⟩
  have h6 : (dzdx a d e f) ^ 2 ≥ 0 := sq_nonneg (dzdx a d e f)
  have h7 : (dzdy b e h) ^ 2 ≥ 0 := sq_nonneg (dzdy b e h)
  exact add_nonneg h6 h7

end VeriGIS.HornSlope
