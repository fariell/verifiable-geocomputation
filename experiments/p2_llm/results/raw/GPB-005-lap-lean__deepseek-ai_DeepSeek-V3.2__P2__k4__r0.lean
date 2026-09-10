import Mathlib

-- We'll model a 3×3 grid of elevations as a function from ℤ × ℤ to ℝ.
-- The discrete Laplacian here is the sum of the four orthogonal neighbors minus 4 times the center.
-- The theorem: if the center is a local maximum among its four orthogonal neighbors,
-- then the discrete Laplacian ≤ 0.

theorem local_max_implies_nonpositive_laplacian
    (f : ℤ × ℤ → ℝ) (x y : ℤ)
    (h_max : f (x, y) ≥ f (x + 1, y))
    (h_max2 : f (x, y) ≥ f (x - 1, y))
    (h_max3 : f (x, y) ≥ f (x, y + 1))
    (h_max4 : f (x, y) ≥ f (x, y - 1)) :
    let neighbors_sum := f (x + 1, y) + f (x - 1, y) + f (x, y + 1) + f (x, y - 1)
    let laplacian := neighbors_sum - 4 * f (x, y)
    in laplacian ≤ 0 := by
  intro neighbors_sum laplacian
  have h1 : f (x + 1, y) ≤ f (x, y) := h_max
  have h2 : f (x - 1, y) ≤ f (x, y) := h_max2
  have h3 : f (x, y + 1) ≤ f (x, y) := h_max3
  have h4 : f (x, y - 1) ≤ f (x, y) := h_max4
  have h_sum : neighbors_sum ≤ 4 * f (x, y) := by
    linarith
  linarith
