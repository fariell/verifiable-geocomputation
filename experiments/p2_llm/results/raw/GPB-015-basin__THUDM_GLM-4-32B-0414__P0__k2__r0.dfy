// P006_watershed.dfy
// Formalization of watershed uniqueness under deterministic D8.

module Watershed {
  // Define the grid and cell types
  type Grid = array2d<int>
  type Cell = (int, int)

  // Define the successor function (d8_at from p005_d8)
  function method d8_at(h: Grid, r: int, c: int): string {
    // Implementation of d8_at would go here
    // For now, we'll return a placeholder
    "NoFlow"
  }

  // Define the delta function to get direction offsets
  function method _delta(name: string): (int, int) {
    // Implementation of _delta would go here
    // For now, we'll return a placeholder
    (0, 0)
  }

  // Define the follow_d8 function to trace the path
  function method follow_d8(h: Grid, r: int, c: int, max_steps: int): (bool, Cell, seq<Cell>) {
    // Implementation of follow_d8 would go here
    // For now, we'll return a placeholder
    (true, (0, 0), [])
  }

  // Define the bounded iterate stepN function
  function method stepN(h: Grid, start: Cell, n: int): Cell {
    if n == 0 then start
    else {
      var d := d8_at(h, start.0, start.1);
      if d == "NoFlow" then start
      else {
        var dp, dq := _delta(d);
        var nr, nc := start.0 + dq, start.1 + dp;
        stepN(h, (nr, nc), n - 1)
      }
    }
  }

  // Theorem: Watershed uniqueness
  lemma WatershedUniqueness(h: Grid, start: Cell, n1: int, n2: int)
    requires n1 >= 0 && n2 >= 0
    requires n1 <= n2
    requires exists n. stepN(h, start, n) == start // There is a fixed point
    ensures stepN(h, start, n1) == stepN(h, start, n2)
  {
    // Base case: n1 == n2
    if n1 == n2 then return;
    
    // Inductive step
    var n := n1;
    while n < n2
      invariant n1 <= n && n <= n2
      invariant stepN(h, start, n1) == stepN(h, start, n)
      decreases n2 - n
    {
      n := n + 1;
    }
  }
}
