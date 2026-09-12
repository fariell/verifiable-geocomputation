import Mathlib.Data.Real.Basic
import Mathlib.Data.List.Basic
import Mathlib.Data.Set.Function
import Mathlib.Algebra.GroupPower.Lemmas

open List

/- Directions defined as (Δcolumn, Δrow) for D8 flow -/
def directions : List (ℤ × ℤ) :=
  [(1, 0),   -- East
   (1, 1),   -- Southeast
   (0, 1),   -- South
   (-1, 1),  -- Southwest
   (-1, 0),  -- West
   (-1, -1), -- Northwest
   (0, -1),  -- North
   (1, -1)]  -- Northeast

/- Priority function for flow direction -/
def priority (A B : ℝ) (dc dr : ℤ) : ℝ :=
  let denom := (dc : ℝ)^2 + (dr : ℝ)^2
  (A * dc + B * dr)^2 / denom

/- Compute global flow direction from plane parameters -/
def global_flow_direction (A B : ℝ) : Option (ℤ × ℤ) :=
  let candidates := directions.filter (λ (dc, dr) => A * (dc : ℝ) + B * (dr : ℝ) < 0)
  if h : candidates.isEmpty then
    none
  else
    let candList := candidates
    let M := candList.foldl (λ maxVal d => 
      max maxVal (priority A B d.1 d.2)) (priority A B (candList.head h).1 (candList.head h).2)
    directions.find? (λ d => 
      d ∈ candidates ∧ priority A B d.1 d.2 = M)

/- D8 flow implementation for a grid cell -/
def d8_flow (grid : ℤ → ℤ → ℝ) (i j : ℤ) : Option (ℤ × ℤ) :=
  let neighbors := directions.filter (λ (dc, dr) => 
    let elev_center := grid i j
    let elev_nbr := grid (i + dr) (j + dc)
    elev_center - elev_nbr > 0)
  if h : neighbors.isEmpty then
    none
  else
    let M := neighbors.foldl (λ maxVal d => 
      let elev_center := grid i j
      let elev_nbr := grid (i + d.2) (j + d.1)
      let drop := elev_center - elev_nbr
      max maxVal (drop^2 / (d.1^2 + d.2^2 : ℝ)) 
      (let (dc, dr) := neighbors.head h
      let drop0 := grid i j - grid (i + dr) (j + dc)
      drop0^2 / (dc^2 + dr^2 : ℝ))
    directions.find? (λ d => 
      d ∈ neighbors ∧ 
      let drop := grid i j - grid (i + d.2) (j + d.1)
      drop^2 / (d.1^2 + d.2^2 : ℝ) = M)

/- Proof that flow direction is constant for planar DEM -/
theorem d8_flow_constant (A B C : ℝ) (grid : ℤ → ℤ → ℝ) 
  (hgrid : ∀ i j, grid i j = A * j + B * i + C) 
  (i j : ℤ) :
  d8_flow grid i j = global_flow_direction A B := by
  simp [d8_flow, global_flow_direction, hgrid]
  congr! 2
  · ext ⟨dc, dr⟩
    simp [hgrid]
    ring_nf
    rw [sub_neg]
    exact lt_to_lt_iff_ne.symm
  · ext ⟨dc, dr⟩
    simp [hgrid, priority]
    ring_nf
