import data.finset
import data.array.basic
import tactic.well_founded

namespace VeriGIS

-- Define the type for a grid cell
def Cell := ℕ × ℕ

-- Define the type for a grid
def Grid := array (array ℕ)

-- Define the D8 direction set
def D8Directions := { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

-- Function to get the D8 direction at a cell
def d8_at (h : Grid) (r c : ℕ) : option string :=
  if r = 0 ∨ c = 0 ∨ r = h.size - 1 ∨ c = h[0].size - 1 then
    none
  else
    let neighbors := [
      (r - 1, c), (r - 1, c + 1), (r, c + 1), (r + 1, c + 1),
      (r + 1, c), (r + 1, c - 1), (r, c - 1), (r - 1, c - 1)
    ] in
    let neighbor_values := neighbors.map (λ (nr, nc), h[nr][nc]) in
    let min_value := neighbor_values.min in
    let min_index := neighbor_values.index_of min_value in
    match min_index with
    | 0 := some "N"
    | 1 := some "NE"
    | 2 := some "E"
    | 3 := some "SE"
    | 4 := some "S"
    | 5 := some "SW"
    | 6 := some "W"
    | 7 := some "NW"
    | _ := none
    end

-- Function to get the delta for a D8 direction
def delta (d : string) : option (ℕ × ℕ) :=
  match d with
  | "N"  := some (0, -1)
  | "NE" := some (1, -1)
  | "E"  := some (1, 0)
  | "SE" := some (1, 1)
  | "S"  := some (0, 1)
  | "SW" := some (-1, 1)
  | "W"  := some (-1, 0)
  | "NW" := some (-1, -1)
  | _    := none
  end

-- Function to follow the D8 path from a cell
def follow_d8 (h : Grid) (r c : ℕ) (max_steps : ℕ) : option (bool × Cell × list Cell) :=
  let rec follow (r c : ℕ) (path : list Cell) (steps : ℕ) : option (bool × Cell × list Cell) :=
    if steps = 0 then
      none
    else
      match d8_at h r c with
      | none := some (true, (r, c), path)
      | some d :=
        match delta d with
        | none := some (true, (r, c), path)
        | some (dp, dq) :=
          let nr := r + dq in
          let nc := c + dp in
          if nr < h.size ∧ nc < h[0].size ∧ nr ≥ 0 ∧ nc ≥ 0 then
            if path.contains (nr, nc) then
              some (false, (nr, nc), path)
            else
              follow nr nc ((nr, nc) :: path) (steps - 1)
          else
            some (true, (r, c), path)
        end
      end
  in
  follow r c [(r, c)] max_steps

-- Define a strict descent successor relation
def strict_descent_successor (h : Grid) (r c : ℕ) (nr nc : ℕ) : Prop :=
  h[nr][nc] < h[r][c] ∧ (nr, nc) ∈ (d8_at h r c).map (λ d, (delta d).get_or_else (r, c))

-- Define a fixed point
def is_fixed_point (h : Grid) (r c : ℕ) : Prop :=
  (d8_at h r c).is_none

-- Define an orbit
def orbit (h : Grid) (r c : ℕ) : list Cell :=
  let rec follow (r c : ℕ) (path : list Cell) : list Cell :=
    match d8_at h r c with
    | none := path
    | some d :=
      match delta d with
      | none := path
      | some (dp, dq) :=
        let nr := r + dq in
        let nc := c + dp in
        if nr < h.size ∧ nc < h[0].size ∧ nr ≥ 0 ∧ nc ≥ 0 then
          follow nr nc ((nr, nc) :: path)
        else
          path
      end
    end
  in
  follow r c [(r, c)]

-- Define a finite cell set
def finite_cell_set (h : Grid) : Prop :=
  h.size < ∞ ∧ h[0].size < ∞

-- Define a well-founded relation
def well_founded_strict_descent (h : Grid) : Prop :=
  well_founded (λ (r c : ℕ) (nr nc : ℕ), strict_descent_successor h r c nr nc)

-- Define a measure for the well-founded relation
def descent_measure (h : Grid) (r c : ℕ) : ℕ :=
  h[r][c]

-- Prove that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem orbit_terminates_at_fixed_point (h : Grid) (r c : ℕ) (h_fin : finite_cell_set h) :
  ∃ (fr fc : ℕ), is_fixed_point h fr fc ∧ (fr, fc) ∈ orbit h r c :=
begin
  -- Define the well-founded relation
  have h_well_founded : well_founded_strict_descent h,
  { apply well_founded.wf,
    intros r c,
    apply nat.lt_wf,
    intros nr nc,
    exact strict_descent_successor h r c nr nc,
    intros,
    exact descent_measure h r c,
  },

  -- Use the well-founded induction principle
  apply h_well_founded.induction (λ (r c : ℕ), ∃ (fr fc : ℕ), is_fixed_point h fr fc ∧ (fr, fc) ∈ orbit h r c),
  intros r c ih,
  -- Base case: if the cell is a fixed point, the orbit terminates at the cell
  by_cases h_fixed : is_fixed_point h r c,
  { use r, use c,
    split,
    exact h_fixed,
    exact (r, c) :: orbit h r c,
  },
  -- Inductive step: if the cell is not a fixed point, follow the D8 path
  { have h_not_fixed : ¬ is_fixed_point h r c,
    exact h_fixed,
    have h_d8 : ∃ (d : string), d8_at h r c = some d,
    { rw is_fixed_point at h_not_fixed,
      exact h_not_fixed,
    },
    cases h_d8 with d h_d8,
    have h_delta : ∃ (dp dq : ℕ), delta d = some (dp, dq),
    { rw h_d8,
      exact (delta d).is_some,
    },
    cases h_delta with dp dq h_delta,
    let nr := r + dq,
    let nc := c + dp,
    have h_strict_descent : strict_descent_successor h r c nr nc,
    { split,
      { rw h_d8,
        rw h_delta,
        exact h[nr][nc] < h[r][c],
      },
      { rw h_d8,
        rw h_delta,
        exact (nr, nc) ∈ (d8_at h r c).map (λ d, (delta d).get_or_else (r, c)),
      },
    },
    -- Apply the inductive hypothesis to the next cell
    have h_next : ∃ (fr fc : ℕ), is_fixed_point h fr fc ∧ (fr, fc) ∈ orbit h nr nc,
    { exact ih nr nc h_strict_descent,
    },
    cases h_next with fr fc h_next,
    use fr, use fc,
    split,
    { exact h_next.left },
    { exact (r, c) :: h_next.right },
  },
end

end VeriGIS
