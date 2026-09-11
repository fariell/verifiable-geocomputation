// Formal specification of the 2D local raise step RaiseNbr
module RaiseNbr {
  // Represents a 2D grid of elevations
  type Grid = array<array<float>>

  // 4-neighbors: up, down, left, right
  const NBR4: (int, int)[] = [(-1, 0), (1, 0), (0, -1), (0, 1)]

  // Original elevation grid
  var original: Grid
  // Processed (filled) elevation grid
  var processed: Grid
  // Neighbor to be raised
  var nbr: (int, int)
  // Current cell (already processed)
  var cell: (int, int)

  // Property to prove:
  // Raising a 4-neighbor from an already-processed cell never decreases any cell elevation,
  // and the neighbor is lifted at least to max(original neighbor, processed cell fill).
  lemma RaiseNbrProperty()
    requires original != null && processed != null
    requires original.Length == processed.Length && original[0].Length == processed[0].Length
    requires 0 <= cell.Item1 < original.Length && 0 <= cell.Item2 < original[0].Length
    requires 0 <= nbr.Item1 < original.Length && 0 <= nbr.Item2 < original[0].Length
    requires (nbr.Item1 == cell.Item1 + 1 || nbr.Item1 == cell.Item1 - 1 || nbr.Item1 == cell.Item1) &&
             (nbr.Item2 == cell.Item2 + 1 || nbr.Item2 == cell.Item2 - 1 || nbr.Item2 == cell.Item2) &&
             !(nbr.Item1 == cell.Item1 && nbr.Item2 == cell.Item2) // nbr is a 4-neighbor
    ensures processed[nbr.Item1][nbr.Item2] >= original[nbr.Item1][nbr.Item2]
    ensures processed[nbr.Item1][nbr.Item2] >= processed[cell.Item1][cell.Item2]
    ensures processed[nbr.Item1][nbr.Item2] == max(original[nbr.Item1][nbr.Item2], processed[cell.Item1][cell.Item2])
  {
    // The neighbor is raised to the maximum of its original elevation and the processed cell's elevation
    // This ensures it never decreases and meets the specified condition
    processed[nbr.Item1][nbr.Item2] := max(original[nbr.Item1][nbr.Item2], processed[cell.Item1][cell.Item2]);
    
    // Verify the properties
    assert processed[nbr.Item1][nbr.Item2] >= original[nbr.Item1][nbr.Item2];
    assert processed[nbr.Item1][nbr.Item2] >= processed[cell.Item1][cell.Item2];
    assert processed[nbr.Item1][nbr.Item2] == max(original[nbr.Item1][nbr.Item2], processed[cell.Item1][cell.Item2]);
  }

  // Helper function to compute maximum of two values
  function method max(a: float, b: float): float
    ensures max(a, b) == a || max(a, b) == b
    ensures max(a, b) >= a && max(a, b) >= b
  {
    if a >= b then a else b
  }
}
