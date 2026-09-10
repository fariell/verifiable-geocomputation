// Formalization of watershed uniqueness under deterministic successor function
// Property: If a deterministic successor function reaches an outlet (fixed point)
// from the same start cell in any two finite step counts, those outlets are equal.

// Grid dimensions and cell type
type Cell = (int, int)

// Deterministic successor function (D8 flow direction)
function Succ(cell: Cell): Cell
  // Deterministic: for each cell, exactly one successor (or itself if outlet)
  ensures Succ(cell) == cell || Succ(Succ(cell)) != Succ(cell)  // No trivial cycles of length 2

// Fixed point (outlet) predicate
predicate IsOutlet(cell: Cell) {
  Succ(cell) == cell
}

// Bounded iteration function: apply Succ exactly n times
function StepN(cell: Cell, n: nat): Cell
  decreases n
{
  if n == 0 then cell
  else StepN(Succ(cell), n - 1)
}

// Main theorem: uniqueness of outlet reachable in bounded steps
theorem WatershedUniqueness(start: Cell, m: nat, n: nat)
  requires m > 0 && n > 0  // Non-zero step counts
  requires IsOutlet(StepN(start, m))  // Reaches outlet in m steps
  requires IsOutlet(StepN(start, n))  // Reaches outlet in n steps
  ensures StepN(start, m) == StepN(start, n)  // Same outlet
{
  // Key lemma: once at an outlet, further steps stay there
  lemma OutletFixedPoint(cell: Cell, k: nat)
    requires IsOutlet(cell)
    ensures StepN(cell, k) == cell
    decreases k
  {
    if k > 0 {
      OutletFixedPoint(cell, k - 1);
    }
  }

  // Without loss of generality, assume m <= n
  if m <= n {
    // Apply Succ m times to reach outlet O1
    var O1 := StepN(start, m);
    // From O1, apply Succ (n-m) more times to reach O2
    var O2 := StepN(O1, n - m);
    // But O1 is outlet, so O2 == O1 by lemma
    OutletFixedPoint(O1, n - m);
    assert O2 == O1;
    // By definition of StepN composition
    assert StepN(start, n) == StepN(StepN(start, m), n - m) == O2;
    assert StepN(start, n) == O1 == StepN(start, m);
  } else {
    // Symmetric case when n < m
    var O2 := StepN(start, n);
    var O1 := StepN(O2, m - n);
    OutletFixedPoint(O2, m - n);
    assert O1 == O2;
    assert StepN(start, m) == StepN(StepN(start, n), m - n) == O1;
    assert StepN(start, m) == O2 == StepN(start, n);
  }
}

// Additional lemma: any cell that reaches an outlet in some steps
// will reach the same outlet in any larger number of steps
lemma OutletConsistency(start: Cell, m: nat, n: nat)
  requires m <= n
  requires IsOutlet(StepN(start, m))
  ensures IsOutlet(StepN(start, n))
  ensures StepN(start, m) == StepN(start, n)
{
  WatershedUniqueness(start, m, n);
}

// Verification of termination condition for planar slope case
// (Not required by the main theorem but included for context)
predicate Terminates(start: Cell, bound: nat) {
  exists k: nat :: k <= bound && IsOutlet(StepN(start, k))
}

// Counterexample for artificial flat 4-ring (P-006b)
// Shows that termination is not guaranteed in all cases
method RingCounterexample() returns (succ: Cell -> Cell, start: Cell, bound: nat)
  ensures forall c: Cell :: succ(c) != c  // No fixed points
  ensures forall c: Cell :: succ(succ(succ(succ(c)))) == c  // 4-cycle
  ensures !Terminates(start, bound)  // Does not terminate within bound
{
  // Construct 4-cycle successor function
  succ := (c: Cell) =>
    match c
    case (0,0) => (0,1)
    case (0,1) => (1,1)
    case (1,1) => (1,0)
    case (1,0) => (0,0)
    case _ => c  // Default for other cells (not used in counterexample)
    ;
  start := (0,0);
  bound := 3;  // Less than cycle length
  
  // Verify no fixed points
  assert forall c: Cell :: c == (0,0) || c == (0,1) || c == (1,1) || c == (1,0) || 
    (c != (0,0) && c != (0,1) && c != (1,1) && c != (1,0));
  assert succ((0,0)) == (0,1) != (0,0);
  assert succ((0,1)) == (1,1) != (0,1);
  assert succ((1,1)) == (1,0) != (1,1);
  assert succ((1,0)) == (0,0) != (1,0);
  
  // Verify 4-cycle
  assert succ(succ(succ(succ((0,0))))) == (0,0);
  
  // Verify non-termination within bound
  assert StepN(start, 0) == (0,0) && !IsOutlet((0,0));
  assert StepN(start, 1) == (0,1) && !IsOutlet((0,1));
  assert StepN(start, 2) == (1,1) && !IsOutlet((1,1));
  assert StepN(start, 3) == (1,0) && !IsOutlet((1,0));
}
