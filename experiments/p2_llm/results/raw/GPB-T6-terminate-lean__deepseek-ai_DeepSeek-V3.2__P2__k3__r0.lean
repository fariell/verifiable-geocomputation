import Mathlib.Tactic

variable {α : Type} [Fintype α] [DecidableEq α]

structure StrictDescent (succ : α → α) : Prop where
  descent : ∀ a, succ a = a ∨ (succ a) ≠ a ∧ Fintype.card {x | succ x = succ a} < Fintype.card {x | succ x = a}

theorem termination_of_strict_descent (succ : α → α) (h : StrictDescent succ) :
    ∀ a, ∃ n, (succ^[n] a) = (succ^[n+1] a) := by
  intro a
  have : WellFounded (InvImage (· < ·) (λ x => Fintype.card {y | succ y = x})) :=
    InvImage.wf (λ x => Fintype.card {y | succ y = x}) (by
      apply IsWellFounded.wf)
  refine WellFounded.induction this (Fintype.card {y | succ y = a}) (by
    intro m IH
    by_cases hm : succ a = a
    · refine ⟨0, ?_⟩
      simp [hm]
    · have hdesc := h.descent a
      rcases hdesc with (ha | ⟨hne, hlt⟩)
      · exfalso; exact hm ha
      · have := IH (Fintype.card {y | succ y = succ a}) hlt (succ a)
        rcases this with ⟨n, hn⟩
        refine ⟨n+1, ?_⟩
        simp [Function.iterate_succ_apply', hn])
    ?_)
  exact ⟨a, rfl⟩
