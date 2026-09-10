import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

-- Finite 3x3 window of elevations
abbrev ElevationMatrix := Matrix (Fin 3) (Fin 3) ℝ

-- Horn slope-square formula for a 3x3 window with spacing w
noncomputable def SlopeSq (E : ElevationMatrix) (w : ℝ) (hw : w > 0) : ℝ :=
  let dx := (E 1 2 + E 2 2 + E 1 0 + E 2 0 - 2*(E 1 1 + E 2 1)) / (6*w)
  let dy := (E 2 1 + E 2 2 + E 0 1 + E 0 2 - 2*(E 1 1 + E 1 2)) / (6*w)
  dx^2 + dy^2

theorem HornSlopeSq_nonneg (E : ElevationMatrix) (w : ℝ) (hw : w > 0) : SlopeSq E w hw ≥ 0 := by
  unfold SlopeSq
  have h1 : ((E 1 2 + E 2 2 + E 1 0 + E 2 0 - 2*(E 1 1 + E 2 1)) / (6*w)) ^ 2 ≥ 0 := by
    nlinarith? [sq_nonneg _]
  have h2 : ((E 2 1 + E 2 2 + E 0 1 + E 0 2 - 2*(E 1 1 + E 1 2)) / (6*w)) ^ 2 ≥ 0 := by
    nlinarith? [sq_nonneg _]
  nlinarith
