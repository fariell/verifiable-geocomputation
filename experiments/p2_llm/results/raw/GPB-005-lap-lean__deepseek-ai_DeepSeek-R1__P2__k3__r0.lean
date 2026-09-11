import Mathlib.Data.Real.Basic

theorem local_max_imp_laplacian_nonpos (c n s w e : ℝ)
  (h_n : c ≥ n) (h_s : c ≥ s) (h_w : c ≥ w) (h_e : c ≥ e) :
  (n + s + w + e) - 4 * c ≤ 0 := by
  linarith
