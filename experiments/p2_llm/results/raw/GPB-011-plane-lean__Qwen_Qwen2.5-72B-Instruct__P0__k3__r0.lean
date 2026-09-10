import data.real.basic
import data.array.basic
import data.matrix.notation
import tactic

namespace VeriGIS

-- Define the type for the grid
def Grid (n m : ℕ) := matrix (fin n) (fin m) ℝ

-- Define the D8 flow directions
inductive D8Direction
| E | SE | S | SW | W | NW | N | NE | NoFlow

-- Define the function to calculate the D8 flow direction at a given cell
def d8_at (h : Grid n m) (r c : ℕ) : D8Direction :=
if r = 0 ∨ r = n - 1 ∨ c = 0 ∨ c = m - 1 then D8Direction.NoFlow
else
  let e := h r c in
  let best := (D8Direction.NoFlow, 0.0) in
  let best_p := (drop : ℝ, dist2 : ℝ) → drop * drop / dist2 in
  let DIRS : list (D8Direction × ℤ × ℤ × ℝ) :=
    [(D8Direction.E, 1, 0, 1.0),
     (D8Direction.SE, 1, 1, 2.0),
     (D8Direction.S, 0, 1, 1.0),
     (D8Direction.SW, -1, 1, 2.0),
     (D8Direction.W, -1, 0, 1.0),
     (D8Direction.NW, -1, -1, 2.0),
     (D8Direction.N, 0, -1, 1.0),
     (D8Direction.NE, 1, -1, 2.0)] in
  let best_dir := DIRS.foldl (λ best dir, 
    let (name, dp, dq, dist2) := dir in
    let rr := r + dq in
    let cc := c + dp in
    if 0 ≤ rr ∧ rr < n ∧ 0 ≤ cc ∧ cc < m then
      let drop := e - h rr cc in
      if drop > 0 then
        let p := best_p drop dist2 in
        if p > (best_p (snd best) (snd best)) then (name, drop) else best
      else best
    else best) best in
  fst best_dir

-- Define the function to create a planar DEM grid
def plane_grid (A B C : ℝ) (n m : ℕ) : Grid n m :=
λ r c, A * (r : ℝ) + B * (c : ℝ) + C

-- Define the function to get the flow direction for all interior cells
def interior_flows (h : Grid n m) : list (D8Direction) :=
list.pmap (λ r, list.pmap (λ c, d8_at h r c) (list.range (m - 2) |>.map (λ i, i + 1))) (list.range (n - 2) |>.map (λ i, i + 1)) |>.join

-- Define the property to be proven
theorem d8_flow_direction_constant_on_plane (A B C : ℝ) (n m : ℕ) (h : Grid n m) (h' : Grid n m) :
  A > 0 ∧ B > 0 → (h = plane_grid A B C n m) → (h' = plane_grid A B (C + 1) n m) →
  interior_flows h = interior_flows h' :=
begin
  assume A_pos B_pos h_eq h'_eq,
  rw h_eq at h'_eq,
  rw h'_eq,
  -- Simplify the problem by showing that the flow direction is determined by the relative
  -- differences in elevation, which are unchanged by a constant translation in C.
  have h_diff : ∀ r c, h r c - h (r + 1) c = h' r c - h' (r + 1) c,
  { intros r c,
    simp [plane_grid, h_eq, h'_eq],
    ring, },
  have h'_diff : ∀ r c, h r c - h r (c + 1) = h' r c - h' r (c + 1),
  { intros r c,
    simp [plane_grid, h_eq, h'_eq],
    ring, },
  -- Show that the flow direction is the same for all interior cells
  have flow_eq : ∀ r c, 0 < r ∧ r < n - 1 → 0 < c ∧ c < m - 1 → d8_at h r c = d8_at h' r c,
  { intros r c r_in c_in,
    -- Use the definition of d8_at and the fact that the differences are the same
    simp [d8_at, h_diff, h'_diff, r_in, c_in],
    -- The flow direction is determined by the maximum drop, which is the same for both grids
    congr,
    -- The list of directions and their corresponding drops and distances are the same
    congr,
    -- The best direction and its corresponding drop are the same
    congr, },
  -- Use the flow_eq to show that the interior flows are the same
  simp [interior_flows, flow_eq],
end

end VeriGIS
