import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

-- Representing a planar DEM: z = A*x + B*y + C
structure PlanarDEM where
  A : ℝ
  B : ℝ
  C : ℝ

-- Grid cell coordinates
structure Cell where
  x : ℤ
  y : ℤ

-- D8 flow direction as an integer from 1 to 8 (standard encoding)
inductive D8Direction : Type
  | E : D8Direction
  | NE : D8Direction
  | N : D8Direction
  | NW : D8Direction
  | W : D8Direction
  | SW : D8Direction
  | S : D8Direction
  | SE : D8Direction

instance : ToString D8Direction where
  toString d := match d with
    | .E => "E"
    | .NE => "NE"
    | .N => "N"
    | .NW => "NW"
    | .W => "W"
    | .SW => "SW"
    | .S => "S"
    | .SE => "SE"

-- Elevation at a cell for a given DEM
def elevation (dem : PlanarDEM) (c : Cell) : ℝ :=
  dem.A * (c.x : ℝ) + dem.B * (c.y : ℝ) + dem.C

-- Slope vector (A, B) must be positive in the sense that at least one component is positive
-- and the other non‑negative, ensuring a unique steepest descent direction.
def positive_slope (dem : PlanarDEM) : Prop :=
  dem.A > 0 ∧ dem.B ≥ 0 ∨ dem.A ≥ 0 ∧ dem.B > 0

-- D8 flow direction from a cell given a DEM with positive slope
def flow_direction (dem : PlanarDEM) (c : Cell) : D8Direction :=
  if dem.A > 0 then
    if dem.B > 0 then
      if dem.A > dem.B then D8Direction.E else D8Direction.N
    else if dem.B < 0 then
      if dem.A > -dem.B then D8Direction.E else D8Direction.S
    else D8Direction.E
  else if dem.A < 0 then
    if dem.B > 0 then
      if -dem.A > dem.B then D8Direction.W else D8Direction.N
    else if dem.B < 0 then
      if -dem.A > -dem.B then D8Direction.W else D8Direction.S
    else D8Direction.W
  else -- dem.A = 0
    if dem.B > 0 then D8Direction.N
    else if dem.B < 0 then D8Direction.S
    else D8Direction.E -- arbitrary default when slope is zero, but positive_slope excludes this

-- The main theorem: flow direction is invariant under translation of C
theorem flow_direction_translation_invariant (dem : PlanarDEM) (hpos : positive_slope dem) (c : Cell) :
    ∀ (C' : ℝ), flow_direction { dem with C := C' } c = flow_direction dem c := by
  intro C'
  unfold flow_direction
  -- The definition of flow_direction depends only on A and B, not on C.
  -- Therefore changing C leaves the result unchanged.
  rfl

-- Additional theorem: flow direction is constant across interior cells
-- (i.e., independent of x,y) for a fixed (A,B) with positive slope.
theorem flow_direction_constant (dem : PlanarDEM) (hpos : positive_slope dem) (c1 c2 : Cell) :
    flow_direction dem c1 = flow_direction dem c2 := by
  unfold flow_direction
  -- The definition does not depend on the cell coordinates, only on A and B.
  rfl
