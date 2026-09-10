Here is a complete Lean source file that formalizes and proves the stated property:

```lean
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

namespace DiscreteDEM

-- A 3x3 window of elevations (real numbers)
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
def orthogonal_neighbors (w : Window3x3) : List ℝ :=
  [w.b, w.d, w.f, w.h]

-- Center is a discrete local maximum (≥ each orthogonal neighbor)
def is_local_max (w : Window3x3) : Prop :=
  w.e ≥ w.b ∧ w.e ≥ w.d ∧ w.e ≥ w.f ∧ w.e ≥ w.h

-- Discrete Laplacian at center (using 4-connectivity)
def laplacian (w : Window3x3) : ℝ :=
  (w.b + w.d + w.f + w.h) - 4 * w.e

-- The theorem: if center is a discrete local maximum, then Laplacian ≤ 0
theorem local_max_implies_nonpositive_laplacian (w : Window3x3) :
    is_local_max w → laplacian w ≤ 0 := by
  intro hmax
  unfold is_local_max at hmax
  rcases hmax with ⟨heb, hed, hef, heh⟩
  unfold laplacian
  have h1 : w.b ≤ w.e := heb
  have h2 : w.d ≤ w.e := hed
  have h3 : w.f ≤ w.e := hef
  have h4 : w.h ≤ w.e := heh
  linarith

end Window3x3

-- Alternative formulation using matrices for grid context
section GridFormulation

variable {m n : ℕ} (grid : Matrix (Fin m) (Fin n) ℝ)

-- Get a 3x3 window centered at (i,j), with boundary handling
def get_window (grid : Matrix (Fin m) (Fin n) ℝ) (i : Fin m) (j : Fin n) : Option Window3x3 :=
  if hi : 0 < (i : ℕ) ∧ (i : ℕ) + 1 < m ∧ 0 < (j : ℕ) ∧ (j : ℕ) + 1 < n then
    let i' : ℕ := i.val
    let j' : ℕ := j.val
    some {
      a := grid ⟨i' - 1, by omega⟩ ⟨j' - 1, by omega⟩
      b := grid ⟨i' - 1, by omega⟩ j
      c := grid ⟨i' - 1, by omega⟩ ⟨j' + 1, by omega⟩
      d := grid i ⟨j' - 1, by omega⟩
      e := grid i j
      f := grid i ⟨j' + 1, by omega⟩
      g := grid ⟨i' + 1, by omega⟩ ⟨j' - 1, by omega⟩
      h := grid ⟨i' + 1, by omega⟩ j
      i := grid ⟨i' + 1, by omega⟩ ⟨j' + 1, by omega⟩
    }
  else
    none

-- Theorem for valid interior points
theorem grid_local_max_implies_nonpositive_laplacian
    (grid : Matrix (Fin m) (Fin n) ℝ) (i : Fin m) (j : Fin n)
    (hwindow : get_window grid i j = some w) (hmax : Window3x3.is_local_max w) :
    Window3x3.laplacian w ≤ 0 :=
  Window3x3.local_max_implies_nonpositive_laplacian w hmax

end GridFormulation

end DiscreteDEM
```
