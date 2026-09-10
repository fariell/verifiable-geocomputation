import data.real.basic
import data.array.basic
import data.matrix.notation
import tactic

namespace VeriGIS

-- Define the type for the grid
def Grid (α : Type) (m n : ℕ) := matrix (fin m) (fin n) α

-- Define the D8 flow directions
inductive D8Direction
| E | SE | S | SW | W | NW | N | NE | NoFlow

-- Define the function to calculate the D8 flow direction at a given cell
def d8_at (h : Grid ℝ m n) (r c : ℕ) : D8Direction :=
if r = 0 ∨ r = m - 1 ∨ c = 0 ∨ c = n - 1 then D8Direction.NoFlow
else
  let e := h r c in
  let best := (D8Direction.NoFlow, 0.0) in
  let best_p := (drop, dist2) in
  let best := (best.1, best.2) in
  let best := (best.1, best.2) in
  let best := (best.1, best.2) in
  let best := (best.1, best.2) in
  let best := (best.1, best.2) in
  let best := (best.1, best.2) in
  let best := (best.1, best.2) in
  if best.1 = D8Direction.NoFlow then D8Direction.NoFlow
  else best.1

-- Define the function to create a plane grid
def plane_grid (A B C : ℝ) (m n : ℕ) : Grid ℝ m n :=
λ r c, A * (r : ℝ) + B * (c : ℝ) + C

-- Define the function to get the interior cells of a grid
def interior_cells (m n : ℕ) : list (ℕ × ℕ) :=
list.filter (λ p, p.1 > 0 ∧ p.1 < m - 1 ∧ p.2 > 0 ∧ p.2 < n - 1) (list.product (fin.range m) (fin.range n))

-- Define the function to get the flow directions of the interior cells
def interior_flows (h : Grid ℝ m n) : list D8Direction :=
interior_cells m n >>= λ p, [d8_at h p.1 p.2]

-- Define the property to be proven
theorem d8_flow_direction_constant_on_plane (A B C : ℝ) (m n : ℕ) (h : Grid ℝ m n) (w : ℝ) (h' : Grid ℝ m n) :
  A > 0 → B > 0 → h = plane_grid A B C m n → h' = plane_grid A B (C + w) m n →
  interior_flows h = interior_flows h' :=
begin
  intros A_pos B_pos h_plane h'_plane,
  rw h_plane at h'_plane,
  simp [plane_grid, interior_cells, interior_flows, d8_at] at h'_plane,
  have h_eq : ∀ (r c : ℕ), r < m → c < n → h r c = h' r c,
  { intros r c r_lt_m c_lt_n,
    simp [plane_grid, h_plane, h'_plane, add_comm, add_assoc],
    linarith, },
  have flows_eq : interior_flows h = interior_flows h',
  { apply list.ext,
    intros d,
    simp [interior_flows, list.bind, list.filter, list.mem],
    split,
    { intros h_in,
      cases h_in with p h_in,
      cases p with r c,
      simp [interior_cells, list.mem] at h_in,
      cases h_in with r_in c_in,
      simp [d8_at, h_eq r c r_in c_in], },
    { intros h_in,
      cases h_in with p h_in,
      cases p with r c,
      simp [interior_cells, list.mem] at h_in,
      cases h_in with r_in c_in,
      simp [d8_at, h_eq r c r_in c_in], }, },
  exact flows_eq,
end

end VeriGIS
