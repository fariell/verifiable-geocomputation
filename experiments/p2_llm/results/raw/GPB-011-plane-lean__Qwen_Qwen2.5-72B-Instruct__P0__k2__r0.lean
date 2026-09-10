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
list.filter (λ rc, rc.1 > 0 ∧ rc.1 < m - 1 ∧ rc.2 > 0 ∧ rc.2 < n - 1) (list.product (fin.range m) (fin.range n))

-- Define the function to get the flow directions of the interior cells
def interior_flows (h : Grid ℝ m n) : list D8Direction :=
interior_cells m n >>= λ rc, [d8_at h rc.1 rc.2]

-- Define the property to be proven
def d8_flow_constant_on_plane (A B C : ℝ) (m n : ℕ) (h : Grid ℝ m n) : Prop :=
∀ (r c : ℕ), (r, c) ∈ interior_cells m n → d8_at h r c = d8_at (plane_grid A B C m n) r c

-- Prove the property
theorem d8_flow_constant_on_plane_translation (A B : ℝ) (h : Grid ℝ m n) (C1 C2 : ℝ) (m n : ℕ) :
  d8_flow_constant_on_plane A B C1 m n h → d8_flow_constant_on_plane A B C2 m n h :=
begin
  intros h_const,
  unfold d8_flow_constant_on_plane,
  intros r c rc_in_interior,
  have h1 := h_const r c rc_in_interior,
  have h2 := h_const r c rc_in_interior,
  rw [plane_grid, plane_grid] at h1 h2,
  simp only [matrix.nth, fin.coe_mk, sub_eq_add_neg, add_assoc, add_comm, add_left_comm] at h1 h2,
  congr,
  exact h1,
end

end VeriGIS
