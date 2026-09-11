/-
  ==========================================================================
   GeoProofBench · Discrete Local Maximum and Laplacian
   文件 : formal/lean4/VeriGIS/LocalMaxLaplacian.lean
   算子 : Discrete Laplacian in 3×3 window
   环境 : Lean 4 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  Formalizes the property: If center cell is local maximum (≥ orthogonal neighbors),
  then discrete Laplacian at center is non-positive.
-/

import Mathlib.Tactic

namespace VeriGIS.LocalMaxLaplacian

noncomputable section

/-!
  ## 3×3 window convention (orthogonal neighbors labeled)

      a   b   c
      d   e   f   → Orthogonal neighbors: b (top), d (left), f (right), h (bottom)
      g   h   i
-/

/-- Discrete Laplacian operator for center cell e -/
def laplacian (b d f h e : ℝ) : ℝ := (b + d + f + h) - 4 * e

/--
  Main theorem: When center cell e is local maximum (≥ all four orthogonal neighbors),
  the discrete Laplacian is non-positive.
-/
theorem local_max_imp_nonpos_laplacian (b d f h e : ℝ)
    (h_top : e ≥ b) (h_left : e ≥ d) (h_right : e ≥ f) (h_bottom : e ≥ h) :
    laplacian b d f h e ≤ 0 := by
  -- Expand Laplacian definition
  unfold laplacian
  -- Combine inequalities: b + d + f + h ≤ 4*e
  have sum_le : b + d + f + h ≤ e + e + e + e := by
    linarith [h_top, h_left, h_right, h_bottom]
  -- Rearrange to required form
  linarith

end -- noncomputable section

end VeriGIS.LocalMaxLaplacian
