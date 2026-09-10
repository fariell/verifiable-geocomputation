import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

-- Representing a planar DEM: z = A*x + B*y + C
structure DEM : Type where
  A : ℝ
  B : ℝ
  C : ℝ

-- Grid cell coordinates
structure Cell : Type where
  x : ℤ
  y : ℤ

-- D8 flow direction as an integer from 1 to 8 (or 0 for no flow)
inductive D8Direction : Type
  | E : D8Direction
  | NE : D8Direction
  | N : D8Direction
  | NW : D8Direction
  | W : D8Direction
  | SW : D8Direction
  | S : D8Direction
  | SE : D8Direction
  deriving DecidableEq

open D8Direction

-- Slope positivity condition: at least one of A, B is positive
def positive_slope (dem : DEM) : Prop :=
  dem.A > 0 ∨ dem.B > 0

-- Elevation at a cell for a given DEM
def elevation (dem : DEM) (cell : Cell) : ℝ :=
  dem.A * (cell.x : ℝ) + dem.B * (cell.y : ℝ) + dem.C

-- Neighbor offsets for D8 (including diagonals)
def neighbor_offsets : List (ℤ × ℤ) :=
  [(1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1), (0,-1), (1,-1)]

-- Map offset to D8 direction
def offset_to_direction : (ℤ × ℤ) → D8Direction
  | (1,0) => E
  | (1,1) => NE
  | (0,1) => N
  | (-1,1) => NW
  | (-1,0) => W
  | (-1,-1) => SW
  | (0,-1) => S
  | (1,-1) => SE
  | _ => E -- default case (should not happen with our list)

-- Compute steepest descent direction among D8 neighbors
def flow_direction (dem : DEM) (cell : Cell) : D8Direction :=
  let z0 := elevation dem cell
  let candidates := neighbor_offsets.map fun (dx, dy) =>
    let nb := { x := cell.x + dx, y := cell.y + dy : Cell }
    let z1 := elevation dem nb
    (z0 - z1, offset_to_direction (dx, dy))
  -- Find maximum drop (steepest descent)
  match candidates.maximum? (λ a b => a.1 < b.1) with
  | some (_, dir) => dir
  | none => E -- default if no neighbors (should not happen)

-- The main theorem: interior cells with same (A,B) and positive slope
-- have constant flow direction, independent of C.
theorem constant_flow_direction_for_planar_DEM
    (A B : ℝ) (hpos : A > 0 ∨ B > 0)
    (C1 C2 : ℝ)
    (cell1 cell2 : Cell) :
    flow_direction { A := A, B := B, C := C1 } cell1 =
    flow_direction { A := A, B := B, C := C2 } cell2 := by
  -- Unfold definitions
  unfold flow_direction elevation
  simp only
  -- The key observation: elevation difference between a cell and its neighbor
  -- is independent of C because C cancels out.
  have h_diff : ∀ (dx dy : ℤ) (cell : Cell) (C : ℝ),
      ({ A := A, B := B, C := C1 : DEM }.A * (cell.x : ℝ) + { A := A, B := B, C := C1 : DEM }.B * (cell.y : ℝ) + { A := A, B := B, C := C1 : DEM }.C) -
      ({ A := A, B := B, C := C1 : DEM }.A * ((cell.x + dx) : ℝ) + { A := A, B := B, C := C1 : DEM }.B * ((cell.y + dy) : ℝ) + { A := A, B := B, C := C1 : DEM }.C) =
      ({ A := A, B := B, C := C2 : DEM }.A * (cell.x : ℝ) + { A := A, B := B, C := C2 : DEM }.B * (cell.y : ℝ) + { A := A, B := B, C := C2 : DEM }.C) -
      ({ A := A, B := B, C := C2 : DEM }.A * ((cell.x + dx) : ℝ) + { A := A, B := B, C := C2 : DEM }.B * ((cell.y + dy) : ℝ) + { A := A, B := B, C := C2 : DEM }.C) := by
    intro dx dy cell C
    ring
  -- Therefore, the list of (drop, direction) pairs is identical for both DEMs.
  -- So the chosen direction (maximum drop) will be the same.
  congr
  ext ⟨dx, dy⟩
  simp [h_diff dx dy cell1, h_diff dx dy cell2]
