import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

theorem local_max_imp_laplacian_nonpos (b d e f h dx dy : ℝ)
    (hdx : dx > 0) (hdy : dy > 0)
    (h_max : e ≥ b ∧ e ≥ d ∧ e ≥ f ∧ e ≥ h) :
    (d - 2 * e + f) / dx ^ 2 + (b - 2 * e + h) / dy ^ 2 ≤ 0 := by
  obtain ⟨hb, hd, hf, hh⟩ := h_max
  have h1 : d + f ≤ 2 * e := by linarith
  have h2 : b + h ≤ 2 * e := by linarith
  have h1' : d - 2 * e + f ≤ 0 := by linarith
  have h2' : b - 2 * e + h ≤ 0 := by linarith
  have h1'' : (d - 2 * e + f) / dx ^ 2 ≤ 0 :=
    div_nonpos_of_nonpos_of_pos h1' (pow_pos hdx 2)
  have h2'' : (b - 2 * e + h) / dy ^ 2 ≤ 0 :=
    div_nonpos_of_nonpos_of_pos h2' (pow_pos hdy 2)
  exact add_nonpos h1'' h2''
