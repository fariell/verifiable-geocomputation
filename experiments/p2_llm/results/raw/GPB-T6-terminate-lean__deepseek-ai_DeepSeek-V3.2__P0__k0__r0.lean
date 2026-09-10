import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Order.WellFounded

open Finset

variable {α : Type*} [Fintype α] [DecidableEq α]

-- A strict descent relation on a finite type
structure StrictDescent (succ : α → α) : Prop where
  strict : ∀ a, succ a ≠ a → succ (succ a) = succ a
  desc : ∀ a, succ a ≠ a → ∃ (f : α → ℕ), f (succ a) < f a

-- The orbit of a starting point under iteration
def orbit (succ : α → α) (start : α) : ℕ → α
  | 0 => start
  | n + 1 => succ (orbit succ start n)

-- A fixed point is where succ a = a
def isFixedPoint (succ : α → α) (a : α) : Prop := succ a = a

-- The main theorem: under a strict descent successor on a finite set,
-- every orbit terminates at a fixed point.
theorem orbit_terminates_at_fixed_point (succ : α → α) (h : StrictDescent succ) (start : α) :
    ∃ (n : ℕ), isFixedPoint succ (orbit succ start n) := by
  -- Define a measure function from the descent condition
  rcases h.desc start (by
    intro H
    have := h.strict start H
    simp [H] at this) with ⟨f, hf⟩
  -- But we need a measure for all points, not just start
  -- Instead, use the finiteness of α to get a well-founded measure
  have : WellFounded (InvImage (· < · : ℕ → ℕ → Prop) f) :=
    InvImage.wf f (by infer_instance : WellFounded LT.lt)
  -- Define relation: a ≺ b if succ b = a and succ a ≠ a
  let r : α → α → Prop := λ a b => succ b = a ∧ succ a ≠ a
  have hwf : WellFounded r := by
    apply Subrelation.wf (λ x y hxy => ?_) this
    rcases hxy with ⟨hsucc, hneq⟩
    have := h.desc x hneq
    rcases this with ⟨g, hg⟩
    exact hg
  -- Now show that iterating succ must reach a fixed point
  refine WellFounded.induction hwf start (λ x ih => ?_)
  by_cases hx : succ x = x
  · -- x is already a fixed point
    refine ⟨0, ?_⟩
    simp [orbit, isFixedPoint, hx]
  · -- x is not a fixed point
    have hstep : r (succ x) x := ⟨rfl, hx⟩
    rcases ih (succ x) hstep with ⟨n, hn⟩
    refine ⟨n + 1, ?_⟩
    simp [orbit, hn]
