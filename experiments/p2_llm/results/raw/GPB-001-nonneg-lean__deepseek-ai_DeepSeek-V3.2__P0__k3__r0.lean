import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Real.Basic

/-
  Horn (1981) finite-difference slope operator for a 3×3 window.
  Given elevations z₁,…,z₉ arranged as:
    z₁ z₂ z₃
    z₄ z₅ z₆
    z₇ z₈ z₉
  and grid spacing w > 0, the slope squared is:
    SlopeSq = ((z₃ + 2z₆ + z₉ - z₁ - 2z₄ - z₇)/(8w))²
            + ((z₇ + 2z₈ + z₉ - z₁ - 2z₂ - z₃)/(8w))²
-/
def hornSlopeSq (z : Fin 9 → ℝ) (w : ℝ) : ℝ :=
  let dzdx := (z 2 + 2 * z 5 + z 8 - z 0 - 2 * z 3 - z 6) / (8 * w)
  let dzdy := (z 6 + 2 * z 7 + z 8 - z 0 - 2 * z 1 - z 2) / (8 * w)
  dzdx ^ 2 + dzdy ^ 2

/--
  For any finite 3×3 elevation window and positive grid spacing w,
  the Horn slope‑square is nonnegative.
  This holds for arbitrary elevations, not only planar surfaces.
-/
theorem hornSlopeSq_nonneg (z : Fin 9 → ℝ) (w : ℝ) (hw : w > 0) : 0 ≤ hornSlopeSq z w := by
  unfold hornSlopeSq
  have hw' : 8 * w > 0 := by linarith
  have h1 : 0 ≤ ((z 2 + 2 * z 5 + z 8 - z 0 - 2 * z 3 - z 6) / (8 * w)) ^ 2 := by
    apply pow_two_nonneg
  have h2 : 0 ≤ ((z 6 + 2 * z 7 + z 8 - z 0 - 2 * z 1 - z 2) / (8 * w)) ^ 2 := by
    apply pow_two_nonneg
  linarith
