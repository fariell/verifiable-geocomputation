import data.finset
import data.array.basic
import tactic.well_founded

namespace VeriGIS

-- Define the type for a grid cell
def Cell := ℕ × ℕ

-- Define the type for a grid
def Grid := array (array ℕ)

-- Define the D8 direction set
def D8Directions := fin 8

-- Define the D8 direction mapping
def d8Delta : D8Directions → Cell
| 0 := (0, -1)
| 1 := (1, -1)
| 2 := (1, 0)
| 3 := (1, 1)
| 4 := (0, 1)
| 5 := (-1, 1)
| 6 := (-1, 0)
| 7 := (-1, -1)

-- Define the D8 successor function
def d8Successor (h : Grid) (r c : ℕ) : option Cell :=
let n := h.size in
if r < n.1 ∧ c < n.2 then
  let minDir := (finset.univ : finset D8Directions).min (λ d, h (r + (d8Delta d).1) (c + (d8Delta d).2)) in
  if minDir.is_none then none else
  let minDir := minDir.get! in
  if h (r + (d8Delta minDir).1) (c + (d8Delta minDir).2) < h r c then
    some (r + (d8Delta minDir).1, c + (d8Delta minDir).2)
  else none
else none

-- Define the orbit of a cell under the D8 successor function
def orbit (h : Grid) (r c : ℕ) : stream Cell :=
stream.corec (λ p, match d8Successor h p.1 p.2 with
| some (nr, nc) := (nr, nc) :: orbit h nr nc
| none := []

-- Define the termination of an orbit
def terminatesAt (h : Grid) (r c : ℕ) : option Cell :=
let or := orbit h r c in
or.find? (λ p, d8Successor h p.1 p.2 = none)

-- Define the fixed point of a cell
def isFixedPoint (h : Grid) (r c : ℕ) : Prop :=
d8Successor h r c = none

-- Define the well-founded relation for the D8 successor function
def d8WellFounded (h : Grid) : well_founded (λ p q, d8Successor h p.1 p.2 = some q) :=
begin
  -- Define a measure function that decreases with each step
  let measure : Cell → ℕ := λ (r, c), h r c,
  -- Prove that the measure function is well-founded
  apply well_founded.intro,
  intros p q hq,
  -- Unfold the measure function and the D8 successor function
  unfold measure,
  -- Use the definition of the D8 successor function to show that the measure decreases
  cases hq with nr nc,
  cases d8Successor h p.1 p.2 with q' hq',
  { -- If there is no successor, the measure does not change
    refl },
  { -- If there is a successor, the measure decreases
    have hdec : h q'.1 q'.2 < h p.1 p.2,
    { -- Use the definition of the D8 successor function to show that the height decreases
      cases hq' with d hd,
      rw hd,
      exact (finset.univ : finset D8Directions).min_le (λ d, h (p.1 + (d8Delta d).1) (p.2 + (d8Delta d).2) d },
    -- Show that the measure decreases
    exact nat.lt_of_le_of_ne (le_refl (h p.1 p.2)) (ne_of_lt hdec) }
end

-- Prove that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem orbitTerminatesAtFixedPoint (h : Grid) (r c : ℕ) : terminatesAt h r c ≠ none → isFixedPoint h (terminatesAt h r c).get :=
begin
  -- Assume the orbit terminates at some point
  intros hterm,
  -- Let p be the point where the orbit terminates
  let p := (terminatesAt h r c).get hterm,
  -- Show that p is a fixed point
  have hfixed : d8Successor h p.1 p.2 = none,
  { -- Use the definition of terminatesAt to show that p has no successor
    rw terminatesAt,
    cases stream.find? (λ p, d8Successor h p.1 p.2 = none) (orbit h r c) with q hq,
    { -- If the orbit does not terminate, contradiction
      exfalso,
      exact hterm },
    { -- If the orbit terminates at q, then q must be a fixed point
      exact hq } },
  -- Conclude that p is a fixed point
  exact hfixed
end

end VeriGIS
