import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Nat.Basic
import Mathlib.Order.WellFounded

section

variable {α : Type} [Fintype α] (succ : α → α)

/-- A strict descent relation: `succ a = b` implies `b` is strictly less than `a`
    according to some measure `μ : α → ℕ`. -/
structure StrictDescent (μ : α → ℕ) : Prop where
  desc : ∀ a, μ (succ a) < μ a

/-- The orbit of `a` under `succ`, as a sequence. -/
def orbit (a : α) : ℕ → α :=
  λ n => Nat.recOn n a (λ _ x => succ x)

/-- A fixed point of `succ`. -/
def IsFixedPoint (a : α) : Prop :=
  succ a = a

/-- Termination of the orbit: there exists `n` such that all later steps are fixed. -/
def terminates (a : α) : Prop :=
  ∃ n, ∀ m, n ≤ m → IsFixedPoint (orbit a m)

theorem termination_under_strict_descent (μ : α → ℕ) (h : StrictDescent succ μ) (a : α) :
    terminates succ a := by
  -- The measure gives a well-founded decreasing sequence
  have hwf : WellFounded (λ (x y : α) => μ x < μ y) :=
    WellFounded.wellFounded_lt
  -- Define the sequence of measures along the orbit
  let μ_seq (n : ℕ) : ℕ := μ (orbit succ a n)
  have h_decr : ∀ n, μ_seq (n + 1) < μ_seq n := by
    intro n
    simp [μ_seq, orbit]
    exact h.desc (orbit succ a n)
  -- Since ℕ is well‑founded, this decreasing sequence must stabilize
  obtain ⟨n, hn⟩ := WellFounded.not_lt_min (WellFounded.wellFounded_lt) (Set.range μ_seq) ⟨μ_seq 0, 0, rfl⟩
  refine ⟨n, λ m hm => ?_⟩
  -- Show that from n onward, the orbit is constant
  have : orbit succ a n = orbit succ a m := by
    induction' hm with k hle ih
    · rfl
    · have := h_decr (n + k)
      exfalso
      exact Nat.lt_asymm this (hn ⟨μ_seq (n + k + 1), n + k + 1, rfl⟩ (by omega))
  simp [IsFixedPoint, this]

end
