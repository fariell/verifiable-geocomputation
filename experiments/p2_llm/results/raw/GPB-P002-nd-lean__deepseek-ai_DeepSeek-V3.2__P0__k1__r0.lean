import Mathlib.Data.Stream.Defs
import Mathlib.Data.Nat.Basic
import Mathlib.Order.Basic

namespace Fill1D

/-- The 1D left-outlet fill operator. 
    `fill a i` is the maximum of `a j` for `j ≤ i`. -/
def fill (a : ℕ → ℕ) : ℕ → ℕ
  | 0 => a 0
  | i+1 => max (fill a i) (a (i+1))

/-- The fill operator yields a nondecreasing sequence. -/
theorem fill_nondecreasing (a : ℕ → ℕ) : ∀ i, fill a i ≤ fill a (i+1) := by
  intro i
  induction' i with k IH
  · -- Base case i = 0
    simp [fill]
    exact Nat.le_max_left _ _
  · -- Inductive step
    simp [fill]
    exact Nat.le_max_left _ _

end Fill1D
