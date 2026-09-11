import Mathlib.Data.Real.Basic

structure OrthogonalWindow where
  north : ℝ
  south : ℝ
  east : ℝ
  west : ℝ
  center : ℝ

def discrete_laplacian (w : OrthogonalWindow) (dx dy : ℝ) : ℝ :=
  (w.west - 2 * w.center + w.east) / dx^2 + (w.north - 2 * w.center + w.south) / dy^2

theorem local_max_implies_nonpositive_laplacian
  (w : OrthogonalWindow)
  (dx dy : ℝ)
  (dx_pos : dx > 0)
  (dy_pos : dy > 0)
  (h_max : w.center ≥ w.north ∧ w.center ≥ w.south ∧ w.center ≥ w.east ∧ w.center ≥ w.west) :
  discrete_laplacian w dx dy ≤ 0 := by
  unfold discrete_laplacian
  rcases h_max with ⟨hn, hs, he, hw⟩
  have h1 : w.west - 2 * w.center + w.east ≤ 0 := by linarith
  have h2 : w.north - 2 * w.center + w.south ≤ 0 := by linarith
  have denom1_pos : 0 < dx^2 := by nlinarith [dx_pos]
  have denom2_pos : 0 < dy^2 := by nlinarith [dy_pos]
  apply add_nonpos
  · apply div_nonpos_of_nonpos_of_nonneg h1 (le_of_lt denom1_pos)
  · apply div_nonpos_of_nonpos_of_nonneg h2 (le_of_lt denom2_pos)
