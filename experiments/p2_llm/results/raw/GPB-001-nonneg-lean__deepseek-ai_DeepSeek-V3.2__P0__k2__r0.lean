import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Real.Basic

/-
  Horn (1981) finite-difference slope operator for a 3×3 window.
  Given elevations z₀,…,z₈ arranged as:
    z₀ z₁ z₂
    z₃ z₄ z₅
    z₆ z₇ z₈
  and grid spacing w > 0, the squared slope is:
    SlopeSq = ((z₆ + 2*z₇ + z₈) - (z₀ + 2*z₁ + z₂))² / (8*w)²
            + ((z₂ + 2*z₅ + z₈) - (z₀ + 2*z₃ + z₆))² / (8*w)²
-/
def HornSlopeSq (z : Fin 9 → ℝ) (w : ℝ) : ℝ :=
  let dzdx := ((z 6 + 2 * z 7 + z 8) - (z 0 + 2 * z 1 + z 2)) / (8 * w)
  let dzdy := ((z 2 + 2 * z 5 + z 8) - (z 0 + 2 * z 3 + z 6)) / (8 * w)
  dzdx ^ 2 + dzdy ^ 2

/--
  For any finite 3×3 elevation window and positive grid spacing w,
  the Horn slope-square is nonnegative.
  This holds for arbitrary elevations, not only planar surfaces.
-/
theorem HornSlopeSq_nonneg (z : Fin 9 → ℝ) (w : ℝ) (hw : w > 0) : 0 ≤ HornSlopeSq z w := by
  unfold HornSlopeSq
  have hw' : 8 * w > 0 := by linarith
  have h1 : 0 ≤ ((z 6 + 2 * z 7 + z 8) - (z 0 + 2 * z 1 + z 2)) / (8 * w) ^ 2 := by
    apply div_nonneg
    · nlinarith [sq_nonneg ((z 6 + 2 * z 7 + z 8) - (z 0 + 2 * z 1 + z 2))]
    · nlinarith
  have h2 : 0 ≤ ((z 2 + 2 * z 5 + z 8) - (z 0 + 2 * z 3 + z 6)) / (8 * w) ^ 2 := by
    apply div_nonneg
    · nlinarith [sq_nonneg ((z 2 + 2 * z 5 + z 8) - (z 0 + 2 * z 3 + z 6))]
    · nlinarith
  have h3 : 0 ≤ ((z 6 + 2 * z 7 + z 8) - (z 0 + 2 * z 1 + z 2)) ^ 2 / ((8 * w) ^ 2) := by
    apply div_nonneg (by nlinarith [sq_nonneg _]) (by nlinarith)
  have h4 : 0 ≤ ((z 2 + 2 * z 5 + z 8) - (z 0 + 2 * z 3 + z 6)) ^ 2 / ((8 * w) ^ 2) := by
    apply div_nonneg (by nlinarith [sq_nonneg _]) (by nlinarith)
  nlinarith
