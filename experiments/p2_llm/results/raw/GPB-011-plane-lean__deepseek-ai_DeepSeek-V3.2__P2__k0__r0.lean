import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

-- Represent a planar DEM: z = A x + B y + C
structure DEM : Type where
  A : ℝ
  B : ℝ
  C : ℝ

-- Grid cell coordinates
structure Cell : Type where
  x : ℤ
  y : ℤ

-- D8 flow direction as an angle in degrees (simplified to integer for this example)
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

-- Slope positivity condition: A > 0 and B > 0
def positive_slope (dem : DEM) : Prop := dem.A > 0 ∧ dem.B > 0

-- Elevation at a cell for a given DEM
def elevation (dem : DEM) (cell : Cell) : ℝ :=
  dem.A * (cell.x : ℝ) + dem.B * (cell.y : ℝ) + dem.C

-- D8 flow direction from a cell to its steepest downward neighbor
-- Simplified: compare elevations of the 8 neighboring cells
def d8_direction (dem : DEM) (cell : Cell) : D8Direction :=
  let neighbors : List (Cell × D8Direction) :=
    [ (Cell.mk (cell.x + 1) cell.y, D8Direction.E),
      (Cell.mk (cell.x + 1) (cell.y + 1), D8Direction.NE),
      (Cell.mk cell.x (cell.y + 1), D8Direction.N),
      (Cell.mk (cell.x - 1) (cell.y + 1), D8Direction.NW),
      (Cell.mk (cell.x - 1) cell.y, D8Direction.W),
      (Cell.mk (cell.x - 1) (cell.y - 1), D8Direction.SW),
      (Cell.mk cell.x (cell.y - 1), D8Direction.S),
      (Cell.mk (cell.x + 1) (cell.y - 1), D8Direction.SE) ]
  let current_z := elevation dem cell
  let candidates := neighbors.filter (λ (nb, _) => elevation dem nb < current_z)
  if candidates.isEmpty then D8Direction.E  -- default if no lower neighbor
  else
    let steepest := candidates.minimum? (λ (nb1, _) (nb2, _) =>
      elevation dem nb1 ≤ elevation dem nb2)
    match steepest with
    | some (_, dir) => dir
    | none => D8Direction.E

-- Theorem: For a DEM with positive slope, D8 direction is invariant under translation of C
theorem d8_invariant_under_translation (dem : DEM) (hpos : positive_slope dem) (cell : Cell) :
    ∀ (ΔC : ℝ), d8_direction { dem with C := dem.C + ΔC } cell = d8_direction dem cell := by
  intro ΔC
  unfold d8_direction
  have h_elev_shift : ∀ (c : Cell), elevation { dem with C := dem.C + ΔC } c = elevation dem c + ΔC := by
    intro c
    unfold elevation
    simp [add_assoc]
  -- The shift adds ΔC to all elevations, so relative ordering between cells is unchanged
  have h_rel_preserved : ∀ (c1 c2 : Cell),
      elevation { dem with C := dem.C + ΔC } c1 < elevation { dem with C := dem.C + ΔC } c2 ↔
      elevation dem c1 < elevation dem c2 := by
    intro c1 c2
    simp [h_elev_shift]
    exact by
      constructor
      · intro h
        linarith
      · intro h
        linarith
  -- Therefore, the set of lower neighbors and the steepest one remain the same
  simp [h_rel_preserved]
