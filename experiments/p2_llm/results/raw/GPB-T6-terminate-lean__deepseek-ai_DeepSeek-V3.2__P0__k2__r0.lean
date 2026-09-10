import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Order.WellFounded

section

variable {α : Type} [Fintype α] (succ : α → α)

/-- A strict descent relation: `succ x` is strictly less than `x` according to some measure. -/
structure StrictDescent (measure : α → ℕ) : Prop where
  desc : ∀ x, succ x ≠ x → measure (succ x) < measure x

/-- The orbit of `x` under `succ`, as a list, stopping when a fixed point is reached. -/
def orbit (x : α) : List α :=
  let rec go (x : α) (seen : Finset α) : List α :=
    if h : succ x = x then [x]
    else if hmem : x ∈ seen then []
    else x :: go (succ x) (seen.insert x)
  go x ∅

/-- The orbit terminates (reaches a fixed point) in finitely many steps. -/
def terminates (x : α) : Prop :=
  ∃ n : ℕ, ∀ m ≥ n, (Function.iterate succ m) x = (Function.iterate succ n) x

theorem termination_of_strict_descent (measure : α → ℕ) (hdesc : StrictDescent succ measure) :
    ∀ x, terminates succ x := by
  intro x
  have hwf : WellFounded (InvImage (· < · : ℕ → ℕ → Prop) measure) :=
    InvImage.wf measure Nat.lt_wfRel.wf
  refine WellFounded.induction hwf x ?_
  intro y ih
  by_cases hy : succ y = y
  · refine ⟨0, λ m _ => ?_⟩
    simp [hy]
  · have hlt := hdesc.desc y hy
    rcases ih (succ y) hlt with ⟨n, hn⟩
    refine ⟨n + 1, λ m hm => ?_⟩
    rcases Nat.le_of_eq_add (Nat.succ_le_of_lt hm) with ⟨k, rfl⟩
    simp [Function.iterate_succ']
    exact hn k (by omega)

/-- Alternative formulation using a `decreases` clause. -/
theorem termination_by_decreases (measure : α → ℕ) (hdesc : StrictDescent succ measure) (x : α) :
    terminates succ x := by
  apply termination_of_strict_descent measure hdesc x

end
