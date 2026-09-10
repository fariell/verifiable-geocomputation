// Formalization of watershed uniqueness under deterministic D8 flow
// Property: If a deterministic successor function reaches an outlet (fixed point)
// from the same start cell in any two finite step counts, those outlets are equal.

// Grid dimensions and cell type
type Cell = (int, int)
type Grid = array2<int>

// Deterministic successor function: returns the unique downstream neighbor or the cell itself if it's an outlet
predicate IsOutlet(succ: Cell -> Cell, cell: Cell)
  reads this
{
  succ(cell) == cell
}

// Bounded iteration without searching for fixed points
function StepN(succ: Cell -> Cell, start: Cell, n: nat): Cell
  reads this
  decreases n
{
  if n == 0 then start
  else StepN(succ, succ(start), n - 1)
}

// Main theorem: if two bounded iterations from the same start both reach outlets,
// then those outlets must be the same cell.
theorem WatershedUniqueness(succ: Cell -> Cell, start: Cell, m: nat, n: nat)
  requires m > 0 && n > 0
  requires IsOutlet(succ, StepN(succ, start, m))
  requires IsOutlet(succ, StepN(succ, start, n))
  ensures StepN(succ, start, m) == StepN(succ, start, n)
{
  // Key insight: once an outlet is reached, further iterations stay at that outlet
  var outlet_m := StepN(succ, start, m);
  var outlet_n := StepN(succ, start, n);
  
  // Show that outlet_m is a fixed point
  assert IsOutlet(succ, outlet_m);
  assert forall k: nat :: StepN(succ, outlet_m, k) == outlet_m;
  
  // Similarly for outlet_n
  assert IsOutlet(succ, outlet_n);
  assert forall k: nat :: StepN(succ, outlet_n, k) == outlet_n;
  
  // Consider the maximum of m and n
  var max := if m > n then m else n;
  
  // Both iterations reach the same cell at step max
  calc {
    StepN(succ, start, max);
    == // Case analysis on which is larger
    { if m > n {
        calc {
          StepN(succ, start, max);
          == // max = m
          StepN(succ, start, m);
          == // outlet_m is fixed point
          StepN(succ, outlet_m, max - m);
          ==
          outlet_m;
        }
      } else {
        calc {
          StepN(succ, start, max);
          == // max = n
          StepN(succ, start, n);
          == // outlet_n is fixed point
          StepN(succ, outlet_n, max - n);
          ==
          outlet_n;
        }
      }
    }
    ==
    { if m > n then outlet_m else outlet_n; }
  }
  
  // Therefore both outlets are the same
  assert StepN(succ, start, m) == StepN(succ, start, n);
}

// Additional lemma: once an outlet is reached, all further steps remain there
lemma OutletFixedPoint(succ: Cell -> Cell, cell: Cell, k: nat)
  requires IsOutlet(succ, cell)
  ensures StepN(succ, cell, k) == cell
  decreases k
{
  if k == 0 {
    // Base case
  } else {
    // Inductive step
    OutletFixedPoint(succ, cell, k - 1);
  }
}

// Verification for the artificial flat 4-ring counterexample
// This shows the theorem's precondition (reaching an outlet) is necessary
const RingCells: set<Cell> := {(0,0), (0,1), (1,1), (1,0)}
const RingSucc: Cell -> Cell = 
  (c: Cell) requires c in RingCells =>
    match c
      case (0,0) => (0,1)
      case (0,1) => (1,1)
      case (1,1) => (1,0)
      case (1,0) => (0,0)

lemma RingNoOutlet()
  ensures forall c: Cell :: c in RingCells ==> !IsOutlet(RingSucc, c)
{
  // All cells in the ring have different successors
  forall c: Cell | c in RingCells
    ensures !IsOutlet(RingSucc, c)
  {
    // By definition of RingSucc, no cell maps to itself
  }
}

lemma RingCycles()
  ensures forall c: Cell, n: nat :: c in RingCells ==> StepN(RingSucc, c, n) in RingCells
  decreases n
{
  // The ring stays within the 4 cells
  forall c: Cell, n: nat | c in RingCells
    ensures StepN(RingSucc, c, n) in RingCells
    decreases n
  {
    if n == 0 {
    } else {
      RingCycles();
    }
  }
}
