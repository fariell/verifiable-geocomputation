import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Real.Basic

/-
  Horn (1981) finite-difference slope operator for a 3×3 window.
  Given elevations z₁,…,z₉ arranged as:
    z₁ z₂ z₃
    z₄ z₅ z₆
    z₇ z₈ z₉
  and grid spacing w > 0, the slope squared is:
    SlopeSq = (dzdx)^2 + (dzdy)^2
  where
    dzdx = (z₃ + 2*z₆ + z₉ - z₁ - 2*z₄ - z₇) / (8*w)
    dzdy = (z₇ + 2*z₈ + z₉ - z₁ - 2*z₂ - z₃) / (8*w)
-/

structure HornWindow where
  z₁ z₂ z₃ z₄ z₅ z₆ z₇ z₈ z₉ : ℝ

namespace HornWindow

def dzdx (h : HornWindow) (w : ℝ) : ℝ :=
  (h.z₃ + 2 * h.z₆ + h.z₉ - h.z₁ - 2 * h.z₄ - h.z₇) / (8 * w)

def dzdy (h : HornWindow) (w : ℝ) : ℝ :=
  (h.z₇ + 2 * h.z₈ + h.z₉ - h.z₁ - 2 * h.z₂ - h.z₃) / (8 * w)

def slopeSq (h : HornWindow) (w : ℝ) : ℝ :=
  (dzdx h w) ^ 2 + (dzdy h w) ^ 2

theorem horn_slopeSq_nonneg (h : HornWindow) (w : ℝ) (hw : w > 0) : 0 ≤ slopeSq h w := by
  unfold slopeSq
  have h1 : 0 ≤ (dzdx h w) ^ 2 := by nlinarith [sq_nonneg (dzdx h w)]
  have h2 : 0 ≤ (dzdy h w) ^ 2 := by nlinarith [sq_nonneg (dzdy h w)]
  nlinarith

end HornWindow
