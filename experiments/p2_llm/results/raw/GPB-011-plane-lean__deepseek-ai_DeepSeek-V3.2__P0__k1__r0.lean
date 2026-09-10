import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

/-
  D8 flow direction on a planar DEM z = A x + B y + C with positive slope.
  We prove that for interior cells sharing the same (A,B,w), the D8 flow direction
  is constant, and that translating the elevation datum C does not change the direction.
-/

section D8Definitions

-- Grid dimensions (n×m)
variable (n m : ℕ) [NeZero n] [NeZero m]

-- Cell coordinates
abbrev Row := Fin n
abbrev Col := Fin m

-- D8 neighbor offsets: (Δcol, Δrow, squared distance)
structure D8Neighbor where
  name : String
  dcol : ℤ
  drow : ℤ
  distSq : ℚ

def D8Neighbors : List D8Neighbor := [
  ⟨"E", 1, 0, 1⟩,
  ⟨"SE", 1, 1, 2⟩,
  ⟨"S", 0, 1, 1⟩,
  ⟨"SW", -1, 1, 2⟩,
  ⟨"W", -1, 0, 1⟩,
  ⟨"NW", -1, -1, 2⟩,
  ⟨"N", 0, -1, 1⟩,
  ⟨"NE", 1, -1, 2⟩
]

-- Elevation function for a planar DEM: z = A*x + B*y + C
-- We map grid coordinates to real elevations
abbrev Plane (A B C : ℚ) (c : Col) (r : Row) : ℚ :=
  A * (c.val : ℚ) + B * (r.val : ℚ) + C

-- Interior cell: not on the boundary
def interior (r : Row) (c : Col) : Prop :=
  0 < r.val ∧ r.val < n - 1 ∧ 0 < c.val ∧ c.val < m - 1

-- Valid neighbor check
def validNeighbor (r : Row) (c : Col) (nb : D8Neighbor) : Prop :=
  let r' : ℤ := r.val + nb.drow
  let c' : ℤ := c.val + nb.dcol
  0 ≤ r' ∧ r' < n ∧ 0 ≤ c' ∧ c' < m

-- Drop (elevation difference) to a neighbor
def drop (A B C : ℚ) (r : Row) (c : Col) (nb : D8Neighbor) : ℚ :=
  Plane A B C c r - Plane A B C (⟨c.val + nb.dcol, by
    have h := validNeighbor n m r c nb
    simp [validNeighbor] at h
    exact ⟨by omega, by omega⟩⟩ : Col) (⟨r.val + nb.drow, by
    have h := validNeighbor n m r c nb
    simp [validNeighbor] at h
    exact ⟨by omega, by omega⟩⟩ : Row)

-- Power drop: (drop^2) / distSq
def powerDrop (A B C : ℚ) (r : Row) (c : Col) (nb : D8Neighbor) : ℚ :=
  let d := drop n m A B C r c nb
  (d * d) / nb.distSq

-- D8 flow direction: neighbor with maximum positive power drop, or "NoFlow"
inductive FlowDir
  | noFlow
  | flow (nb : D8Neighbor)
  deriving DecidableEq

def D8Dir (A B C : ℚ) (r : Row) (c : Col) : FlowDir :=
  let candidates := D8Neighbors.filter (λ nb =>
    validNeighbor n m r c nb ∧ drop n m A B C r c nb > 0)
  match candidates.maximum? (λ nb => powerDrop n m A B C r c nb) with
  | none => FlowDir.noFlow
  | some nb => FlowDir.flow nb

end D8Definitions

section PlaneProperties

variable (n m : ℕ) [NeZero n] [NeZero m]
variable (A B : ℚ) (hA : A > 0) (hB : B ≥ 0) (w : ℚ) (hw : w > 0)

-- Positive slope condition: at least one of A,B positive
def positiveSlope : Prop := A > 0 ∨ B > 0

-- Key lemma: drop is independent of C and linear in coordinates
lemma drop_independent_of_C (C : ℚ) (r : Row) (c : Col) (nb : D8Neighbor) :
    drop n m A B C r c nb = A * (-nb.dcol : ℚ) + B * (-nb.drow : ℚ) := by
  simp [drop, Plane]
  ring

lemma drop_independent_of_C' (C C' : ℚ) (r : Row) (c : Col) (nb : D8Neighbor) :
    drop n m A B C r c nb = drop n m A B C' r c nb := by
  simp [drop_independent_of_C]

-- Power drop is also independent of C
lemma powerDrop_independent_of_C (C : ℚ) (r : Row) (c : Col) (nb : D8Neighbor) :
    powerDrop n m A B C r c nb = ((A * (-nb.dcol : ℚ) + B * (-nb.drow : ℚ)) ^ 2) / nb.distSq := by
  simp [powerDrop, drop_independent_of_C]

lemma powerDrop_independent_of_C' (C C' : ℚ) (r : Row) (c : Col) (nb : D8Neighbor) :
    powerDrop n m A B C r c nb = powerDrop n m A B C' r c nb := by
  simp [powerDrop_independent_of_C]

-- Main theorem: D8 direction is constant across interior cells with same (A,B,w)
-- and invariant under translation of C
theorem D8_constant_on_plane_interior (C : ℚ) (r₁ r₂ : Row) (c₁ c₂ : Col)
    (h₁ : interior n m r₁ c₁) (h₂ : interior n m r₂ c₂) :
    D8Dir n m A B C r₁ c₁ = D8Dir n m A B C r₂ c₂ := by
  unfold D8Dir
  have h_indep : ∀ (r : Row) (c : Col) (nb : D8Neighbor),
      powerDrop n m A B C r c nb = powerDrop n m A B 0 r c nb := by
    intro r c nb
    exact powerDrop_independent_of_C' n m A B C 0 r c nb
  simp [h_indep]

-- Corollary: translation of C does not change direction
theorem D8_invariant_under_C_translation (C C' : ℚ) (r : Row) (c : Col) :
    D8Dir n m A B C r c = D8Dir n m A B C' r c := by
  unfold D8Dir
  have h_indep : ∀ (nb : D8Neighbor),
      powerDrop n m A B C r c nb = powerDrop n m A B C' r c nb := by
    intro nb
    exact powerDrop_independent_of_C' n m A B C C' r c nb
  simp [h_indep]

-- Additional lemma: positive slope ensures flow exists for interior cells
-- (assuming the plane slopes downward in at least one neighbor direction)
lemma interior_has_flow (C : ℚ) (r : Row) (c : Col) (h : interior n m r c)
    (h_slope : positiveSlope A B) : D8Dir n m A B C r c ≠ FlowDir.noFlow := by
  unfold positiveSlope at h_slope
  rcases h_slope with (hA | hB)
  · -- A > 0: west neighbor has positive drop
    let nb : D8Neighbor := ⟨"W", -1, 0, 1⟩
    have h_valid : validNeighbor n m r c nb := by
      unfold validNeighbor interior at h
      obtain ⟨hr1, hr2, hc1, hc2⟩ := h
      constructor <;> omega
    have h_drop : drop n m A B C r c nb > 0 := by
      simp [drop_independent_of_C, hA]
      linarith
    unfold D8Dir
    simp [h_valid, h_drop]
    intro hmax
    have := (List.maximum?_eq_none_iff _).mp hmax nb
    simp [this, powerDrop, drop_independent_of_C, hA] at this
  · -- B > 0: north neighbor has positive drop
    let nb : D8Neighbor := ⟨"N", 0, -1, 1⟩
    have h_valid : validNeighbor n m r c nb := by
      unfold validNeighbor interior at h
      obtain ⟨hr1, hr2, hc1, hc2⟩ := h
      constructor <;> omega
    have h_drop : drop n m A B C r c nb > 0 := by
      simp [drop_independent_of_C, hB]
      linarith
    unfold D8Dir
    simp [h_valid, h_drop]
    intro hmax
    have := (List.maximum?_eq_none_iff _).mp hmax nb
    simp [this, powerDrop, drop_independent_of_C, hB] at this

end PlaneProperties
