import Mathlib.Data.Stream.Defs
import Mathlib.Data.Stream.Init
import Mathlib.Data.Nat.Basic
import Mathlib.Order.Basic

namespace Fill1D

/-- A 1D digital elevation model as a function from indices to elevations. -/
abbrev DEM (α : Type) [Preorder α] := ℕ → α

/-- The left-outlet fill operator for 1D DEMs.
    For each position i, the fill value is the maximum of the original elevation at i
    and the fill value at the previous position (i-1).
    At position 0, the fill value is just the original elevation. -/
def fill {α : Type} [Preorder α] (a : DEM α) : DEM α :=
  λ i => Nat.recOn i (a 0) (λ n prev => max (a (n + 1)) prev)

/-- The property that a sequence is nondecreasing: for all i, s i ≤ s (i+1). -/
def Nondecreasing {α : Type} [Preorder α] (s : DEM α) : Prop :=
  ∀ i, s i ≤ s (i + 1)

/-- Theorem: The 1D left-outlet fill operator yields a nondecreasing sequence. -/
theorem fill_nondecreasing {α : Type} [Preorder α] (a : DEM α) : Nondecreasing (fill a) := by
  intro i
  unfold fill
  induction' i with k IH
  · -- Base case: i = 0
    simp [fill]
    have h : a 0 ≤ max (a 1) (a 0) := le_max_right (a 1) (a 0)
    exact h
  · -- Inductive step: i = k + 1
    simp [fill]
    have h1 : max (a (k + 1)) (Nat.rec (a 0) (λ n prev => max (a (n + 1)) prev) k) ≤ 
              max (a (k + 2)) (max (a (k + 1)) (Nat.rec (a 0) (λ n prev => max (a (n + 1)) prev) k)) :=
      le_max_right (a (k + 2)) (max (a (k + 1)) (Nat.rec (a 0) (λ n prev => max (a (n + 1)) prev) k))
    have h2 : max (a (k + 1)) (Nat.rec (a 0) (λ n prev => max (a (n + 1)) prev) k) = 
              Nat.rec (a 0) (λ n prev => max (a (n + 1)) prev) (k + 1) := by
      simp [fill]
    rw [h2] at h1
    exact h1

end Fill1D
