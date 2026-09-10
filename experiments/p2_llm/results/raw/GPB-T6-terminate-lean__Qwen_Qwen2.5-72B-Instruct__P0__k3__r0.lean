import data.nat.basic
import data.set.finite
import data.array.basic
import tactic.well_founded

namespace VeriGIS

-- Define the type for grid cells
structure Cell where
  r : ℕ
  c : ℕ

-- Define the type for a grid
structure Grid where
  height : ℕ
  width : ℕ
  values : array (array ℕ)

-- Define the D8 direction set
def DIRS : list (string × ℕ × ℕ × ℕ) := [
  ("N", 0, -1, 1),
  ("NE", 1, -1, 2),
  ("E", 1, 0, 1),
  ("SE", 1, 1, 2),
  ("S", 0, 1, 1),
  ("SW", -1, 1, 2),
  ("W", -1, 0, 1),
  ("NW", -1, -1, 2)
]

-- Function to get the D8 direction at a cell
def d8_at (h : Grid) (r c : ℕ) : option string :=
  if r = 0 ∨ r = h.height - 1 ∨ c = 0 ∨ c = h.width - 1 then
    none
  else
    let current_value := h.values[r][c] in
    let directions := DIRS.filter (λ d, 0 ≤ r + d.2 ∧ r + d.2 < h.height ∧ 0 ≤ c + d.3 ∧ c + d.3 < h.width) in
    let min_value := directions.map (λ d, h.values[r + d.2][c + d.3]).min in
    directions.find? (λ d, h.values[r + d.2][c + d.3] = min_value).map (λ d, d.1)

-- Function to get the successor cell in the D8 direction
def d8_succ (h : Grid) (cell : Cell) : option Cell :=
  d8_at h cell.r cell.c >>= λ d, some { r := cell.r + (_delta d).2, c := cell.c + (_delta d).3 }

-- Function to get the delta for a given direction
def _delta (d : string) : option (ℕ × ℕ) :=
  DIRS.find? (λ x, x.1 = d).map (λ x, (x.3, x.2))

-- Define the orbit of a cell
def orbit (h : Grid) (cell : Cell) : stream (option Cell) :=
  stream.iterate (d8_succ h) (some cell)

-- Define the termination of an orbit
def terminates_at_fixed_point (h : Grid) (cell : Cell) : Prop :=
  ∃ n : ℕ, orbit h cell n = some cell

-- Define a strict descent successor
def strict_descent_succ (h : Grid) (cell : Cell) : Prop :=
  ∃ d, d8_at h cell.r cell.c = some d ∧ h.values[cell.r][cell.c] > h.values[cell.r + (_delta d).2][cell.c + (_delta d).3]

-- Define a finite cell set
def finite_cell_set (h : Grid) : Prop :=
  h.height > 0 ∧ h.width > 0

-- Define a measure for the orbit
def orbit_measure (h : Grid) (cell : Cell) : ℕ :=
  h.values[cell.r][cell.c]

-- Prove that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem orbit_terminates_at_fixed_point (h : Grid) (cell : Cell) (h_finite : finite_cell_set h) (h_strict : strict_descent_succ h cell) :
  terminates_at_fixed_point h cell :=
begin
  -- Define the well-founded relation
  let wf := well_founded.wf (λ c1 c2, orbit_measure h c1 < orbit_measure h c2),
  -- Prove that the orbit measure is well-founded
  have h_wf : well_founded (λ c1 c2, orbit_measure h c1 < orbit_measure h c2),
  { apply nat.lt_wf },
  -- Prove that the orbit terminates at a fixed point using the well-founded relation
  have h_orbit : ∃ n, orbit h cell n = some cell,
  { apply well_founded.fix,
    intros n h_orbit,
    cases h_orbit with c h_orbit,
    cases h_orbit with h_orbit_eq h_orbit_ne,
    -- If the orbit reaches a fixed point, we are done
    exact ⟨n, h_orbit_eq⟩,
    -- If the orbit does not reach a fixed point, use the strict descent property
    cases h_strict with d h_strict,
    cases h_strict with h_strict_dir h_strict_val,
    have h_next := d8_succ h cell,
    cases h_next with next_cell h_next,
    -- The next cell has a strictly lower value
    have h_next_val := h_strict_val,
    -- The orbit measure is strictly decreasing
    have h_decreases := nat.lt_of_le_of_ne (le_refl (orbit_measure h cell)) (λ h_eq, h_orbit_ne (eq.refl (some cell))),
    -- Use the well-founded relation to show that the orbit must terminate
    exact h_wf h_decreases },
  -- Extract the termination point
  cases h_orbit with n h_orbit,
  exact ⟨n, h_orbit⟩,
end

end VeriGIS
