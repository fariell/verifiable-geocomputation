import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

theorem discrete_laplacian_nonpositive (h : ℤ × ℤ → ℝ)
  (h_north : h (0, 0) ≥ h (0, 1))
  (h_south : h (0, 0) ≥ h (0, -1))
  (h_east : h (0, 0) ≥ h (1, 0))
  (h_west : h (0, 0) ≥ h (-1, 0)) :
  h (-1, 0) + h (1, 0) + h (0, -1) + h (0, 1) - 4 * h (0, 0) ≤ 0 := by
  have key1 := sub_nonpos_of_le h_west    -- h(-1,0) - h(0,0) ≤ 0
  have key2 := sub_nonpos_of_le h_east    -- h(1,0) - h(0,0) ≤ 0
  have key3 := sub_nonpos_of_le h_south   -- h(0,-1) - h(0,0) ≤ 0
  have key4 := sub_nonpos_of_le h_north   -- h(0,1) - h(0,0) ≤ 0
  linarith
