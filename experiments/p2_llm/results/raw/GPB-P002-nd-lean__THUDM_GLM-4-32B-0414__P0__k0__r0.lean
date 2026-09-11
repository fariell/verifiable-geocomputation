import Mathlib.Data.Real.Basic
import Mathlib.Data.Nat.Basic

namespace FillOperator

/-- The 1D left-outlet Fill operator. -/
def fill (a : List ℝ) : List ℝ := List.map (fun i => a.take (i + 1).max) a

/-- The fill operator yields a nondecreasing sequence. -/
theorem fill_nondecreasing (a : List ℝ) : ∀ i, i < a.length → fill a[i] ≤ fill a[i + 1] := fun i hi => by
  simp [fill, List.take, List.max_le_max, List.take_le, hi]
  omega

end FillOperator
