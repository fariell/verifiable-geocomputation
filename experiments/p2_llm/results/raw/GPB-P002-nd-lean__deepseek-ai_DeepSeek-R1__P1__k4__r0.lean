import Mathlib.Tactic

namespace VeriGIS.Fill1D

noncomputable section

/-!
## 1D Left-Outlet Fill Operator Specification

We formalize the property that the 1D left-outlet fill operator produces a nondecreasing sequence.
The fill starts at the left outlet (index 0) and propagates rightwards using the rule:
  fill[i] = max(original[i], fill[i-1])

This matches the 2D Wang & Liu algorithm's core behavior in the 1D case.
-/

/-- Auxiliary function for left-outlet fill (carries accumulator) -/
def fillAux (acc : ℝ) : List ℝ → List ℝ
  | [] => []
  | (x::xs) => 
      let new := max x acc
      new :: fillAux new xs

/-- 1D left-outlet fill operator -/
def fill : List ℝ → List ℝ
  | [] => []
  | (x::xs) => x :: fillAux x xs

/-!
### Key Property: Fill produces nondecreasing sequences

After applying the fill operator, every consecutive pair in the 
result satisfies `fill[i] ≤ fill[i+1]`.
-/

theorem fill_aux_chain (acc : ℝ) (xs : List ℝ) : 
    List.Chain (·≤·) (acc :: fillAux acc xs) := by
  induction xs with
  | nil => exact List.Chain.nil
  | cons y ys ih =>
      unfold fillAux
      apply List.Chain.cons
      · apply le_max_right
      · exact ih

theorem fill_nondec (l : List ℝ) : List.Chain (·≤·) (fill l) := by
  cases l with
  | nil => exact List.Chain.nil
  | cons x xs => 
      unfold fill
      exact fill_aux_chain x xs

/-!
### Corollary: Element-wise nondecreasing property

For any consecutive indices `i` and `i+1` in the filled result,
we have `get i ≤ get (i+1)`.
-/

theorem fill_step_nondec (l : List ℝ) (i : ℕ) (h : i < (fill l).length - 1) :
    (fill l).get ⟨i, by omega⟩ ≤ (fill l).get ⟨i+1, by omega⟩ := by
  have chain := fill_nondec l
  rw [List.chain_iff_get] at chain
  exact chain i (by omega)

end -- noncomputable section

end VeriGIS.Fill1D
