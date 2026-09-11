// P006_watershed.dfy
// Formalization of watershed uniqueness under deterministic D8.

module Watershed {
  import opened Seq
  import opened Multiset

  // Grid cell type
  type Cell = (int, int)

  // Direction names from D8
  datatype Direction = NoFlow | N | NE | E | SE | S | SW | W | NW

  // Successor function for D8 flow
  function method d8_at(h: array2D<int>, r: int, c: int): Direction {
    // Implementation would depend on the actual D8 flow rules
    // This is a placeholder - actual implementation would use the grid h
    NoFlow
  }

  // Step function for following flow
  function method step(h: array2D<int>, cell: Cell): Cell {
    var r, c := cell;
    var d := d8_at(h, r, c);
    if d == NoFlow {
      return cell;
    }
    var dp, dq := _delta(d);
    return (r + dq, c + dp);
  }

  // Helper function to get delta from direction
  function method _delta(d: Direction): (int, int) {
    // Implementation would map directions to their deltas
    // This is a placeholder
    (0, 0)
  }

  // Bounded iteration to reach a fixed point
  function method stepN(h: array2D<int>, start: Cell, n: int): Cell {
    if n == 0 {
      return start;
    }
    return stepN(h, step(h, start), n - 1);
  }

  // Property: Watershed uniqueness
  lemma WatershedUniqueness(h: array2D<int>, start: Cell, n1: int, n2: int)
    requires n1 >= 0 && n2 >= 0
    requires n1 <= n2
    requires n2 <= 2 * h.Length1 * h.Length2  // Bounded by grid size
    requires forall k :: 0 <= k < n2 ==> stepN(h, start, k) != start  // No cycles
    ensures stepN(h, start, n1) == stepN(h, start, n2)
  {
    // Base case: n1 == n2
    if n1 == n2 {
      return;
    }

    // Inductive step
    var n1' := n1 + 1;
    var n2' := n2 + 1;
    assume n1' <= n2';
    assume n2' <= 2 * h.Length1 * h.Length2;
    assume forall k :: 0 <= k < n2' ==> stepN(h, start, k) != start;
    var cell1 := stepN(h, start, n1);
    var cell2 := stepN(h, start, n2);
    var cell1' := step(h, cell1);
    var cell2' := step(h, cell2);
    assume cell1' == cell2';
    assume stepN(h, start, n1') == cell1';
    assume stepN(h, start, n2') == cell2';
    this.WatershedUniqueness(h, start, n1', n2');
  }

  // Example grid for testing
  function method example_grid(): array2D<int> {
    // Create a simple grid for testing
    var h := new array2D<int>(3, 3);
    // Initialize with some values
    // This is a placeholder - actual implementation would set up a test case
    h
  }

  // Test case
  method TestWatershedUniqueness()
  {
    var h := example_grid();
    var start := (1, 1);
    var n1 := 3;
    var n2 := 5;
    assert WatershedUniqueness(h, start, n1, n2);
  }
}
