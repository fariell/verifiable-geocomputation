import Mathlib

-- Define a grid as a function from ℤ × ℤ to ℝ
def Grid := ℤ × ℤ → ℝ

-- Discrete Laplacian for a 3×3 orthogonal neighborhood
-- Laplacian = sum of (neighbor - center) over orthogonal neighbors
-- Here we use the 4 orthogonal neighbors: up, down, left, right
def discrete_laplacian (g : Grid) (p : ℤ × ℤ) : ℝ :=
  let (x, y) := p
  (g (x+1, y) - g (x, y)) + (g (x-1, y) - g (x, y)) +
  (g (x, y+1) - g (x, y)) + (g (x, y-1) - g (x, y))

-- A center is a discrete local maximum in the orthogonal neighborhood
-- if its value is ≥ each of the four orthogonal neighbors
def is_local_max_orth (g : Grid) (p : ℤ × ℤ) : Prop :=
  let (x, y) := p
  g (x, y) ≥ g (x+1, y) ∧
  g (x, y) ≥ g (x-1, y) ∧
  g (x, y) ≥ g (x, y+1) ∧
  g (x, y) ≥ g (x, y-1)

-- Theorem: If the center is a local max in the orthogonal neighborhood,
-- then the discrete Laplacian at the center is ≤ 0.
theorem local_max_implies_laplacian_nonpos (g : Grid) (p : ℤ × ℤ) :
    is_local_max_orth g p → discrete_laplacian g p ≤ 0 := by
  intro hmax
  unfold discrete_laplacian
  unfold is_local_max_orth at hmax
  rcases hmax with ⟨h1, h2, h3, h4⟩
  have h1' : g (p.1 + 1, p.2) - g p ≤ 0 := by linarith
  have h2' : g (p.1 - 1, p.2) - g p ≤ 0 := by linarith
  have h3' : g (p.1, p.2 + 1) - g p ≤ 0 := by linarith
  have h4' : g (p.1, p.2 - 1) - g p ≤ 0 := by linarith
  linarith
