import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Fin.VecNotation

open Matrix

-- Represent a planar DEM: z = A x + B y + C
structure DEM : Type where
  A : ℝ
  B : ℝ
  C : ℝ

-- Grid coordinates (integer indices)
abbrev GridCoord := ℤ × ℤ

-- D8 flow direction as an integer from 1 to 8 (or 0 for no flow)
abbrev Direction := Fin 9

-- Slope must be positive: A > 0 or B > 0 (or both)
def DEM.positive_slope (d : DEM) : Prop := d.A > 0 ∨ d.B > 0

-- Elevation at a grid cell for a given DEM
def elevation (d : DEM) (x y : ℤ) : ℝ := d.A * (x : ℝ) + d.B * (y : ℝ) + d.C

-- D8 flow direction calculation (simplified interior case)
-- For interior cells, we compare elevation with the 8 neighbors.
-- Here we define a deterministic rule: choose the steepest descent among the 8 neighbors.
-- If multiple have same steepest descent, pick the smallest direction index.
-- If no descent, direction is 0.
def direction_to_neighbor (dx dy : ℤ) : Option Direction :=
  match dx, dy with
  | (-1), (-1) => some ⟨1, by decide⟩
  | 0, (-1)    => some ⟨2, by decide⟩
  | 1, (-1)    => some ⟨3, by decide⟩
  | (-1), 0    => some ⟨4, by decide⟩
  | 1, 0       => some ⟨5, by decide⟩
  | (-1), 1    => some ⟨6, by decide⟩
  | 0, 1       => some ⟨7, by decide⟩
  | 1, 1       => some ⟨8, by decide⟩
  | _, _       => none

-- List of all 8 neighbor offsets
def neighbor_offsets : List (ℤ × ℤ) :=
  [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]

-- Compute D8 flow direction for a cell at (x, y) given DEM d
def flow_direction (d : DEM) (x y : ℤ) : Direction :=
  let neighbors := neighbor_offsets.filterMap fun (dx, dy) =>
        direction_to_neighbor dx dy |>.map fun dir =>
          (dir, elevation d (x + dx) (y + dy))
  let current := elevation d x y
  let descending := neighbors.filter fun (_, h) => h < current
  if h : descending.isEmpty then
    ⟨0, by decide⟩
  else
    let (dir, _) := descending.minBy (fun (_, h) => h) (by simp [descending, h])
    dir

-- The main theorem: translating C does not change flow direction for interior cells
-- when slope is positive.
theorem direction_independent_of_C (d : DEM) (hpos : d.positive_slope) (x y : ℤ) :
    ∀ C' : ℝ, flow_direction d x y = flow_direction { d with C := C' } x y := by
  intro C'
  unfold flow_direction
  simp [elevation]
  congr
  ext ⟨dx, dy⟩
  simp [elevation]
  ring
