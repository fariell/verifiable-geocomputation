import data.real.basic
import data.array.basic
import data.matrix.notation
import tactic

namespace VeriGIS

-- Define the type for the grid
def Grid (α : Type) (n m : ℕ) := matrix (fin n) (fin m) α

-- Define the D8 flow directions
inductive D8Direction
| E | SE | S | SW | W | NW | N | NE | NoFlow

-- Define the function to calculate the D8 flow direction at a given cell
def d8_at (A B C : ℝ) (n m : ℕ) (h : Grid ℝ n m) (r c : ℕ) : D8Direction :=
let e := h r c in
let DIRS : list (D8Direction × ℤ × ℤ × ℝ) :=
  [ (D8Direction.E, 1, 0, 1.0),
    (D8Direction.SE, 1, 1, 2.0),
    (D8Direction.S, 0, 1, 1.0),
    (D8Direction.SW, -1, 1, 2.0),
    (D8Direction.W, -1, 0, 1.0),
    (D8Direction.NW, -1, -1, 2.0),
    (D8Direction.N, 0, -1, 1.0),
    (D8Direction.NE, 1, -1, 2.0) ] in
let best := DIRS.filter_map (λ ⟨dir, dp, dq, dist2⟩,
  let rr := r + dq in
  let cc := c + dp in
  if 0 ≤ rr ∧ rr < n ∧ 0 ≤ cc ∧ cc < m then
    let drop := e - h rr cc in
    if drop > 0 then
      some (dir, (drop * drop) / dist2)
    else
      none
  else
    none) in
if best.empty then
  D8Direction.NoFlow
else
  (best.max_by (λ ⟨_, p⟩ ⟨_, q⟩, p ≤ q)).1

-- Define the function to create a planar DEM grid
def plane_grid (A B C : ℝ) (n m : ℕ) : Grid ℝ n m :=
λ r c, A * (r : ℝ) + B * (c : ℝ) + C

-- Define the function to get the flow direction for all interior cells
def interior_flows (A B C : ℝ) (n m : ℕ) : list D8Direction :=
list.pmap (λ r, list.pmap (λ c, d8_at A B C n m (plane_grid A B C n m) r c) (fin.range (m - 2) 1)) (fin.range (n - 2) 1)

-- Prove that the D8 flow direction is constant across interior cells that share the same (A, B, w)
theorem d8_flow_constant_on_plane (A B : ℝ) (hA : A > 0) (hB : B > 0) (n m : ℕ) (hnm : 3 ≤ n ∧ 3 ≤ m) :
  ∀ (C1 C2 : ℝ) (r c : ℕ) (hr : 1 ≤ r ∧ r < n - 1) (hc : 1 ≤ c ∧ c < m - 1),
  d8_at A B C1 n m (plane_grid A B C1 n m) r c = d8_at A B C2 n m (plane_grid A B C2 n m) r c :=
begin
  intros C1 C2 r c hr hc,
  -- Calculate the elevation at the center cell
  let e1 := (plane_grid A B C1 n m) r c,
  let e2 := (plane_grid A B C2 n m) r c,
  -- Calculate the elevation at the neighboring cells
  let e1_NE := (plane_grid A B C1 n m) (r - 1) (c + 1),
  let e1_N := (plane_grid A B C1 n m) (r - 1) c,
  let e1_NW := (plane_grid A B C1 n m) (r - 1) (c - 1),
  let e1_W := (plane_grid A B C1 n m) r (c - 1),
  let e1_SW := (plane_grid A B C1 n m) (r + 1) (c - 1),
  let e1_S := (plane_grid A B C1 n m) (r + 1) c,
  let e1_SE := (plane_grid A B C1 n m) (r + 1) (c + 1),
  let e1_E := (plane_grid A B C1 n m) r (c + 1),

  let e2_NE := (plane_grid A B C2 n m) (r - 1) (c + 1),
  let e2_N := (plane_grid A B C2 n m) (r - 1) c,
  let e2_NW := (plane_grid A B C2 n m) (r - 1) (c - 1),
  let e2_W := (plane_grid A B C2 n m) r (c - 1),
  let e2_SW := (plane_grid A B C2 n m) (r + 1) (c - 1),
  let e2_S := (plane_grid A B C2 n m) (r + 1) c,
  let e2_SE := (plane_grid A B C2 n m) (r + 1) (c + 1),
  let e2_E := (plane_grid A B C2 n m) r (c + 1),

  -- Prove that the elevation differences are the same for both grids
  have h_diff_NE : e1 - e1_NE = e2 - e2_NE, by simp [e1, e1_NE, e2, e2_NE, plane_grid],
  have h_diff_N : e1 - e1_N = e2 - e2_N, by simp [e1, e1_N, e2, e2_N, plane_grid],
  have h_diff_NW : e1 - e1_NW = e2 - e2_NW, by simp [e1, e1_NW, e2, e2_NW, plane_grid],
  have h_diff_W : e1 - e1_W = e2 - e2_W, by simp [e1, e1_W, e2, e2_W, plane_grid],
  have h_diff_SW : e1 - e1_SW = e2 - e2_SW, by simp [e1, e1_SW, e2, e2_SW, plane_grid],
  have h_diff_S : e1 - e1_S = e2 - e2_S, by simp [e1, e1_S, e2, e2_S, plane_grid],
  have h_diff_SE : e1 - e1_SE = e2 - e2_SE, by simp [e1, e1_SE, e2, e2_SE, plane_grid],
  have h_diff_E : e1 - e1_E = e2 - e2_E, by simp [e1, e1_E, e2, e2_E, plane_grid],

  -- Prove that the flow direction is the same for both grids
  have h_flow_NE : (e1 - e1_NE) * (e1 - e1_NE) / 2.0 = (e2 - e2_NE) * (e2 - e2_NE) / 2.0, by simp [h_diff_NE],
  have h_flow_N : (e1 - e1_N) * (e1 - e1_N) / 1.0 = (e2 - e2_N) * (e2 - e2_N) / 1.0, by simp [h_diff_N],
  have h_flow_NW : (e1 - e1_NW) * (e1 - e1_NW) / 2.0 = (e2 - e2_NW) * (e2 - e2_NW) / 2.0, by simp [h_diff_NW],
  have h_flow_W : (e1 - e1_W) * (e1 - e1_W) / 1.0 = (e2 - e2_W) * (e2 - e2_W) / 1.0, by simp [h_diff_W],
  have h_flow_SW : (e1 - e1_SW) * (e1 - e1_SW) / 2.0 = (e2 - e2_SW) * (e2 - e2_SW) / 2.0, by simp [h_diff_SW],
  have h_flow_S : (e1 - e1_S) * (e1 - e1_S) / 1.0 = (e2 - e2_S) * (e2 - e2_S) / 1.0, by simp [h_diff_S],
  have h_flow_SE : (e1 - e1_SE) * (e1 - e1_SE) / 2.0 = (e2 - e2_SE) * (e2 - e2_SE) / 2.0, by simp [h_diff_SE],
  have h_flow_E : (e1 - e1_E) * (e1 - e1_E) / 1.0 = (e2 - e2_E) * (e2 - e2_E) / 1.0, by simp [h_diff_E],

  -- Since the flow direction is determined by the maximum of these values, and they are all equal,
  -- the flow direction must be the same for both grids
  have h_flow_same : d8_at A B C1 n m (plane_grid A B C1 n m) r c = d8_at A B C2 n m (plane_grid A B C2 n m) r c,
  { simp [d8_at, h_flow_NE, h_flow_N, h_flow_NW, h_flow_W, h_flow_SW, h_flow_S, h_flow_SE, h_flow_E] },
  exact h_flow_same,
end

end VeriGIS
