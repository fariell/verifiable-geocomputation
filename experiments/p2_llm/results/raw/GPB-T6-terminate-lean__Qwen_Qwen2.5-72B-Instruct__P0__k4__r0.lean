import data.nat.basic
import data.set.finite
import data.array.basic
import tactic.well_founded

namespace VeriGIS

-- Define the type for grid cells
def Cell := ℕ × ℕ

-- Define the type for a grid (Digital Elevation Model)
def Grid := array (array ℕ)

-- Define the D8 direction set
def D8Directions := { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

-- Function to get the D8 direction at a cell
def d8_at (h : Grid) (r c : ℕ) : option string :=
  if r = 0 ∨ c = 0 ∨ r = h.size - 1 ∨ c = h[0].size - 1 then
    none
  else
    let current_height := h[r][c] in
    let directions := [
      ("N",  r - 1, c),
      ("NE", r - 1, c + 1),
      ("E",  r, c + 1),
      ("SE", r + 1, c + 1),
      ("S",  r + 1, c),
      ("SW", r + 1, c - 1),
      ("W",  r, c - 1),
      ("NW", r - 1, c - 1)
    ] in
    let min_dir := directions.filter (λ d, d.2 < h.size ∧ d.3 < h[0].size).foldl (λ acc d, if h[d.2][d.3] < current_height ∧ (acc = none ∨ h[d.2][d.3] < h[(acc.get!).2][(acc.get!).3] then some d else acc) none in
    min_dir.map (λ d, d.1)

-- Function to get the delta for a D8 direction
def delta (d : string) : option (ℕ × ℕ) :=
  match d with
  | "N"  => some (0, -1)
  | "NE" => some (1, -1)
  | "E"  => some (1, 0)
  | "SE" => some (1, 1)
  | "S"  => some (0, 1)
  | "SW" => some (-1, 1)
  | "W"  => some (-1, 0)
  | "NW" => some (-1, -1)
  | _    => none
  end

-- Function to follow the D8 path from a cell
def follow_d8 (h : Grid) (r c : ℕ) (max_steps : ℕ) : option (bool × Cell × list Cell) :=
  let rec follow (r c : ℕ) (path : list Cell) (steps : ℕ) : option (bool × Cell × list Cell) :=
    if steps = 0 then
      none
    else
      match d8_at h r c with
      | none => some (true, (r, c), path)
      | some d =>
        match delta d with
        | none => none
        | some (dp, dq) =>
          let nr := r + dq, nc := c + dp in
          if nr < 0 ∨ nc < 0 ∨ nr ≥ h.size ∨ nc ≥ h[0].size then
            some (true, (r, c), path)
          else
            let new_path := (r, c) :: path in
            if new_path.length ≠ new_path.to_finset.card then
              some (false, (nr, nc), new_path)
            else
              follow nr nc new_path (steps - 1)
        end
      end
  in
  follow r c [(r, c)] max_steps

-- Define a strict descent successor relation
def strict_descent_successor (h : Grid) (r c : ℕ) (nr nc : ℕ) : Prop :=
  h[nr][nc] < h[r][c] ∧ (d8_at h r c = some (D8Directions.find (λ d, delta d = some (nr - r, nc - c))))

-- Define a fixed point
def is_fixed_point (h : Grid) (r c : ℕ) : Prop :=
  d8_at h r c = none

-- Define the orbit of a cell
def orbit (h : Grid) (r c : ℕ) : set Cell :=
  { (nr, nc) | strict_descent_successor h r c nr nc }

-- Define the property that every orbit terminates at a fixed point
theorem every_orbit_terminates_at_fixed_point (h : Grid) (r c : ℕ) (h_finite : finite (orbit h r c)) :
  ∃ (nr nc : ℕ), is_fixed_point h nr nc ∧ (r, c) ∈ orbit h nr nc :=
begin
  -- Define a measure function for the height of the cell
  let measure : Cell → ℕ := λ (r, c), h[r][c],

  -- Prove that the measure function is well-founded
  have measure_wf : well_founded measure,
  { apply nat.lt_wf },

  -- Prove that the strict descent successor relation is well-founded
  have strict_descent_wf : well_founded (λ (r c : ℕ) (nr nc : ℕ), strict_descent_successor h r c nr nc),
  { apply well_founded Relation.well_founded_of_has_decreasing,
    intros r c,
    use measure,
    intros nr nc,
    split,
    { exact strict_descent_successor.1 },
    { exact measure_wf } },

  -- Use the well-founded induction principle to prove the theorem
  apply well_founded.induction strict_descent_wf (r, c),
  intros r c ih,
  cases d8_at h r c with d,
  { -- If there is no successor, then (r, c) is a fixed point
    use r, use c,
    split,
    { exact is_fixed_point.1 },
    { exact set.mem_of_eq (r, c) (r, c) (eq.refl (r, c)) } },
  { -- If there is a successor, then follow the path
    cases delta d with dp dq,
    { -- If the delta is not defined, then (r, c) is a fixed point
      use r, use c,
      split,
      { exact is_fixed_point.1 },
      { exact set.mem_of_eq (r, c) (r, c) (eq.refl (r, c)) } },
    { -- If the delta is defined, then follow the path
      let nr := r + dq, nc := c + dp,
      have h_orbit : (nr, nc) ∈ orbit h r c,
      { exact set.mem_of_eq (nr, nc) (nr, nc) (eq.refl (nr, nc)) },
      have h_finite_orbit : finite (orbit h nr nc),
      { exact h_finite.subset (set.singleton_subset_iff.1 h_orbit) },
      have ih' : ∃ (nrr nrc : ℕ), is_fixed_point h nrr nrc ∧ (nr, nc) ∈ orbit h nrr nrc,
      { exact ih nr nc h_finite_orbit },
      cases ih' with nrr nrc,
      use nrr, use nrc,
      split,
      { exact is_fixed_point.1 },
      { exact set.mem_of_mem_of_subset h_orbit (set.singleton_subset_iff.1 (set.mem_of_eq (nr, nc) (nr, nc) (eq.refl (nr, nc)))) } }
end

end VeriGIS
