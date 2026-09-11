import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic

open Real

noncomputable def horn_slope_sq (e : Fin 3 → Fin 3 → ℝ) (w : ℝ) : ℝ :=
  let dzdx := (e 0 2 + 2 * e 1 2 + e 2 2 - (e 0 0 + 2 * e 1 0 + e 2 0)) / (8 * w)
  let dzdy := (e 2 0 + 2 * e 2 1 + e 2 2 - (e 0 0 + 2 * e 0 1 + e 0 2)) / (8 * w)
  dzdx^2 + dzdy^2

theorem horn_slope_sq_nonneg (e : Fin 3 → Fin 3 → ℝ) (w : ℝ) (h : w > 0) : 
  horn_slope_sq e w ≥ 0 := by
  unfold horn_slope_sq
  apply add_nonneg
  · exact sq_nonneg _
  · exact sq_nonneg _
