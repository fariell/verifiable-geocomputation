import Mathlib

-- We'll define a simple grid as a function from ℤ × ℤ to ℝ
-- For a 3×3 window, we only need the center and its four orthogonal neighbors.
-- We'll assume the grid is defined everywhere we need it.

-- Discrete Laplacian (5-point stencil) at (i,j) is:
--   f(i+1,j) + f(i-1,j) + f(i,j+1) + f(i,j-1) - 4*f(i,j)
-- If the center is a local maximum in the 4 orthogonal directions, then:
--   f(i,j) ≥ f(i+1,j), f(i,j) ≥ f(i-1,j), f(i,j) ≥ f(i,j+1), f(i,j) ≥ f(i,j-1)
-- We want to show that under these conditions, the discrete Laplacian ≤ 0.

theorem local_max_implies_nonpositive_laplacian
    (f : ℤ × ℤ → ℝ)
    (i j : ℤ)
    (h1 : f (i, j) ≥ f (i+1, j))
    (h2 : f (i, j) ≥ f (i-1, j))
    (h3 : f (i, j) ≥ f (i, j+1))
    (h4 : f (i, j) ≥ f (i, j-1)) :
    f (i+1, j) + f (i-1, j) + f (i, j+1) + f (i, j-1) - 4 * f (i, j) ≤ 0 := by
  -- Let L = f(i+1,j) + f(i-1,j) + f(i,j+1) + f(i,j-1) - 4*f(i,j)
  -- We know each neighbor ≤ f(i,j), so each term f(neighbor) - f(i,j) ≤ 0.
  -- Therefore, the sum of four such terms is ≤ 0.
  have h1' : f (i+1, j) - f (i, j) ≤ 0 := by linarith
  have h2' : f (i-1, j) - f (i, j) ≤ 0 := by linarith
  have h3' : f (i, j+1) - f (i, j) ≤ 0 := by linarith
  have h4' : f (i, j-1) - f (i, j) ≤ 0 := by linarith
  -- Sum the four inequalities
  have h_sum : (f (i+1, j) - f (i, j)) + (f (i-1, j) - f (i, j)) +
               (f (i, j+1) - f (i, j)) + (f (i, j-1) - f (i, j)) ≤ 0 := by
    linarith
  -- Simplify the left-hand side to get the discrete Laplacian expression
  ring_nf at h_sum
  exact h_sum
