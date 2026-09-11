import Mathlib.Tactic

namespace VeriGIS.Watershed

-- Define the finite cell set and successor relation
structure Cell where
  r : ℕ
  c : ℕ
deriving Repr

def Cell.succ (h : Cell) : Cell := 
  let next := d8_at h.r h.c
  if next == "NoFlow" then h else
    let dp, dq := _delta next
    Cell.mk (h.r + dq) (h.c + dp)

-- Define the orbit as a sequence of cells
def Cell.orbit (start : Cell) : ℕ → Cell
| 0 => start
| n + 1 => Cell.succ (Cell.orbit start n)

-- Define fixed point predicate
def Cell.isFixedPoint (c : Cell) : Prop := 
  Cell.succ c = c

-- Define termination predicate
def Cell.terminates (start : Cell) : Prop := 
  ∃ n, Cell.isFixedPoint (Cell.orbit start n)

-- Define the well-founded measure: number of steps until fixed point
def Cell.measure (start : Cell) : ℕ := 
  Nat.find (Nat.wfPred (Cell.terminates start))

-- Prove termination using well-founded induction
theorem Cell.orbit_terminates (start : Cell) : Cell.terminates start := by
  -- Base case: if start is already a fixed point
  cases' Cell.measure start with n hn
  simp [Cell.isFixedPoint]
  -- Inductive step: show that the successor has a smaller measure
  simp [Cell.measure, Nat.wfPred, Cell.succ]
  apply Nat.find_min
  -- Show that the successor relation is well-founded
  intro n hn
  simp [Cell.measure, Nat.wfPred, Cell.succ] at hn
  apply Nat.wfPred.wf
  intro n
  apply Cell.terminates.mpr
  exists n
  simp [Cell.orbit, Cell.succ]

end VeriGIS.Watershed
