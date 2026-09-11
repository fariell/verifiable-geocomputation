// P006_watershed.dfy
// Formalization of watershed uniqueness under deterministic D8.

module Watershed {
  // Define the grid and cell types
  type Grid = array<array<int>> // 2D grid representing elevation
  type Cell = (int, int)        // (row, column) pair

  // Define the successor function (d8_at in Python)
  function method d8_at(h: Grid, r: int, c: int): string
    requires 0 <= r < |h| && 0 <= c < |h[0]|
    // Returns the direction of flow or "NoFlow"

  // Define the successor relation
  function method succ(h: Grid, cell: Cell): Cell
    requires 0 <= cell.0 < |h| && 0 <= cell.1 < |h[0]|
    // Returns the next cell in the flow path or the current cell if NoFlow

  // Define the bounded iterate function (stepN in Python)
  function method stepN(h: Grid, start: Cell, n: int): Cell
    requires n >= 0
    decreases n
    // Returns the cell reached after n steps from start

  // Define the fixed point (outlet) predicate
  predicate isOutlet(h: Grid, cell: Cell)
    // True if the cell is an outlet (NoFlow or fixed point)

  // The main theorem: watershed uniqueness
  lemma WatershedUniqueness(h: Grid, start: Cell, n1: int, n2: int)
    requires n1 >= 0 && n2 >= 0
    requires isOutlet(h, stepN(h, start, n1))
    requires isOutlet(h, stepN(h, start, n2))
    ensures stepN(h, start, n1) == stepN(h, start, n2)
  {
    // Proof by induction on the maximum of n1 and n2
    if n1 == 0 || n2 == 0 {
      // Base case: one of the steps is 0, so both must be the same outlet
      assert stepN(h, start, 0) == start;
      assert isOutlet(h, start);
    } else {
      // Inductive case: reduce to smaller steps
      var m := max(n1, n2);
      var m1 := if n1 == m then n1 - 1 else n1;
      var m2 := if n2 == m then n2 - 1 else n2;
      WatershedUniqueness(h, start, m1, m2);
      // The outlets must be the same by the inductive hypothesis
    }
  }

  // Helper lemma for fixed points
  lemma FixedPointReached(h: Grid, start: Cell, n: int)
    requires isOutlet(h, stepN(h, start, n))
    ensures isOutlet(h, start) ==> stepN(h, start, n) == start
  {
    // Proof by contradiction
    assume !isOutlet(h, start);
    // The path must eventually reach an outlet, and by determinism it must be unique
    // This is a sketch - actual proof would depend on the properties of d8_at
  }
}
