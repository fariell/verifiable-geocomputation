import Mathlib.Tactic

variable {Cell : Type} [Fintype Cell] [DecidableEq Cell]
variable (succ : Cell → Cell)

structure StrictDescent : Prop where
  descent : ∀ c, succ c = c ∨ (succ c) ≠ c

theorem termination_of_strict_descent (h : StrictDescent succ) :
    ∀ (c : Cell), ∃ (n : ℕ), (fun x => succ x)^[n] c = (fun x => succ x)^[n + 1] c := by
  intro c
  have : WellFounded (InvImage (· < ·) (fun (c : Cell) => Fintype.card Cell - Fintype.card {x | x = c})) :=
    InvImage.wf (fun c => Fintype.card Cell - Fintype.card {x | x = c}) (by
      apply Nat.lt_wfRel)
  refine WellFounded.fix this (fun c ih => ?_) c
  by_cases hc : succ c = c
  · refine ⟨0, ?_⟩
    simp [hc]
  · have : Fintype.card Cell - Fintype.card {x | x = succ c} <
          Fintype.card Cell - Fintype.card {x | x = c} := by
      have hcard : Fintype.card {x | x = succ c} = 1 := by
        simp [Fintype.card_subtype_compl, Fintype.card_finset]
      have hcard' : Fintype.card {x | x = c} = 1 := by
        simp [Fintype.card_subtype_compl, Fintype.card_finset]
      simp [hcard, hcard']
    rcases ih (succ c) this with ⟨n, hn⟩
    refine ⟨n + 1, ?_⟩
    simp [Function.iterate_succ_apply', hn]
