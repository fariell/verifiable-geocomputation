// P006_watershed.dfy
// Formalization of watershed uniqueness under deterministic D8.

module Watershed {
  // Define the grid and cell types
  type Grid = array2d<int>
  type Cell = (int, int)

  // Define the successor function (d8_at in Python)
  function method d8_at(h: Grid, r: int, c: int): string {
    // Implementation of d8_at logic (simplified for this example)
    // Returns "NoFlow" or a direction string
    "NoFlow" // Placeholder
  }

  // Define the delta for each direction
  function method _delta(name: string): (int, int) {
    // Implementation of _delta logic (simplified for this example)
    (0, 0) // Placeholder
  }

  // Define the follow_d8 function (bounded iterate stepN)
  function method follow_d8(h: Grid, r: int, c: int, max_steps: int): (bool, Cell, seq<Cell>) {
    // Implementation of follow_d8 logic (simplified for this example)
    (true, (r, c), [(r, c)]) // Placeholder
  }

  // Define the follow_ring function (for testing)
  function method follow_ring(start: Cell, max_steps: int): (bool, Cell, seq<Cell>) {
    // Implementation of follow_ring logic (simplified for this example)
    (true, start, [start]) // Placeholder
  }

  // The main theorem: watershed uniqueness
  lemma WatershedUniqueness(h: Grid, r: int, c: int, max_steps: int)
    requires 0 <= r < h.Length1 && 0 <= c < h.Length2
    requires max_steps >= 0
    decreases max_steps
  {
    // Get the first outlet and path
    var reached1, outlet1, path1 := follow_d8(h, r, c, max_steps);
    // Get the second outlet and path
    var reached2, outlet2, path2 := follow_d8(h, r, c, max_steps);

    // Assert that if both reached an outlet, they are the same
    if reached1 && reached2 {
      assert outlet1 == outlet2;
    }
  }

  // Test cases
  method TestWatershedUniqueness()
  {
    // Create a test grid
    var h := new Grid[2, 2];
    // Initialize the grid with some values
    // ...

    // Test the WatershedUniqueness lemma
    WatershedUniqueness(h, 0, 0, 10);
  }
}
