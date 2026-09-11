import Mathlib.Tactic.Linarith

def discrete_laplacian (f : Fin 3 → Fin 3 → ℤ) : ℤ :=
  f 0 1 + f 2 1 + f 1 0 + f 1 2 - 4 * f 1 1

theorem local_max_imp_neg_laplacian (f : Fin 3 → Fin 3 → ℤ)
    (h0 : f 1 1 ≥ f 0 1) (h1 : f 1 1 ≥ f 2 1) (h2 : f 1 1 ≥ f 1 0) (h3 : f 1 1 ≥ f 1 2) :
    discrete_laplacian f ≤ 0 := by
  unfold discrete_laplacian
  linarith [h0, h1, h2, h3]
