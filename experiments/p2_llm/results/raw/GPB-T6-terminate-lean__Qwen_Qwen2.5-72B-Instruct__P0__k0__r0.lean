import data.nat.basic
import data.array.basic
import data.set.finite
import tactic

namespace VeriGIS

-- Define the grid and its properties
structure Grid (α : Type*) :=
  (height : ℕ)
  (width : ℕ)
  (cells : array (height * width) α)

-- Define the D8 direction set
inductive D8Direction
| NoFlow
| North
| Northeast
| East
| Southeast
| South
| Southwest
| West
| Northwest

-- Define the D8 direction mapping
def D8Delta : D8Direction → ℤ × ℤ
| NoFlow := (0, 0)
| North := (0, -1)
| Northeast := (1, -1)
| East := (1, 0)
| Southeast := (1, 1)
| South := (0, 1)
| Southwest := (-1, 1)
| West := (-1, 0)
| Northwest := (-1, -1)

-- Define the D8 successor function
def d8Successor (h : Grid ℕ) (r c : ℕ) : D8Direction :=
  let neighbors := [(r, c - 1), (r + 1, c - 1), (r + 1, c), (r + 1, c + 1), (r, c + 1), (r - 1, c + 1), (r - 1, c), (r - 1, c - 1)]
  let valid_neighbors := neighbors.filter (λ p, 0 ≤ p.1 ∧ p.1 < h.height ∧ 0 ≤ p.2 ∧ p.2 < h.width)
  let min_neighbor := valid_neighbors.min (λ p q, h.cells.get (p.1 * h.width + p.2) < h.cells.get (q.1 * h.width + q.2))
  if min_neighbor.is_some then
    match min_neighbor.get with
    | (r', c') := if h.cells.get (r * h.width + c) > h.cells.get (r' * h.width + c') then
      match (r' - r, c' - c) with
      | (0, -1) := North
      | (1, -1) := Northeast
      | (1, 0) := East
      | (1, 1) := Southeast
      | (0, 1) := South
      | (-1, 1) := Southwest
      | (-1, 0) := West
      | (-1, -1) := Northwest
      | _ := NoFlow
    end
  else NoFlow

-- Define the orbit of a cell under the D8 successor function
def orbit (h : Grid ℕ) (r c : ℕ) : stream (ℕ × ℕ) :=
  let rec follow (r c : ℕ) : stream (ℕ × ℕ) :=
    (r, c) :: (match d8Successor h r c with
      | NoFlow := stream.nil
      | dir := let (dp, dq) := D8Delta dir in follow (r + dq) (c + dp)
      end)
  follow r c

-- Define the termination of an orbit
def orbitTerminates (h : Grid ℕ) (r c : ℕ) : Prop :=
  ∃ (n : ℕ), orbit h r c n = (r, c)

-- Define the fixed point of an orbit
def orbitFixedPoint (h : Grid ℕ) (r c : ℕ) : Prop :=
  d8Successor h r c = NoFlow

-- Define the strict descent property
def strictDescent (h : Grid ℕ) (r c : ℕ) : Prop :=
  let (dp, dq) := D8Delta (d8Successor h r c) in
  0 < h.cells.get (r * h.width + c) - h.cells.get ((r + dq) * h.width + (c + dp))

-- Prove that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem orbitTerminatesAtFixedPoint (h : Grid ℕ) (r c : ℕ) (h_strict : strictDescent h r c) :
  orbitTerminates h r c → orbitFixedPoint h r c :=
begin
  intros h_term,
  cases h_term with n h_term,
  induction n with n ih,
  { simp [orbit, h_term], exact h_strict },
  { simp [orbit, h_term],
    cases d8Successor h r c with dir,
    { exact h_term },
    { let (dp, dq) := D8Delta dir,
      have h_next : orbit h (r + dq) (c + dp) n = (r + dq, c + dp), from ih,
      simp [orbit, h_next],
      exact h_strict },
  end

-- Define the 4-ring example
def ringExample : Grid ℕ :=
{ height := 2,
  width := 2,
  cells := array.of_fn (λ i, if i = 0 ∨ i = 3 then 10 else 0) }

-- Prove that the 4-ring example does not terminate
theorem ringExampleDoesNotTerminate : ¬ orbitTerminates ringExample 0 0 4 :=
begin
  intro h_term,
  cases h_term with n h_term,
  induction n with n ih,
  { simp [orbit, h_term], exact (D8Delta North = (0, -1)) },
  { simp [orbit, h_term],
    cases d8Successor ringExample 0 0 with dir,
    { exact (D8Delta North = (0, -1)) },
    { let (dp, dq) := D8Delta dir,
      have h_next : orbit ringExample (0 + dq) (0 + dp) n = (0 + dq, 0 + dp), from ih,
      simp [orbit, h_next],
      exact (D8Delta North = (0, -1)) },
  end

end VeriGIS
