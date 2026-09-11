import Mathlib.Data.Real.Basic

def discrete_laplacian (w : Fin 3 → Fin 3 → ℝ) : ℝ :=
  w 0 1 + w 1 0 + w 1 2 + w 2 1 - 4 * w 1 1

theorem local_max_imp_nonpos_laplacian (w : Fin 3 → Fin 3 → ℝ) :
  w 1 1 ≥ w 0 1 →  -- Center ≥ up
  w 1 1 ≥ w 2 1 →  -- Center ≥ down
  w 1 1 ≥ w 1 0 →  -- Center ≥ left
  w 1 1 ≥ w 1 2 →  -- Center ≥ right
  discrete_laplacian w ≤ 0 := by
  intro h_up h_down h_left h_right
  unfold discrete_laplacian
  have h1 : w 0 1 - w 1 1 ≤ 0 := by linarith
  have h2 : w 2 1 - w 1 1 ≤ 0 := by linarith
  have h3 : w 1 0 - w 1 1 ≤ 0 := by linarith
  have h4 : w 1 2 - w 1 1 ≤ 0 := by linarith
  linarith
