import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Nat.Basic
import Mathlib.Logic.Relation

section

variable {α : Type} [Fintype α] (succ : α → α)

/-- A strict descent relation: `succ a = b` and `b ≠ a`. -/
def StrictDescent (a b : α) : Prop := succ a = b ∧ b ≠ a

/-- A fixed point of `succ`. -/
def IsFixedPoint (a : α) : Prop := succ a = a

/-- The orbit of `a` under `succ`. -/
def orbit (a : α) : ℕ → α
  | 0 => a
  | n + 1 => succ (orbit a n)

/-- The orbit terminates at a fixed point if it eventually reaches a fixed point. -/
def TerminatesAtFixedPoint (a : α) : Prop :=
  ∃ n : ℕ, IsFixedPoint succ (orbit a n) ∧ ∀ m < n, ¬ IsFixedPoint succ (orbit a m)

/-- A measure that strictly decreases under strict descent. -/
def descentMeasure (a : α) : ℕ :=
  Fintype.card α - Fintype.card {x | ∃ k : ℕ, orbit a k = x}

theorem descentMeasure_decreases {a : α} (h : StrictDescent succ a (succ a)) :
    descentMeasure succ (succ a) < descentMeasure succ a := by
  unfold descentMeasure
  have hcard : Fintype.card {x | ∃ k : ℕ, orbit (succ a) k = x} ≤ Fintype.card {x | ∃ k : ℕ, orbit a k = x} := by
    refine Fintype.card_le_univ_of_surjective ?_
    intro x
    rcases x with ⟨x, ⟨k, hk⟩⟩
    refine ⟨⟨x, ⟨k + 1, ?_⟩⟩, Subtype.ext hk⟩
    simp [orbit, hk]
  have hstrict : Fintype.card {x | ∃ k : ℕ, orbit a k = x} < Fintype.card α := by
    refine lt_of_le_of_ne ?_ ?_
    · exact Fintype.card_le_univ
    · intro hcard_eq
      have : ∀ x : α, ∃ k : ℕ, orbit a k = x := by
        intro x
        have := Fintype.card_congr (Equiv.subtypeUnivEquiv (by intro x; exact ⟨fun ⟨k, hk⟩ => hk ▸ mem_univ x, fun _ => ⟨0, rfl⟩⟩))
        simp_rw [Fintype.card_subtype, Fintype.card_fin] at hcard_eq
        exact Fintype.complete x
      have hfixed : IsFixedPoint succ a := by
        have := this (succ a)
        rcases this with ⟨k, hk⟩
        induction' k with k ih
        · simp [orbit] at hk
          exact hk.symm
        · simp [orbit] at hk
          rw [hk] at ih
          exact ih
      rcases h with ⟨hsucc, hne⟩
      apply hne
      rw [← hsucc, hfixed]
  omega

theorem termination_of_strict_descent (hdesc : ∀ a, succ a ≠ a → StrictDescent succ a (succ a)) :
    ∀ a, TerminatesAtFixedPoint succ a := by
  intro a
  by_cases hfixed : IsFixedPoint succ a
  · refine ⟨0, hfixed, by intro m hm; exfalso; omega⟩
  · have hstrict : StrictDescent succ a (succ a) := hdesc a (by
      intro h
      apply hfixed
      exact h)
    have : descentMeasure succ (succ a) < descentMeasure succ a :=
      descentMeasure_decreases succ hstrict
    have IH := termination_of_strict_descent hdesc (succ a)
    rcases IH with ⟨n, hn_fixed, hn_min⟩
    refine ⟨n + 1, hn_fixed, ?_⟩
    intro m hm
    rcases Nat.lt_succ_iff_lt_or_eq.mp hm with (hm' | rfl)
    · exact hn_min m hm'
    · exact hfixed

end
