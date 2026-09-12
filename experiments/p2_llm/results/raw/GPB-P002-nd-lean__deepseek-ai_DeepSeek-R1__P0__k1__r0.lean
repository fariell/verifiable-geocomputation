import Std

variable {α : Type} [LinearOrder α]

def fill (a : ℕ → α) : ℕ → α
| 0 => a 0
| n+1 => max (a (n+1)) (fill a n)

theorem fill_nondec (a : ℕ → α) (i : ℕ) : fill a i ≤ fill a (i+1) := by
  rw [fill]
  exact le_max_right (a (i+1)) (fill a i)
