import Mathlib.Tactic

namespace VeriGIS.Fill1D

noncomputable section

/-!
## 1D Left-Outlet Fill Operator Specification

We formalize the 1D pit-filling algorithm where:
- The outlet is fixed at the leftmost position (index 0)
- Filled elevation at each cell is the maximum of:
  1. Original elevation
  2. Filled elevation of the left neighbor

This yields a non-decreasing sequence from left to right.
-/

/-- Fill operator for 1D elevation sequences -/
def fill : List ℝ → List ℝ
| [] => []
| x::xs => 
    let rest := fill xs
    x :: List.map (max x) rest

/-!
### Core Property: Non-decreasing Sequence
For any input elevation list `a`, the filled sequence satisfies:
∀ i < (length (fill a) - 1), (fill a)[i] ≤ (fill a)[i+1]
-/

theorem fill_non_decreasing (a : List ℝ) :
    ∀ (i : Fin (List.length (fill a) - 1)), 
      List.get (fill a) i.castSucc ≤ List.get (fill a) i.succ := by
  induction a with
  | nil => 
      intro i
      have h_len : List.length (fill []) = 0 := rfl
      simp [h_len] at i
  | cons x xs ih =>
      unfold fill
      let filled_rest := fill xs
      intro i
      cases i using Fin.cases with
      | zero =>
          simp [List.get]
          apply le_max_left
      | succ i =>
          simp [List.get]
          have : i < List.length filled_rest - 1 := by
            rw [List.length_map] at i
            exact Nat.sub_lt_sub_right i.is_lt (by decide)
          specialize ih ⟨i, this⟩
          apply le_trans ?_ (le_max_right _ _)
          exact ih

end -- noncomputable section

end VeriGIS.Fill1D
