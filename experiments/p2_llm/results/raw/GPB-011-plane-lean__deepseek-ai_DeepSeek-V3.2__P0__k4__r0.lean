import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Matrix.Basic

open Matrix

/-
  D8 flow direction on a planar DEM z = A x + B y + C with positive slope.
  We prove that for interior cells sharing the same (A,B,w), the D8 flow direction
  is constant, and translating the elevation datum C does not change the direction.
-/

-- Directions for D8 flow: 8 cardinal and intercardinal directions plus NoFlow
inductive D8Dir
  | E | SE | S | SW | W | NW | N | NE | NoFlow
  deriving DecidableEq, Repr

-- Grid coordinates
abbrev Row := ℤ
abbrev Col := ℤ

-- Neighbor offsets for D8
def D8_offsets : List (D8Dir × (Col × Row) × ℝ) :=
  [ (D8Dir.E,  (1, 0), 1.0),
    (D8Dir.SE, (1, 1), Real.sqrt 2),
    (D8Dir.S,  (0, 1), 1.0),
    (D8Dir.SW, (-1, 1), Real.sqrt 2),
    (D8Dir.W,  (-1, 0), 1.0),
    (D8Dir.NW, (-1, -1), Real.sqrt 2),
    (D8Dir.N,  (0, -1), 1.0),
    (D8Dir.NE, (1, -1), Real.sqrt 2) ]

-- Elevation function for a plane: z = A*x + B*y + C
def plane_elevation (A B C : ℝ) (x y : ℤ) : ℝ :=
  A * (x : ℝ) + B * (y : ℝ) + C

-- D8 flow direction at a cell (x,y) on a plane
def D8_on_plane (A B C : ℝ) (x y : ℤ) : D8Dir :=
  let z0 := plane_elevation A B C x y
  let candidates := D8_offsets.filterMap fun (dir, (dx, dy), dist) =>
    let z1 := plane_elevation A B C (x + dx) (y + dy)
    let drop := z0 - z1
    if drop > 0 then
      some (dir, drop / dist)
    else
      none
  match candidates.maximum? (λ a b => a.2 ≤ b.2) with
  | some (dir, _) => dir
  | none => D8Dir.NoFlow

-- Positive slope condition: at least one of A,B positive and the other nonnegative
structure PositiveSlope where
  A : ℝ
  B : ℝ
  hA : 0 < A ∨ (A = 0 ∧ 0 < B)
  hB : 0 ≤ B

-- Main theorem: D8 direction is invariant under translation of C
theorem D8_plane_constant (ps : PositiveSlope) (C1 C2 : ℝ) (x y : ℤ) :
    D8_on_plane ps.A ps.B C1 x y = D8_on_plane ps.A ps.B C2 x y := by
  unfold D8_on_plane
  have h : ∀ C dx dy, plane_elevation ps.A ps.B C1 (x + dx) (y + dy) - plane_elevation ps.A ps.B C1 x y
                    = plane_elevation ps.A ps.B C2 (x + dx) (y + dy) - plane_elevation ps.A ps.B C2 x y := by
    intro C dx dy
    simp [plane_elevation]
    ring
  congr 1
  ext ⟨dir, dp⟩
  simp only [Option.mem_def, List.mem_filterMap]
  constructor
  · intro ⟨⟨dx, dy, dist⟩, hmem, hdrop⟩
    refine ⟨⟨dx, dy, dist⟩, hmem, ?_⟩
    simp [h] at hdrop ⊢
    exact hdrop
  · intro ⟨⟨dx, dy, dist⟩, hmem, hdrop⟩
    refine ⟨⟨dx, dy, dist⟩, hmem, ?_⟩
    simp [h] at hdrop ⊢
    exact hdrop

-- Corollary: For interior cells (no boundary effects), direction depends only on A,B,w
-- Here w is the grid spacing (implicitly 1 in our integer grid)
theorem D8_plane_interior_constant (ps : PositiveSlope) (C : ℝ) (x1 y1 x2 y2 : ℤ) :
    D8_on_plane ps.A ps.B C x1 y1 = D8_on_plane ps.A ps.B C x2 y2 := by
  calc
    D8_on_plane ps.A ps.B C x1 y1 = D8_on_plane ps.A ps.B 0 x1 y1 := by
      symm
      apply D8_plane_constant ps C 0 x1 y1
    _ = D8_on_plane ps.A ps.B 0 x2 y2 := by
      -- The direction depends only on A,B because C=0, and the relative drops are proportional to A*dx + B*dy
      unfold D8_on_plane
      congr 1
      ext ⟨dir, dp⟩
      simp only [List.mem_filterMap]
      constructor
      · intro ⟨⟨dx, dy, dist⟩, hmem, hdrop⟩
        refine ⟨⟨dx, dy, dist⟩, hmem, ?_⟩
        simp [plane_elevation] at hdrop ⊢
        have : ps.A * (dx : ℝ) + ps.B * (dy : ℝ) > 0 := by
          rcases ps.hA with (hA | ⟨hA0, hBpos⟩)
          · have := ps.hB
            nlinarith?  -- A>0, B≥0, dx,dy in {-1,0,1} with at least one nonzero
          · nlinarith
        nlinarith
      · intro ⟨⟨dx, dy, dist⟩, hmem, hdrop⟩
        refine ⟨⟨dx, dy, dist⟩, hmem, ?_⟩
        simp [plane_elevation] at hdrop ⊢
        have : ps.A * (dx : ℝ) + ps.B * (dy : ℝ) > 0 := by
          rcases ps.hA with (hA | ⟨hA0, hBpos⟩)
          · have := ps.hB
            nlinarith?
          · nlinarith
        nlinarith
    _ = D8_on_plane ps.A ps.B C x2 y2 := by
      apply D8_plane_constant ps 0 C x2 y2
