// Formalization of watershed uniqueness under deterministic D8 flow
// Property: If a deterministic successor function reaches an outlet (fixed point)
// from the same start cell in any two finite step counts, those outlets are equal.

// Grid dimensions and cell type
type Cell = (int, int)

// Deterministic successor function: given a cell, returns its unique downstream neighbor
// "NoFlow" is represented by returning the cell itself (a fixed point).
function Succ(cell: Cell): Cell
  // Deterministic: same input always yields same output
  ensures forall c :: Succ(ccc) == Succ(ccc)  // tautology, emphasizes determinism

// Fixed point definition: cell is an outlet if it maps to itself
predicate IsOutlet(cell: Cell) {
  Succ(cell) == cell
}

// Bounded iteration: apply Succ exactly N times
function StepN(start: Cell, N: int): Cell
  requires N >= 0
  decreases N
{
  if N == 0 then start
  else StepN(Succ(start), N - 1)
}

// Main theorem: if we reach an outlet in two different finite step counts,
// the outlets must be the same cell.
theorem WatershedUniqueness(start: Cell, M: int, N: int)
  requires M >= 0 && N >= 0
  requires IsOutlet(StepN(start, M))
  requires IsOutlet(StepN(start, N))
  ensures StepN(start, M) == StepN(start, N)
{
  // Without loss of generality, assume M <= N
  if M <= N {
    // Apply the property that once at an outlet, further steps stay there
    var outletM := StepN(start, M);
    assert IsOutlet(outletM);
    // Lemma: stepping from an outlet yields the same cell
    assert forall k: int | k >= 0 :: StepN(outletM, k) == outletM by {
      var k': int := k;
      while k' > 0
        invariant StepN(outletM, k') == outletM
        decreases k'
      {
        // Single step from outlet stays at outlet
        assert Succ(outletM) == outletM;
        k' := k' - 1;
      }
    }
    // Then StepN(start, N) = StepN(outletM, N-M) = outletM
    calc {
      StepN(start, N);
      == // Split into first M steps and remaining N-M steps
      StepN(StepN(start, M), N - M);
      == { assert StepN(start, M) == outletM; }
      StepN(outletM, N - M);
      == { assert forall k | 0 <= k :: StepN(outletM, k) == outletM; }
      outletM;
      ==
      StepN(start, M);
    }
  } else {
    // Symmetric case: N <= M
    WatershedUniqueness(start, N, M);
  }
}

// Additional lemma: any cell that reaches an outlet in some finite steps
// will reach the same outlet in any larger number of steps.
lemma OutletStable(start: Cell, M: int, N: int)
  requires M >= 0 && N >= 0
  requires M <= N
  requires IsOutlet(StepN(start, M))
  ensures StepN(start, N) == StepN(start, M)
{
  WatershedUniqueness(start, M, N);
}

// Verification of the 4-ring counterexample from the reference implementation
// This shows the theorem's precondition (reaching an outlet) is necessary.
const RingCells: set<Cell> := {(0,0), (0,1), (1,1), (1,0)}
function RingSucc(cell: Cell): Cell
  requires cell in RingCells
{
  match cell
    case (0,0) => (0,1)
    case (0,1) => (1,1)
    case (1,1) => (1,0)
    case (1,0) => (0,0)
}

// In the ring, no cell is an outlet (no fixed point)
lemma RingNoOutlet()
  ensures forall c | c in RingCells :: !IsOutlet(c)
{
  forall c | c in RingCells
    ensures !IsOutlet(c)
  {
    // By definition of RingSucc, each cell maps to a different cell
    assert RingSucc(c) != c;
  }
}

// The ring satisfies the theorem vacuously because the precondition
// (reaching an outlet) never holds for any finite steps.
lemma RingTheoremVacuouslyTrue(start: Cell, M: int, N: int)
  requires start in RingCells
  requires M >= 0 && N >= 0
  ensures IsOutlet(StepN(start, M)) && IsOutlet(StepN(start, N)) ==> 
          StepN(start, M) == StepN(start, N)
{
  // The implication holds because the antecedent is always false
  RingNoOutlet();
  assert !IsOutlet(StepN(start, M)) || !IsOutlet(StepN(start, N));
}
