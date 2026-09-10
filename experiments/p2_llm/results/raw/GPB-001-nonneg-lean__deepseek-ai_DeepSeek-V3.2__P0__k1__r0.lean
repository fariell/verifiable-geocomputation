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

structure HornWindow where
  z₁ z₂ z₃ z₄ z₅ z₆ z₇ z₈ z₉ : ℝ

namespace HornWindow

def dzdx (w : ℝ) (h : HornWindow) : ℝ :=
  (h.z₃ + 2 * h.z₆ + h.z₉ - h.z₁ - 2 * h.z₄ - h.z₇) / (8 * w)

def dzdy (w : ℝ) (h : HornWindow) : ℝ :=
  (h.z₇ + 2 * h.z₈ + h.z₉ - h.z₁ - 2 * h.z₂ - h.z₃) / (8 * w)

def slopeSq (w : ℝ) (h : HornWindow) : ℝ :=
  (dzdx w h) ^ 2 + (dzdy w h) ^ 2

theorem horn_slopeSq_nonneg (h : HornWindow) (w : ℝ) (hw : w > 0) : 0 ≤ slopeSq w h := by
  unfold slopeSq
  have h1 : 0 ≤ (dzdx w h) ^ 2 := by apply pow_two_nonneg
  have h2 : 0 ≤ (dzdy w h) ^ 2 := by apply pow_two_nonneg
  linarith

end HornWindow
