// Formal specification of the 2D local raise step RaiseNbr
module RaiseNbr {
  // Represents a 2D grid of elevations
  type Grid = array<array<float>>

  // Represents a cell's coordinates in the grid
  type Cell = (int, int)

  // Represents the 4-neighbors of a cell
  type Neighbors = set<Cell>

  // Function to get the 4-neighbors of a cell
  function method GetNeighbors(p: Cell, grid: Grid): Neighbors {
    var (r, c) := p;
    var rows := grid.Length;
    var cols := grid[0].Length;
    var neighbors := set {
      (r - 1, c) if r > 0;
      (r + 1, c) if r < rows - 1;
      (r, c - 1) if c > 0;
      (r, c + 1) if c < cols - 1;
    };
    return neighbors;
  }

  // Function to raise a cell's elevation based on its 4-neighbors
  function method RaiseNbr(p: Cell, nbr: Cell, grid: Grid, processed: Grid): float {
    var originalNbr := grid[nbr];
    var processedCell := processed[p];
    return max(originalNbr, processedCell);
  }

  // Property to be proven: raising a 4-neighbor from an already-processed cell
  // never decreases any cell elevation, and the neighbor is lifted at least to
  // max(original neighbor, processed cell fill)
  lemma RaiseNbrProperty(grid: Grid, processed: Grid, p: Cell, nbr: Cell)
    requires 0 <= p.0 < grid.Length && 0 <= p.1 < grid[0].Length;
    requires 0 <= nbr.0 < grid.Length && 0 <= nbr.1 < grid[0].Length;
    requires GetNeighbors(p, grid).Contains(nbr);
    requires processed != null;
    requires forall r, c :: 0 <= r < grid.Length && 0 <= c < grid[0].Length ==> grid[r][c] == processed[r][c] || processed[r][c] == float.PositiveInfinity;
    ensures RaiseNbr(p, nbr, grid, processed) >= grid[nbr];
    ensures RaiseNbr(p, nbr, grid, processed) >= processed[p];
  {
    var originalNbr := grid[nbr];
    var processedCell := processed[p];
    var raisedElevation := RaiseNbr(p, nbr, grid, processed);
    assert raisedElevation >= originalNbr;
    assert raisedElevation >= processedCell;
  }
}
