import Mathlib.Tactic

variable {α : Type} [Fintype α] [DecidableEq α]

structure StrictDescent (succ : α → α) : Prop where
  descent : ∀ a, succ a = a ∨ (succ a) ≠ a ∧ ∃ (f : α → Nat), f (succ a) < f a

theorem terminates_at_fixed_point (succ : α → α) (h : StrictDescent succ) :
    ∀ a, ∃ n, (succ^[n] a) = (succ^[n+1] a) := by
  intro a
  have : WellFounded (InvImage (· < ·) (h.descent a).choose_spec.2.choose) :=
    ⟨by
      intro x
      apply Acc.intro
      intro y hlt
      exact Acc.intro y (fun z hz => (Nat.lt_trans hz hlt).not_lt (Nat.lt_irrefl _))⟩
  refine WellFounded.fix this (fun n IH => ?_) 0
  cases' h.descent (succ^[n] a) with heq hdesc
  · exact ⟨n, heq⟩
  · have hlt : h.descent a).choose_spec.2.choose (succ^[n+1] a) <
      (h.descent a).choose_spec.2.choose (succ^[n] a) := by
      simpa [Function.iterate_succ'] using hdesc.2.2
    obtain ⟨k, hk⟩ := IH (n+1) hlt
    exact ⟨k, hk⟩
