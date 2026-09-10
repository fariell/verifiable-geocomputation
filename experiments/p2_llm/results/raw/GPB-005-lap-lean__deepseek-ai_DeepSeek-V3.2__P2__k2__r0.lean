import Mathlib

-- We'll model a 3×3 grid of integers (elevations)
-- We'll represent it as a 3×3 matrix (Fin 3 → Fin 3 → ℤ)
-- The discrete Laplacian here is the sum of orthogonal neighbor differences:
--   Δ = (north + south + east + west) - 4 * center
-- But the problem states: if center ≥ each orthogonal neighbor,
-- then the discrete Laplacian ≤ 0.

-- Let's define the discrete Laplacian for a 3×3 grid at the center (1,1)
-- using zero-indexing: indices 0,1,2. Center is (1,1).
-- We'll assume the grid is given as a function `g : Fin 3 → Fin 3 → ℤ`.

theorem local_max_implies_nonpositive_laplacian (g : Fin 3 → Fin 3 → ℤ) :
    (g 1 1 ≥ g 0 1 ∧ g 1 1 ≥ g 2 1 ∧ g 1 1 ≥ g 1 0 ∧ g 1 1 ≥ g 1 2) →
    (g 0 1 + g 2 1 + g 1 0 + g 1 2 - 4 * g 1 1 ≤ 0) := by
  intro h
  rcases h with ⟨hnorth, hsouth, hwest, heast⟩
  -- We have: g 1 1 ≥ g 0 1, g 1 1 ≥ g 2 1, g 1 1 ≥ g 1 0, g 1 1 ≥ g 1 2
  -- Want: g 0 1 + g 2 1 + g 1 0 + g 1 2 - 4 * g 1 1 ≤ 0
  -- Rewrite as: (g 0 1 - g 1 1) + (g 2 1 - g 1 1) + (g 1 0 - g 1 1) + (g 1 2 - g 1 1) ≤ 0
  have h1 : g 0 1 - g 1 1 ≤ 0 := by linarith
  have h2 : g 2 1 - g 1 1 ≤ 0 := by linarith
  have h3 : g 1 0 - g 1 1 ≤ 0 := by linarith
  have h4 : g 1 2 - g 1 1 ≤ 0 := by linarith
  -- Sum of four nonpositive numbers is nonpositive
  linarith
