import Mathlib.Data.Nat.Basic
import Mathlib.Logic.Function.Iterate

variable {Cell : Type} (succ : Cell → Cell) (h : Cell → ℕ)
  (strict_descent : ∀ c, succ c ≠ c → h (succ c) < h c)

theorem terminates_at_fixed_point (c : Cell) :
    ∃ (n : ℕ) (c' : Cell), (succ^[n] c) = c' ∧ succ c' = c' := by
  apply Nat.strongInductionOn (h c)
  intro k ih
  by_cases hc : succ c = c
  · use 0, c
    simp [hc]
  · have step : h (succ c) < h c := strict_descent c hc
    obtain ⟨n, c', h_iter, h_fixed⟩ := ih (h (succ c)) step (succ c)
    use n + 1, c'
    constructor
    · rw [Function.iterate_succ_apply, h_iter]
    · exact h_fixed
