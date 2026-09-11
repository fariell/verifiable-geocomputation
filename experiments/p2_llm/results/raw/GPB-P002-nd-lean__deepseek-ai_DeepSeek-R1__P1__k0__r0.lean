import Mathlib.Tactic

namespace VeriGIS.OneDFill

noncomputable section

/-!
## 1D Left-Outlet Fill Operator Specification

We formalize the 1D pit-filling algorithm where:
- The outlet is at the leftmost position (index 0)
- Fill values propagate rightward: 
  `fill(a)[i] = max(a[i], fill(a)[i-1])`
- The result must be nondecreasing: 
  `∀ i, fill(a)[i] ≤ fill(a)[i+1]`
-/

/-- Predicate: List is nondecreasing (adjacent elements satisfy `x ≤ y`) -/
def nondec : List ℝ → Prop
| [] => True
| [_] => True
| x::y::xs => x ≤ y ∧ nondec (y::xs)

/-- Auxiliary function for left-outlet fill (carries current fill value) -/
def fill_aux (acc : ℝ) : List ℝ → List ℝ
| [] => []
| x::xs => 
    let m := max acc x
    m :: fill_aux m xs

/-- Left-outlet fill operator: 
    - Start with first element
    - Propagate max(current, previous) rightward -/
def fill : List ℝ → List ℝ
| [] => []
| x::xs => x :: fill_aux x xs

/-!
### Key Property: Fill Result is Nondecreasing
-/

lemma fill_aux_prop (acc : ℝ) (xs : List ℝ) : 
    nondec (fill_aux acc xs) ∧ (∀ y ∈ fill_aux acc xs, acc ≤ y) := by
  induction xs with
  | nil => simp [fill_aux, nondec]
  | cons x xs' ih =>
      simp [fill_aux]
      rcases ih with ⟨ih_nondec, ih_all⟩
      constructor
      · cases hrest : fill_aux (max acc x) xs' with
        | nil => simp [nondec]
        | cons h t =>
            have h_first : max acc x ≤ h := by
              apply ih_all; simp [hrest, List.mem_cons]
            have h_tail : nondec (h::t) := by
              rw [← hrest] at ih_nondec; exact ih_nondec
            exact ⟨h_first, h_tail⟩
      · intro y hy
        simp at hy
        rcases hy with (rfl | hy)
        · apply le_max_left
        · exact le_trans (le_max_left _ _) (ih_all y hy)

theorem fill_nondec (a : List ℝ) : nondec (fill a) := by
  cases a with
  | nil => simp [fill, nondec]
  | cons x xs =>
      cases xs with
      | nil => simp [fill, fill_aux, nondec]
      | cons y ys =>
          have ⟨nondec_tail, all_ge_x⟩ := fill_aux_prop x (y::ys)
          simp [fill, nondec]
          constructor
          · apply all_ge_x
            simp [fill_aux, List.mem_cons, true_or]
          · exact nondec_tail

end -- noncomputable section

end VeriGIS.OneDFill
