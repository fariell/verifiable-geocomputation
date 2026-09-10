import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

/-
  If the center cell of a 3x3 window is a discrete local maximum 
  (center elevation ≥ each of the four orthogonal neighbors), 
  then the discrete Laplacian at the center is ≤ 0.
-/

section DiscreteMaximumLaplacian

variable {R : Type} [LinearOrderedRing R] [TopologicalRing R]

/-- A 3×3 window of elevations. -/
structure Window3x3 (R : Type) where
  a : R  -- NW
  b : R  -- N
  c : R  -- NE
  d : R  -- W
  e : R  -- center
  f : R  -- E
  g : R  -- SW
  h : R  -- S
  i : R  -- SE

namespace Window3x3

/-- The four orthogonal neighbors of the center. -/
def orthogonal_neighbors (w : Window3x3 R) : R × R × R × R :=
  (w.b, w.d, w.f, w.h)

/-- Center is a discrete local maximum: ≥ each orthogonal neighbor. -/
def is_local_max (w : Window3x3 R) : Prop :=
  w.e ≥ w.b ∧ w.e ≥ w.d ∧ w.e ≥ w.f ∧ w.e ≥ w.h

/-- Discrete Laplacian (5-point stencil) at the center. -/
def laplacian (w : Window3x3 R) : R :=
  (w.b + w.d + w.f + w.h) - 4 * w.e

theorem local_max_implies_nonpositive_laplacian (w : Window3x3 R) :
    w.is_local_max → w.laplacian ≤ 0 := by
  intro hmax
  rcases hmax with ⟨hN, hW, hE, hS⟩
  unfold laplacian
  have h1 : w.b ≤ w.e := hN
  have h2 : w.d ≤ w.e := hW
  have h3 : w.f ≤ w.e := hE
  have h4 : w.h ≤ w.e := hS
  have sum_le : w.b + w.d + w.f + w.h ≤ 4 * w.e := by
    linarith
  linarith

end Window3x3

end DiscreteMaximumLaplacian
