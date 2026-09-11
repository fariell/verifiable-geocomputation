import Mathlib.Data.Real.Basic
import Mathlib.Data.Nat.Basic

namespace FillOperator

-- Define the 1D left-outlet Fill operator
def fill (a : List ℝ) : List ℝ := List.map (fun i => List.foldl (fun acc j => max acc a[j]) a[i] a) (List.range a.length)

-- Property: The fill operator yields a nondecreasing sequence
lemma fill_nondecreasing (a : List ℝ) (h : ∀ i, i < a.length → a[i] ≤ a[i + 1]) : ∀ i, i < fill a.length → fill a[i] ≤ fill a[i + 1] := by
  intro i hi
  simp [fill] at *
  intro i hi
  apply List.foldl_le
  intro j hj
  apply max_le
  apply h
  linarith
  apply h
  linarith

end FillOperator
