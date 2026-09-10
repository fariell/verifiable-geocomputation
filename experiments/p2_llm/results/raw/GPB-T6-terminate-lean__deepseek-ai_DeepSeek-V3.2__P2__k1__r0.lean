import Mathlib.Tactic

variable {Cell : Type} [Fintype Cell] [DecidableEq Cell]
variable (succ : Cell → Cell)

structure StrictDescent : Prop where
  descent : ∀ c, succ c = c ∨ (succ c) ≠ c

theorem termination_of_strict_descent (h : StrictDescent succ) :
    ∀ (c : Cell), ∃ (n : ℕ), (fun x => succ x)^[n] c = (fun x => succ x)^[n + 1] c := by
  intro c
  have : WellFounded (InvImage (· < ·) (fun (c : Cell) => Fintype.card Cell - Fintype.card {x | x = succ c})) :=
    InvImage.wf (fun c => Fintype.card Cell - Fintype.card {x | x = succ c}) (by
      apply Nat.lt_wfRel)
  refine WellFounded.induction this c ?_
  intro c ih
  by_cases hc : succ c = c
  · refine ⟨0, ?_⟩
    simp [hc]
  · have hdesc : succ (succ c) ≠ succ c ∨ succ (succ c) = succ c := by
      cases' h.descent (succ c) with h_eq h_neq
      · right; exact h_eq
      · left; exact h_neq
    cases' hdesc with hneq heq
    · have : (fun x => succ x)^[1] c = succ c := by simp
      rw [this]
      have card_lt : Fintype.card Cell - Fintype.card {x | x = succ (succ c)} <
                     Fintype.card Cell - Fintype.card {x | x = succ c} := by
        have hsub : {x | x = succ c} ⊆ {x | x = succ (succ c)} := by
          intro x hx
          simp at hx ⊢
          rw [hx]
          exact hneq
        have : Fintype.card {x | x = succ c} < Fintype.card {x | x = succ (succ c)} :=
          Fintype.card_lt_card_of_subset hsub (by
            intro h
            have : succ c = succ (succ c) := by
              apply Fintype.card_le_one_iff_subsingleton.mp ?_ (succ c) (succ (succ c))
              exact le_of_eq h.symm
            exact hneq this)
        omega
      obtain ⟨n, hn⟩ := ih (succ c) this
      refine ⟨n + 1, ?_⟩
      simp [Function.iterate_succ_apply', hn]
    · refine ⟨1, ?_⟩
      simp [heq]
