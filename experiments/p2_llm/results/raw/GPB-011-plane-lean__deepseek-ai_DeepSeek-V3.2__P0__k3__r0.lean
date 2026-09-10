import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

/-
  D8 flow direction on a planar DEM z = A x + B y + C with positive slope.
  We prove that for interior cells sharing the same (A, B, w) parameters,
  the D8 flow direction is constant, and translating the elevation datum C
  does not change the direction.
-/

/-- D8 neighbor offsets: (dx, dy, squared distance) -/
def D8_dirs : List (ℤ × ℤ × ℝ) :=
  [(1, 0, 1), (1, 1, 2), (0, 1, 1), (-1, 1, 2),
   (-1, 0, 1), (-1, -1, 2), (0, -1, 1), (1, -1, 2)]

/-- Flow direction as a vector (dx, dy) -/
abbrev FlowDir := ℤ × ℤ

/-- NoFlow sentinel -/
def NoFlow : FlowDir := (0, 0)

/-- D8 flow direction at cell (x, y) given elevation function h -/
def D8 (h : ℤ → ℤ → ℝ) (x y : ℤ) : FlowDir :=
  let e := h x y
  let candidates := D8_dirs.filterMap (λ (dx, dy, d2) =>
    let x' := x + dx
    let y' := y + dy
    let drop := e - h x' y'
    if drop > 0 then
      some ((drop * drop) / d2, (dx, dy))
    else
      none)
  match candidates.maximum? (λ a b => a.1 ≤ b.1) with
  | some (_, dir) => dir
  | none => NoFlow

/-- Planar DEM: z = A x + B y + C -/
def plane (A B C : ℝ) (x y : ℤ) : ℝ :=
  A * (x : ℝ) + B * (y : ℝ) + C

/-- Positive slope condition: A > 0 and B ≥ 0, with at least one strictly positive -/
structure PosSlope where
  A : ℝ
  B : ℝ
  hA : A > 0
  hB : B ≥ 0

/-- Interior cell condition: all 8 neighbors are defined (always true for ℤ grid) -/
def interior (x y : ℤ) : Prop := True

theorem D8_plane_constant (ps : PosSlope) (C : ℝ) (x₁ y₁ x₂ y₂ : ℤ) :
    interior x₁ y₁ → interior x₂ y₂ →
    D8 (plane ps.A ps.B C) x₁ y₁ = D8 (plane ps.A ps.B C) x₂ y₂ := by
  intro _ _
  unfold D8 plane
  simp only [add_sub_cancel, sub_self, mul_zero, zero_add]
  have hA : ps.A > 0 := ps.hA
  have hB : ps.B ≥ 0 := ps.hB
  -- The drop for neighbor (dx, dy) is A*dx + B*dy (independent of x,y,C)
  let drop (dx dy : ℤ) : ℝ := ps.A * (dx : ℝ) + ps.B * (dy : ℝ)
  -- Compute squared drop / distance for each direction
  let candidates : List (ℝ × FlowDir) :=
    D8_dirs.filterMap (λ (dx, dy, d2) =>
      let d := drop dx dy
      if d > 0 then
        some ((d * d) / d2, (dx, dy))
      else
        none)
  -- The maximizing direction depends only on A, B, not on (x,y,C)
  have : ∀ x y, D8 (plane ps.A ps.B C) x y =
      match candidates.maximum? (λ a b => a.1 ≤ b.1) with
      | some (_, dir) => dir
      | none => NoFlow := by
    intro x y
    unfold D8
    congr
    funext (dx, dy, d2)
    simp [plane, drop]
    ring
  simp [this]

theorem D8_translation_invariant (ps : PosSlope) (C₁ C₂ : ℝ) (x y : ℤ) :
    D8 (plane ps.A ps.B C₁) x y = D8 (plane ps.A ps.B C₂) x y := by
  unfold D8 plane
  simp only [add_sub_cancel, sub_self, mul_zero, zero_add]
  -- The drop e - h x' y' = (A*x+B*y+C) - (A*x'+B*y'+C) = A*(x-x') + B*(y-y')
  -- which is independent of C.
  congr
  funext (dx, dy, d2)
  simp [add_sub_add_left_eq_sub]

/-- Main theorem combining both properties -/
theorem D8_plane_properties (ps : PosSlope) (C : ℝ) (x₁ y₁ x₂ y₂ : ℤ) :
    interior x₁ y₁ → interior x₂ y₂ →
    D8 (plane ps.A ps.B C) x₁ y₁ = D8 (plane ps.A ps.B C) x₂ y₂ ∧
    ∀ C', D8 (plane ps.A ps.B C) x₁ y₁ = D8 (plane ps.A ps.B C') x₁ y₁ := by
  intro h1 h2
  constructor
  · exact D8_plane_constant ps C x₁ y₁ x₂ y₂ h1 h2
  · intro C'
    exact D8_translation_invariant ps C C' x₁ y₁
