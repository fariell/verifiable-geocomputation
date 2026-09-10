import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

open Matrix

-- A 3×3 window of elevations (real numbers)
structure Window3x3 where
  a : ℝ  -- top-left
  b : ℝ  -- top-center
  c : ℝ  -- top-right
  d : ℝ  -- middle-left
  e : ℝ  -- center
  f : ℝ  -- middle-right
  g : ℝ  -- bottom-left
  h : ℝ  -- bottom-center
  i : ℝ  -- bottom-right

namespace Window3x3

-- Orthogonal neighbors of the center cell
def orthogonalNeighbors (w : Window3x3) : List ℝ :=
  [w.b, w.d, w.f, w.h]

-- Discrete local maximum condition: center ≥ each orthogonal neighbor
def isLocalMax (w : Window3x3) : Prop :=
  ∀ x ∈ w.orthogonalNeighbors, w.e ≥ x

-- Discrete Laplacian (using the standard 4-neighbor stencil)
-- Δe = (b + d + f + h) - 4*e
def laplacian (w : Window3x3) : ℝ :=
  (w.b + w.d + w.f + w.h) - 4 * w.e

-- The theorem: if center is a discrete local max, then Laplacian ≤ 0
theorem local_max_implies_nonpositive_laplacian (w : Window3x3) :
    w.isLocalMax → w.laplacian ≤ 0 := by
  intro hmax
  -- Expand the local max condition for each neighbor
  have hb : w.e ≥ w.b := hmax w.b (by simp [orthogonalNeighbors])
  have hd : w.e ≥ w.d := hmax w.d (by simp [orthogonalNeighbors])
  have hf : w.e ≥ w.f := hmax w.f (by simp [orthogonalNeighbors])
  have hh : w.e ≥ w.h := hmax w.h (by simp [orthogonalNeighbors])
  -- Compute Laplacian
  calc
    w.laplacian = (w.b + w.d + w.f + w.h) - 4 * w.e := rfl
    _ ≤ (w.e + w.e + w.e + w.e) - 4 * w.e := by
      -- Each neighbor ≤ center
      have hsum : w.b + w.d + w.f + w.h ≤ w.e + w.e + w.e + w.e := by
        linarith
      linarith
    _ = 0 := by ring

end Window3x3
