import Mathlib.Tactic.Linarith

theorem local_max_imp_laplacian_nonpos (g : Fin 3 → Fin 3 → ℝ)
    (h_top : g 1 1 ≥ g 0 1)
    (h_bot : g 1 1 ≥ g 2 1)
    (h_left : g 1 1 ≥ g 1 0)
    (h_right : g 1 1 ≥ g 1 2) :
    (g 0 1 + g 2 1 + g 1 0 + g 1 2) - 4 * g 1 1 ≤ 0 := by
  have h1 : g 0 1 ≤ g 1 1 := h_top
  have h2 : g 2 1 ≤ g 1 1 := h_bot
  have h3 : g 1 0 ≤ g 1 1 := h_left
  have h4 : g 1 2 ≤ g 1 1 := h_right
  linarith
