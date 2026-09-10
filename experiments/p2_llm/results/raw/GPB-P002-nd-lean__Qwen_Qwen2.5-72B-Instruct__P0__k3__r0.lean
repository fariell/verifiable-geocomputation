import data.array.basic
import data.real.basic
import tactic

namespace VeriGIS

section FillOperator

variables {α : Type} [linear_order α] [decidable_eq α]

-- Define a 1D grid as a list of elements
def grid1D := list α

-- Define the 1D left-outlet Fill operator
def fill1D (a : grid1D) : grid1D :=
  let fill := a.map (λ x, x) in
  let rec fill' (i : ℕ) (fill : grid1D) : grid1D :=
    if i < fill.length - 1 then
      let new_val := max (fill.nth i) (fill.nth (i + 1)) in
      fill'.update_nth (i + 1) new_val
    else
      fill
  in
  fill'.iterate (0 : ℕ) fill (a.length - 1)

-- Define the property that the Fill operator yields a nondecreasing sequence
def nondecreasing (a : grid1D) : Prop :=
  ∀ i, i < a.length - 1 → a.nth i ≤ a.nth (i + 1)

-- Prove that the 1D left-outlet Fill operator yields a nondecreasing sequence
theorem fill1D_nondecreasing (a : grid1D) : nondecreasing (fill1D a) :=
begin
  unfold fill1D,
  induction a with x a' ih,
  { simp [nondecreasing, list.length, list.nth], },
  { simp [nondecreasing, list.length, list.nth, fill1D, list.map, list.update_nth],
    have h : (a'.iterate (0 : ℕ) (a'.map (λ x, x)) (a'.length - 1)).length = a'.length,
    { simp [list.iterate, list.length], },
    have h' : ∀ i, i < a'.length - 1 → (a'.iterate (0 : ℕ) (a'.map (λ x, x)) (a'.length - 1)).nth i ≤ (a'.iterate (0 : ℕ) (a'.map (λ x, x)) (a'.length - 1)).nth (i + 1),
    { intros i hi,
      simp [list.iterate, list.update_nth, list.nth],
      cases a' with y a''; simp,
      { exact false.elim (lt_irrefl i hi), },
      { have h1 : i < a''.length - 1,
        { linarith, },
        have h2 : (a''.iterate (0 : ℕ) (a''.map (λ x, x)) (a''.length - 1)).nth i ≤ (a''.iterate (0 : ℕ) (a''.map (λ x, x)) (a''.length - 1)).nth (i + 1),
        { exact ih h1, },
        have h3 : (a''.iterate (0 : ℕ) (a''.map (λ x, x)) (a''.length - 1)).nth (i + 1) ≤ (a''.iterate (0 : ℕ) (a''.map (λ x, x)) (a''.length - 1)).nth (i + 2),
        { exact ih (lt_of_lt_of_le hi (le_of_lt (lt_add_one (a''.length - 1)))), },
        exact le_trans h2 h3, }},
    exact h', }
end

end FillOperator

end VeriGIS
