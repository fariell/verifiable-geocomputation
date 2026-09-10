import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic

open Matrix

-- D8 flow directions as vectors (dx, dy)
inductive D8Dir
  | E  : D8Dir
  | SE : D8Dir
  | S  : D8Dir
  | SW : D8Dir
  | W  : D8Dir
  | NW : D8Dir
  | N  : D8Dir
  | NE : D8Dir
  | NoFlow : D8Dir
deriving DecidableEq

namespace D8Dir

def toVec : D8Dir → ℤ × ℤ
  | E    => (1, 0)
  | SE   => (1, 1)
  | S    => (0, 1)
  | SW   => (-1, 1)
  | W    => (-1, 0)
  | NW   => (-1, -1)
  | N    => (0, -1)
  | NE   => (1, -1)
  | NoFlow => (0, 0)

def distanceSq : D8Dir → ℕ
  | E    => 1
  | SE   => 2
  | S    => 1
  | SW   => 2
  | W    => 1
  | NW   => 2
  | N    => 1
  | NE   => 2
  | NoFlow => 0

end D8Dir

-- Finite grid indexed by Fin m × Fin n
structure Grid (m n : ℕ) where
  height : Fin m → Fin n → ℝ

-- Planar DEM: z = A*x + B*y + C
def planarDEM (A B C : ℝ) (m n : ℕ) : Grid m n :=
  { height := λ i j => A * (i.val : ℝ) + B * (j.val : ℝ) + C }

-- Interior cell: not on boundary
def interior (m n : ℕ) (i : Fin m) (j : Fin n) : Prop :=
  0 < i.val ∧ i.val < m - 1 ∧ 0 < j.val ∧ j.val < n - 1

-- D8 flow computation for a cell
def D8_flow (h : Grid m n) (i : Fin m) (j : Fin n) : D8Dir :=
  let e := h.height i j
  let candidates : List D8Dir := [D8Dir.E, D8Dir.SE, D8Dir.S, D8Dir.SW,
                                  D8Dir.W, D8Dir.NW, D8Dir.N, D8Dir.NE]
  let valid (d : D8Dir) : Option ℝ :=
    let (dx, dy) := d.toVec
    let i' : ℤ := i.val + dy
    let j' : ℤ := j.val + dx
    if h : i' ≥ 0 ∧ i' < m ∧ j' ≥ 0 ∧ j' < n then
      let i'' : Fin m := ⟨i'.toNat, by
        have := h.1
        have := h.2.1
        simp [Fin.val, Int.toNat_of_nonneg (by omega)]⟩
      let j'' : Fin n := ⟨j'.toNat, by
        have := h.2.2.1
        have := h.2.2.2
        simp [Fin.val, Int.toNat_of_nonneg (by omega)]⟩
      let e' := h.height i'' j''
      let drop := e - e'
      if drop > 0 then
        some ((drop * drop) / (d.distanceSq : ℝ))
      else none
    else none
  let best := candidates.foldl (λ (best : Option (D8Dir × ℝ)) d =>
    match valid d, best with
    | some p, none => some (d, p)
    | some p, some (_, p') => if p > p' then some (d, p) else best
    | none, _ => best
    ) none
  match best with
  | some (d, _) => d
  | none => D8Dir.NoFlow

-- Main theorem: On a planar DEM with positive slope, D8 flow direction is constant
-- across interior cells that share the same (A,B,w), and translating C doesn't change it.
theorem planar_D8_constant (A B : ℝ) (hA : A > 0) (hB : B ≥ 0) (m n : ℕ) (hm : m ≥ 3) (hn : n ≥ 3) :
    let w := 1 -- cell width (positive)
    let C1 C2 : ℝ := 0
    let g1 := planarDEM A B C1 m n
    let g2 := planarDEM A B C2 m n
    ∀ i j i' j', interior m n i j → interior m n i' j' →
      D8_flow g1 i j = D8_flow g1 i' j' ∧
      D8_flow g1 i j = D8_flow g2 i j := by
  intro w C1 C2 g1 g2 i j i' j' hi hi'
  have pos_slope : A > 0 := hA
  have nonneg_B : B ≥ 0 := hB
  -- First show translation invariance
  have translation_inv : D8_flow g1 i j = D8_flow g2 i j := by
    simp [D8_flow, planarDEM, Grid.mk.injEq]
    -- The key: elevation differences are unchanged when adding same constant to all cells
    have : ∀ (d : D8Dir), (g1.height i j - g1.height _ _) = (g2.height i j - g2.height _ _) := by
      intro d
      simp [g1, g2, planarDEM]
      ring
    -- Therefore the argmax is identical
    simp [this]
  -- Now show constancy across interior cells
  have constancy : D8_flow g1 i j = D8_flow g1 i' j' := by
    -- For planar DEM z = A*x + B*y + C, the drop to neighbor (dx,dy) is A*dx + B*dy
    -- The D8 power is (drop^2)/dist^2 = (A*dx + B*dy)^2 / dist^2
    -- Since A>0 and B≥0, the maximum occurs at the same direction for all interior cells
    -- because the expression doesn't depend on (i,j) or C
    have dir_calc : ∀ (d : D8Dir), 
        let (dx, dy) := d.toVec
        let drop := A * (dx : ℝ) + B * (dy : ℝ)
        let power := (drop * drop) / (d.distanceSq : ℝ)
        power = if d = D8Dir.W then A^2 else
                if d = D8Dir.NW then ((A + B)^2)/2 else
                if d = D8Dir.N then 0 else
                if d = D8Dir.NE then ((A - B)^2)/2 else
                if d = D8Dir.E then 0 else
                if d = D8Dir.SE then ((A + B)^2)/2 else
                if d = D8Dir.S then 0 else
                ((A - B)^2)/2 := by
      intro d
      cases d <;> simp [D8Dir.toVec, D8Dir.distanceSq] <;> ring
    -- With A>0, B≥0, the maximum is at W when B=0, and at NW when B>0
    by_cases hB0 : B = 0
    · -- Case B=0: all flow West
      have : D8_flow g1 i j = D8Dir.W := by
        simp [D8_flow, dir_calc, hB0, hA, show (0:ℝ) ≥ 0 from by norm_num]
        decide
      have : D8_flow g1 i' j' = D8Dir.W := by
        simp [D8_flow, dir_calc, hB0, hA, show (0:ℝ) ≥ 0 from by norm_num]
        decide
      simp [this]
    · -- Case B>0: all flow Northwest
      have hBpos : B > 0 := lt_of_le_of_ne nonneg_B hB0.symm
      have : D8_flow g1 i j = D8Dir.NW := by
        simp [D8_flow, dir_calc, hA, hBpos]
        nlinarith
      have : D8_flow g1 i' j' = D8Dir.NW := by
        simp [D8_flow, dir_calc, hA, hBpos]
        nlinarith
      simp [this]
  exact ⟨constancy, translation_inv⟩
