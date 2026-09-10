import Mathlib

-- We'll define a simple grid as a function from ℤ × ℤ to ℝ
-- This allows us to talk about neighbors without worrying about bounds.
-- The theorem is about a local property, so we can assume the needed neighbors exist.

variable (grid : ℤ × ℤ → ℝ)

-- Discrete Laplacian (5-point stencil) at (i, j)
def discreteLaplacian (i j : ℤ) : ℝ :=
  grid (i-1, j) + grid (i+1, j) + grid (i, j-1) + grid (i, j+1) - 4 * grid (i, j)

-- Local maximum condition: center ≥ each of the four orthogonal neighbors
def isLocalMax (i j : ℤ) : Prop :=
  grid (i, j) ≥ grid (i-1, j) ∧
  grid (i, j) ≥ grid (i+1, j) ∧
  grid (i, j) ≥ grid (i, j-1) ∧
  grid (i, j) ≥ grid (i, j+1)

-- Theorem: If the center is a local max, then the discrete Laplacian ≤ 0.
theorem local_max_implies_laplacian_nonpos (i j : ℤ) (h : isLocalMax grid i j) :
    discreteLaplacian grid i j ≤ 0 := by
  rcases h with ⟨h_left, h_right, h_down, h_up⟩
  unfold discreteLaplacian
  have h1 : grid (i-1, j) ≤ grid (i, j) := h_left
  have h2 : grid (i+1, j) ≤ grid (i, j) := h_right
  have h3 : grid (i, j-1) ≤ grid (i, j) := h_down
  have h4 : grid (i, j+1) ≤ grid (i, j) := h_up
  linarith
