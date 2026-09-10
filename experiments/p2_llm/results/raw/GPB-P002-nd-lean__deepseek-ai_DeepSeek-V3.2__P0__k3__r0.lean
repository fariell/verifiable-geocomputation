import Mathlib.Data.Stream.Defs
import Mathlib.Data.Stream.Init
import Mathlib.Data.Nat.Basic
import Mathlib.Order.Basic

namespace Fill1D

/-- The 1D left-outlet Fill operator as a stream transformer.
    For each position i, Fill(a)[i] = max(a[i], Fill(a)[i-1]) with Fill(a)[-1] = -∞.
    We implement it as a stream `Stream' ℕ ℤ` for simplicity (ℤ allows negative values). -/
def Fill (a : Stream' ℕ ℤ) : Stream' ℕ ℤ :=
  Stream'.scanl (λ prev i => max prev (a.get i)) (-∞) a

/-- The property that a sequence is nondecreasing: for all i, s[i] ≤ s[i+1]. -/
def Nondecreasing (s : Stream' ℕ ℤ) : Prop :=
  ∀ i : ℕ, s.get i ≤ s.get (i+1)

/-- Theorem: The 1D left-outlet Fill operator yields a nondecreasing sequence. -/
theorem fill_nondecreasing (a : Stream' ℕ ℤ) : Nondecreasing (Fill a) := by
  intro i
  unfold Fill
  unfold Nondecreasing
  -- We need to show: (scanl f init a)[i] ≤ (scanl f init a)[i+1]
  -- where f prev idx = max prev (a.get idx) and init = -∞
  let f := λ (prev : ℤ) (idx : ℕ) => max prev (a.get idx)
  have h_scanl_succ : ∀ n : ℕ, (Stream'.scanl f (-∞) a).get (n+1) =
      f ((Stream'.scanl f (-∞) a).get n) n := by
    intro n
    rw [Stream'.scanl_succ]
  rw [h_scanl_succ i]
  -- Now we have: (Fill a)[i+1] = max ((Fill a)[i]) (a.get i)
  -- So we need: (Fill a)[i] ≤ max ((Fill a)[i]) (a.get i)
  -- This holds by `le_max_left`.
  exact le_max_left _ (a.get i)

end Fill1D
