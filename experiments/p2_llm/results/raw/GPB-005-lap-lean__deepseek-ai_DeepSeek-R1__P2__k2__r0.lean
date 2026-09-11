import Mathlib.Data.Real.Basic

theorem discrete_laplacian_nonpositive (f : ℤ × ℤ → ℝ) (i j : ℤ) :
  let c := f (i, j)
  let n := f (i-1, j)
  let s := f (i+1, j)
  let e := f (i, j+1)
  let w := f (i, j-1)
  (c ≥ n ∧ c ≥ s ∧ c ≥ e ∧ c ≥ w) → 
  (n + s + e + w - 4 * c ≤ 0) := by
  intro h
  rcases h with ⟨hcn, hcs, hce, hcw⟩
  have h_sum : n + s + e + w ≤ c + c + c + c := by
    gcongr
    exact hcn; exact hcs; exact hce; exact hcw
  linarith
