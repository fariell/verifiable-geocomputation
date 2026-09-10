import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic

open Matrix

-- Representing a planar DEM: z = A x + B y + C
structure PlanarDEM where
  A : ℚ
  B : ℚ
  C : ℚ

-- D8 flow direction encoding as an integer 1..8 (or 0 for no flow)
-- We'll use ZMod 9 for simplicity, where 0 means no flow and 1..8 are directions.
abbrev D8Dir := ZMod 9

-- Grid cell coordinates
structure Cell where
  x : ℤ
  y : ℤ

-- Slope must be positive: A > 0 and B > 0
def positive_slope (dem : PlanarDEM) : Prop :=
  dem.A > 0 ∧ dem.B > 0

-- Elevation at a cell for a given DEM
def elevation (dem : PlanarDEM) (c : Cell) : ℚ :=
  dem.A * (c.x : ℚ) + dem.B * (c.y : ℚ) + dem.C

-- D8 flow direction from a cell to its 8 neighbors
-- We compute the steepest descent among the 8 neighbors.
-- If no descent exists, return 0.
def d8_dir (dem : PlanarDEM) (c : Cell) : D8Dir :=
  let neighbors : List (Cell × D8Dir) :=
    [ (⟨c.x - 1, c.y - 1⟩, 1), (⟨c.x, c.y - 1⟩, 2), (⟨c.x + 1, c.y - 1⟩, 3),
      (⟨c.x - 1, c.y⟩, 4),                         (⟨c.x + 1, c.y⟩, 5),
      (⟨c.x - 1, c.y + 1⟩, 6), (⟨c.x, c.y + 1⟩, 7), (⟨c.x + 1, c.y + 1⟩, 8) ]
  let z0 := elevation dem c
  let candidates := neighbors.filterMap (λ ⟨nb, dir⟩ =>
    let znb := elevation dem nb
    if znb < z0 then some (z0 - znb, dir) else none)
  match candidates.maximum? (λ a b => a.1 ≤ b.1) with
  | some (_, dir) => dir
  | none => 0

-- Theorem: On a planar DEM with positive slope, D8 flow direction is constant
-- across interior cells that share the same (A, B, w) where w = A/B (slope ratio).
-- Translating the elevation datum C does not change the direction.
theorem d8_dir_constant_for_same_slope_ratio (A B : ℚ) (hA : A > 0) (hB : B > 0) :
    let w := A / B in
    ∀ (C1 C2 : ℚ) (c1 c2 : Cell),
      d8_dir ⟨A, B, C1⟩ c1 = d8_dir ⟨A, B, C2⟩ c2 := by
  intro w C1 C2 c1 c2
  -- Unfold definitions
  simp [d8_dir, elevation, PlanarDEM.mk]
  -- The elevation at any cell is linear in C, and C cancels when comparing differences.
  -- Because the slope is the same (A, B fixed), the relative differences between
  -- a cell and its neighbors are independent of C.
  have h1 : ∀ (C : ℚ) (c : Cell) (dx dy : ℤ),
      elevation ⟨A, B, C⟩ ⟨c.x + dx, c.y + dy⟩ - elevation ⟨A, B, C⟩ c = A * (dx : ℚ) + B * (dy : ℚ) := by
    intro C c dx dy
    simp [elevation]
    ring
  -- Therefore, the steepest descent choice depends only on A, B, dx, dy, not on C.
  -- Hence the D8 direction is the same for any C.
  ext i
  simp [d8_dir, elevation]
  congr
  funext nb
  simp [h1]
