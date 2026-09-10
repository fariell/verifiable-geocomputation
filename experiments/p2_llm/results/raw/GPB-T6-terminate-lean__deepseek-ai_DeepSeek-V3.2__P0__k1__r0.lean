import Mathlib.Data.Finset.Basic
import Mathlib.Data.Nat.Basic
import Mathlib.Order.WellFounded

section

variable {α : Type} [Fintype α] (succ : α → α)

/-- A strict descent relation: `succ x` is strictly less than `x` according to some measure. -/
structure StrictDescent (measure : α → ℕ) : Prop where
  desc : ∀ x, succ x ≠ x → measure (succ x) < measure x

/-- The orbit of `x` under `succ`, as a list of successive applications. -/
def orbit (x : α) : List α :=
  let rec go (x : α) (seen : Finset α) : List α :=
    if h : x ∈ seen then []
    else x :: go (succ x) (insert x seen)
  go x ∅

/-- The orbit terminates if it reaches a fixed point. -/
def terminates (x : α) : Prop :=
  ∃ n : ℕ, (Nat.iterate succ n x) = succ ((Nat.iterate succ n x))

/-- Every orbit terminates under a strict descent relation. -/
theorem all_orbits_terminate (measure : α → ℕ) (h_desc : StrictDescent succ measure) :
    ∀ x, terminates succ x := by
  intro x
  have wf : WellFounded (InvImage (· < ·) measure) :=
    InvImage.wf measure (Nat.lt_wfRel.wf)
  refine WellFounded.induction wf x ?_
  intro y IH
  by_cases h_fixed : succ y = y
  · refine ⟨0, ?_⟩
    simp [h_fixed]
  · have h_lt : measure (succ y) < measure y :=
      h_desc.desc y h_fixed
    rcases IH (succ y) h_lt with ⟨n, hn⟩
    refine ⟨n + 1, ?_⟩
    simp [Nat.iterate_succ', hn]

end
