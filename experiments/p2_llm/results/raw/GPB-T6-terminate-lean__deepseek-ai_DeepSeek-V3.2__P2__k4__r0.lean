import Mathlib.Tactic

variable {α : Type} [Fintype α] [DecidableEq α] (succ : α → α)

structure StrictDescent : Prop where
  descent : ∀ a, succ a = a ∨ (succ a) ≠ a ∧ Fintype.card {x // succ x = succ a} < Fintype.card {x // succ x = a}

theorem terminates_at_fixed_point (h : StrictDescent succ) : ∀ a, ∃ n, (fun x => succ x)^[n] a = (fun x => succ x)^[n+1] a := by
  intro a
  have hwf : WellFounded (InvImage (· < ·) (fun x : α => Fintype.card {y // succ y = x})) := by
    apply InvImage.wf
    exact Nat.lt_wfRel
  induction' hwf using WellFounded.induction with x IH
  dsimp [InvImage] at IH
  by_cases hx : succ x = x
  · refine ⟨0, ?_⟩
    simp [hx]
  · have hdesc := h.descent x
    rcases hdesc with (rfl | ⟨hne, hlt⟩)
    · exfalso; exact hx rfl
    · rcases IH (succ x) hlt with ⟨n, hn⟩
      refine ⟨n+1, ?_⟩
      simp [Function.iterate_succ_apply', hn]
