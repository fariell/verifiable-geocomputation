import Mathlib.Data.Real.Basic

theorem local_max_imp_laplacian_nonpositive (g : Fin 3 → Fin 3 → ℝ)
    (h_n : g 1 1 ≥ g 0 1) (h_s : g 1 1 ≥ g 2 1) (h_e : g 1 1 ≥ g 1 2) (h_w : g 1 1 ≥ g 1 0)) :
    (g 0 1 + g 2 1 + g 1 2 + g 1 0) - 4 * g 1 1 ≤ 0 := by
  have h1 := h_n  -- g 0 1 ≤ g 1 1
  have h2 := h_s  -- g 2 1 ≤ g 1 1
  have h3 := h_e  -- g 1 2 ≤ g 1 1
  have h4 := h_w  -- g 1 0 ≤ g 1 1
  linarith
