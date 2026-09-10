import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

/-- A 3x3 window of elevations. -/
abbrev Window := Matrix (Fin 3) (Fin 3) ℝ

/-- The Horn slope-square formula for a 3x3 window with spacing w. -/
def SlopeSq (w : ℝ) (E : Window) : ℝ :=
  let dx := (1/(2*w)) * ((E 1 2 + E 2 2 + E 2 1) - (E 1 0 + E 0 0 + E 0 1))
  let dy := (1/(2*w)) * ((E 0 1 + E 0 2 + E 1 2) - (E 1 0 + E 2 0 + E 2 1))
  dx^2 + dy^2

/-- For any finite 3x3 elevation window and positive grid spacing w,
    the Horn slope-square is nonnegative. -/
theorem SlopeSq_nonneg (w : ℝ) (hw : w > 0) (E : Window) : 0 ≤ SlopeSq w E := by
  unfold SlopeSq
  have h1 : 0 ≤ ((1/(2*w)) * ((E 1 2 + E 2 2 + E 2 1) - (E 1 0 + E 0 0 + E 0 1)))^2 :=
    pow_two_nonneg _
  have h2 : 0 ≤ ((1/(2*w)) * ((E 0 1 + E 0 2 + E 1 2) - (E 1 0 + E 2 0 + E 2 1)))^2 :=
    pow_two_nonneg _
  linarith
