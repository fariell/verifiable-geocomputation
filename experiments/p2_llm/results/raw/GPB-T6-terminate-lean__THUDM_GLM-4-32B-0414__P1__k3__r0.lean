import Mathlib.Tactic

namespace VeriGIS.Watershed

-- Define the cell type and successor relation
structure Cell where
  r : Nat
  c : Nat
  deriving Repr, DecidableEq

-- Define the D8 successor relation (from p005_d8)
inductive D8Successor : Cell → Cell → Prop
| N {c} : D8Successor {r := 0, c} {r := 1, c}
| NE {r} : D8Successor {r, c := 0} {r, c := 1}
| E {r} : D8Successor {r, c := 0} {r, c := 1}
| SE {r} : D8Successor {r, c := 0} {r, c := 1}
| S {c} : D8Successor {r := 0, c} {r := 1, c}
| SW {r} : D8Successor {r, c := 0} {r, c := 1}
| W {r} : D8Successor {r, c := 0} {r, c := 1}
| NW {r} : D8Successor {r, c := 0} {r, c := 1}

-- Define a strict descent relation (height must decrease)
def StrictDescent (h : Cell → ℝ) : Cell → Cell → Prop
| c1, c2 => D8Successor c1 c2 ∧ h c1 > h c2

-- Define an orbit as a sequence of cells
def Orbit (h : Cell → ℝ) : List Cell → Prop
| [] => False
| [c] => StrictDescent h c c
| c1 :: c2 :: cs => StrictDescent h c1 c2 ∧ Orbit (c2 :: cs)

-- Define a fixed point as a cell with no strict descent
def FixedPoint (h : Cell → ℝ) (c : Cell) : Prop := ¬∃ c', StrictDescent h c c'

-- Define a finite cell set
def FiniteCellSet (S : Set Cell) : Prop := S.Finite

-- The main theorem: under strict descent, every orbit terminates at a fixed point
-- We use a well-founded measure based on the height of cells
theorem orbit_terminates_at_fixed_point
  (h : Cell → ℝ)
  (S : Set Cell)
  (hS : FiniteCellSet S)
  (orbit : List Cell)
  (orbit_in_S : ∀ c ∈ orbit, c ∈ S)
  (orbit_strict : Orbit h orbit)
  : orbit ≠ [] → ∃ c ∈ orbit, FixedPoint h c := by
  -- Define a measure based on the height of cells in the orbit
  let height_measure : List Cell → ℕ
  | [] => 0
  | c :: cs => Nat.floor (h c) + height_measure cs

  -- Show the measure decreases with each step in the orbit
  intro orbit_nonempty
  -- Get the first cell in the orbit
  obtain [c1; c2; _] := orbit
  -- Get the height of the first cell
  let h1 := h c1
  -- Get the height of the second cell
  let h2 := h c2
  -- Show the height decreases
  have h1_gt_h2 := orbit_strict.1.2
  -- Show the measure decreases
  have measure_decreases : height_measure orbit < height_measure (c2 :: orbit.drop 2) := by
    -- Calculate the measure before
    let before := height_measure orbit
    -- Calculate the measure after
    let after := height_measure (c2 :: orbit.drop 2)
    -- Show the measure decreases
    have h1_floor := Nat.floor_le h1
    have h2_floor := Nat.floor_le h2
    have h1_gt_h2 := h1_gt_h2
    -- Use the fact that the floor function is monotonic
    nlinarith
  -- Use well-founded recursion to find a fixed point
  cases' Nat.find (fun n => height_measure (orbit.take n) = 0) with n hn
  -- The orbit must terminate at a fixed point
  use orbit.last
  -- The orbit is nonempty
  simp only [orbit_nonempty]
  -- The last cell in the orbit must be a fixed point
  intro c2_exists
  -- Get the height of the last cell
  let h_last := h orbit.last
  -- Show the last cell is a fixed point
  push_neg
  -- Assume there is a strict descent from the last cell
  intro c'
  -- Get the height of the next cell
  let h_c' := h c'
  -- Show the height must decrease
  have h_last_gt_h_c' := c2_exists.1.2
  -- This contradicts the fact that the orbit terminates
  contradiction

end VeriGIS.Watershed
