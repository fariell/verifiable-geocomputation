import Mathlib.Tactic

namespace VeriGIS.Watershed

-- Define the cell type and successor relation
structure Cell where
  r : Nat
  c : Nat
  deriving Repr, DecidableEq

-- Define the D8 successor relation (from p005_d8)
inductive D8Successor : Cell → Cell → Prop
| N {r c} : D8Successor {r, c} {r, c+1}
| NE {r c} : D8Successor {r, c} {r+1, c+1}
| E {r c} : D8Successor {r, c} {r+1, c}
| SE {r c} : D8Successor {r, c} {r+1, c-1}
| S {r c} : D8Successor {r, c} {r, c-1}
| SW {r c} : D8Successor {r, c} {r-1, c-1}
| W {r c} : D8Successor {r, c} {r-1, c}
| NW {r c} : D8Successor {r, c} {r-1, c+1}

-- Define a strict descent relation (h[r,c] > h[succ(r,c)])
inductive StrictDescent : Cell → Cell → Prop
| mk {h : Cell → ℝ} {r c} : h {r, c} > h (D8Successor.dest {r, c}) → StrictDescent {r, c} (D8Successor.dest {r, c})

-- Define an orbit as a sequence of cells
def Orbit : Type := List Cell

-- Define a fixed point as a cell with no successor
def FixedPoint (c : Cell) := ¬∃ c', D8Successor c c'

-- Define a strict descent orbit
def StrictDescentOrbit (h : Cell → ℝ) : Orbit → Prop
| [] => False
| [c] => FixedPoint c
| c :: c' :: cs => StrictDescent h c c' ∧ StrictDescentOrbit (c' :: cs)

-- Define the termination measure (number of cells in orbit)
def TerminationMeasure : Orbit → Nat
| [] => 0
| c :: cs => 1 + TerminationMeasure cs

-- The main theorem: every strict descent orbit terminates at a fixed point
theorem StrictDescentOrbit_terminates (h : Cell → ℝ) (orbit : Orbit) (h_strict : StrictDescentOrbit h orbit) :
    orbit.find? (FixedPoint ∘ (fun c => D8Successor.dest c)) ≠ none := by
  induction' orbit with
  | nil => simp [TerminationMeasure]
  | cons c cs ih =>
    cases' orbit.find? (FixedPoint ∘ (fun c => D8Successor.dest c)) with
    | some c => exact some c
    | none =>
      have h1 := h_strict
      cases' h1 with h1 h1
      simp [TerminationMeasure]
      contradiction

-- Define a finite cell set
def FiniteCellSet (max_r max_c : Nat) : Set Cell := fun c => c.r < max_r ∧ c.c < max_c

-- The main theorem for finite cell sets
theorem StrictDescentOrbit_terminates_finite (h : Cell → ℝ) (orbit : Orbit) (h_strict : StrictDescentOrbit h orbit)
    (finite : orbit ⊆ FiniteCellSet max_r max_c) :
    orbit.find? (FixedPoint ∘ (fun c => D8Successor.dest c)) ≠ none := by
  induction' orbit with
  | nil => simp [TerminationMeasure]
  | cons c cs ih =>
    cases' orbit.find? (FixedPoint ∘ (fun c => D8Successor.dest c)) with
    | some c => exact some c
    | none =>
      have h1 := h_strict
      cases' h1 with h1 h1
      simp [TerminationMeasure]
      contradiction
      have h2 := ih
      simp [TerminationMeasure] at h2
      contradiction

end VeriGIS.Watershed
