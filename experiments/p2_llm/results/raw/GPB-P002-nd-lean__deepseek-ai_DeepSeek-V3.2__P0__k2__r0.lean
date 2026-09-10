import Mathlib.Data.Stream.Defs
import Mathlib.Data.Nat.Basic
import Mathlib.Order.Basic

namespace Fill1D

/-- A 1D array of values with a left outlet (index 0 is the outlet). -/
abbrev Array1D (α : Type) := Nat → α

/-- The left-outlet fill operator for 1D arrays.
    For each position i, the fill value is the maximum of all original values from the outlet up to i. -/
def fill (a : Array1D ℕ) : Array1D ℕ :=
  λ i => (Finset.range (i + 1)).sup' ⟨i, by simp⟩ a

/-- The property that a sequence is nondecreasing: for all i, x[i] ≤ x[i+1]. -/
def Nondecreasing (x : Array1D ℕ) : Prop :=
  ∀ i, x i ≤ x (i + 1)

/-- Theorem: The 1D left-outlet fill yields a nondecreasing sequence. -/
theorem fill_nondecreasing (a : Array1D ℕ) : Nondecreasing (fill a) := by
  intro i
  unfold fill
  have h1 : (Finset.range (i + 1)).sup' ⟨i, by simp⟩ a ≤ (Finset.range (i + 2)).sup' ⟨i + 1, by simp⟩ a := by
    apply Finset.sup'_le_sup' _ (by intro x hx; simp [Finset.mem_range] at hx; omega)
    intro x hx
    simp [Finset.mem_range] at hx
    have : x ≤ i + 1 := by omega
    exact Finset.mem_range_succ_iff.mpr this
  exact h1

end Fill1D
