import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Fin.VecNotation

open Matrix

/-
  D8 flow direction on a planar DEM z = A x + B y + C with positive slope.
  We prove that for interior cells sharing the same (A,B,w), the D8 direction
  is constant, and translating the elevation datum C does not change the direction.
-/

/-- D8 neighbor offsets: (dx, dy, squared distance) -/
def D8_offsets : List (ℤ × ℤ × ℝ) :=
  [ (1, 0, 1), (1, 1, 2), (0, 1, 1), (-1, 1, 2),
    (-1, 0, 1), (-1, -1, 2), (0, -1, 1), (1, -1, 2) ]

/-- Flow direction as an optional vector (dx, dy). `none` means "NoFlow". -/
abbrev Direction := Option (ℤ × ℤ)

/-- Elevation of a planar DEM at cell (x,y): z = A*x + B*y + C -/
def elevation (A B C : ℝ) (x y : ℤ) : ℝ := A * (x : ℝ) + B * (y : ℝ) + C

/-- D8 steepest‑descent direction for a cell (x,y) on a DEM given by (A,B,C). -/
def D8_direction (A B C : ℝ) (x y : ℤ) : Direction :=
  let candidates := D8_offsets.filterMap λ ⟨dx, dy, d2⟩ =>
    let x' := x + dx
    let y' := y + dy
    let drop := elevation A B C x y - elevation A B C x' y'
    if drop > 0 then some ((drop * drop) / d2, (dx, dy)) else none
  match candidates.maximum? (λ a b => a.1 ≤ b.1) with
  | none => none
  | some (_, dir) => some dir

/-- Interior cell condition: all eight D8 neighbors exist within the grid bounds.
    For simplicity we assume an infinite grid, so every cell is interior. -/
def is_interior (x y : ℤ) : Prop := True

/-- Main theorem: On a planar DEM with positive slope, D8 direction is constant
    across interior cells that share the same (A,B,w), and translating C does not
    change the direction. -/
theorem D8_plane_constant (A B : ℝ) (hA : A > 0) (hB : B > 0) (C₁ C₂ : ℝ) (x₁ y₁ x₂ y₂ : ℤ) :
    is_interior x₁ y₁ → is_interior x₂ y₂ →
    D8_direction A B C₁ x₁ y₁ = D8_direction A B C₂ x₂ y₂ := by
  intro _ _
  unfold D8_direction
  have : ∀ (C : ℝ) (x y dx dy : ℤ) (d2 : ℝ),
      elevation A B C x y - elevation A B C (x + dx) (y + dy) =
      elevation A B 0 x y - elevation A B 0 (x + dx) (y + dy) := by
    intro C x y dx dy d2
    simp [elevation]
    ring
  simp_rw [this]
  congr
