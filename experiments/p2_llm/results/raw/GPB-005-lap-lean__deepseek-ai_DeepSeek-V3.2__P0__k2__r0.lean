import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

-- A 3x3 window of elevations
structure Window where
  a : ℝ  -- top-left
  b : ℝ  -- top-center
  c : ℝ  -- top-right
  d : ℝ  -- middle-left
  e : ℝ  -- center
  f : ℝ  -- middle-right
  g : ℝ  -- bottom-left
  h : ℝ  -- bottom-center
  i : ℝ  -- bottom-right

namespace Window

-- Orthogonal neighbors of the center cell
def orthogonalNeighbors (w : Window) : List ℝ :=
  [w.b, w.d, w.f, w.h]

-- Discrete local maximum condition: center ≥ each orthogonal neighbor
def isLocalMax (w : Window) : Prop :=
  w.e ≥ w.b ∧ w.e ≥ w.d ∧ w.e ≥ w.f ∧ w.e ≥ w.h

-- Discrete Laplacian at the center (using the standard 5-point stencil)
def laplacian (w : Window) : ℝ :=
  (w.b + w.d + w.f + w.h) - 4 * w.e

-- The theorem: if center is a discrete local maximum, then Laplacian ≤ 0
theorem local_max_implies_nonpositive_laplacian (w : Window) :
    isLocalMax w → laplacian w ≤ 0 := by
  intro hmax
  unfold isLocalMax at hmax
  rcases hmax with ⟨heb, hed, hef, heh⟩
  unfold laplacian
  have h1 : w.b ≤ w.e := heb
  have h2 : w.d ≤ w.e := hed
  have h3 : w.f ≤ w.e := hef
  have h4 : w.h ≤ w.e := heh
  linarith

end Window
