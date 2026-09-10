import Mathlib.Data.Stream.Defs
import Mathlib.Data.Stream.Init
import Mathlib.Data.Nat.Basic
import Mathlib.Order.Basic

namespace Fill1D

/-- The 1D left-outlet fill operator.
    `fill a i` is defined as the maximum of the original value at `i` and the filled value at `i-1`
    (with the left boundary treated as having value `-∞`). -/
def fill (a : ℕ → ℤ) : ℕ → ℤ
  | 0 => a 0
  | i + 1 => max (a (i + 1)) (fill a i)

/-- The main theorem: the filled sequence is nondecreasing. -/
theorem fill_nondecreasing (a : ℕ → ℤ) (i : ℕ) : fill a i ≤ fill a (i + 1) := by
  induction' i with k IH
  · -- Base case i = 0
    simp [fill]
    exact le_max_right (a 0) (a 1)
  · -- Inductive step
    simp [fill]
    have h1 : fill a k ≤ max (a (k + 1)) (fill a k) := le_max_right _ _
    have h2 : max (a (k + 1)) (fill a k) ≤ max (a (k + 2)) (max (a (k + 1)) (fill a k)) :=
      le_max_right _ _
    exact h1.trans h2

end Fill1D
