module RaiseNbrProperty {

  // Define a 2D grid as a map from (row, col) pairs to elevations
  type Grid = map<(int, int), real>;

  // Define the 4-neighborhood of a cell
  const NBR4: set<(int, int)> := {(-1, 0), (1, 0), (0, -1), (0, 1)};

  // Function to get the 4-neighbors of a cell (r, c) within a grid of size (rows, cols)
  function method GetNeighbors(rows: int, cols: int, r: int, c: int): set<(int, int)> {
    { (nr, nc) | (nr, nc) in NBR4 && 0 <= r + nr < rows && 0 <= c + nc < cols }
  }

  // Function to get the elevation of a cell (r, c) in the grid
  function method Elevation(grid: Grid, r: int, c: int): real {
    grid[r, c]
  }

  // Function to get the original elevation of a cell (r, c) in the grid
  function method OriginalElevation(grid: Grid, r: int, c: int): real {
    grid[r, c]
  }

  // Function to get the elevation of a cell (r, c) after processing
  function method ProcessedElevation(grid: Grid, r: int, c: int): real {
    grid[r, c]
  }

  // Function to raise a neighbor (nr, nc) from a processed cell (r, c)
  method RaiseNbr(grid: Grid, rows: int, cols: int, r: int, c: int, nr: int, nc: int) returns (newGrid: Grid) {
    requires 0 <= r < rows && 0 <= c < cols;
    requires (nr, nc) in GetNeighbors(rows, cols, r, c);
    requires 0 <= nr < rows && 0 <= nc < cols;
    ensures newGrid == grid ++ [(nr, nc) -> max(OriginalElevation(grid, nr, nc), ProcessedElevation(grid, r, c))];
    ensures forall i, j | 0 <= i < rows && 0 <= j < cols :: (i, j) != (nr, nc) ==> newGrid[i, j] == grid[i, j];
    ensures Elevation(newGrid, nr, nc) >= Elevation(grid, nr, nc);
    ensures Elevation(newGrid, nr, nc) >= Elevation(grid, r, c);

    newGrid := grid;
    newGrid[nr, nc] := max(OriginalElevation(grid, nr, nc), ProcessedElevation(grid, r, c));
  }

  // Lemma to prove the property: raising a 4-neighbor from an already-processed cell
  // never decreases any cell elevation, and the neighbor is lifted at least to max(original neighbor, processed cell fill)
  lemma LocalRaiseStepPreservesElevation(grid: Grid, rows: int, cols: int, r: int, c: int, nr: int, nc: int) {
    requires 0 <= r < rows && 0 <= c < cols;
    requires (nr, nc) in GetNeighbors(rows, cols, r, c);
    requires 0 <= nr < rows && 0 <= nc < cols;
    var newGrid := RaiseNbr(grid, rows, cols, r, c, nr, nc);
    assert Elevation(newGrid, nr, nc) >= Elevation(grid, nr, nc);
    assert Elevation(newGrid, nr, nc) >= Elevation(grid, r, c);
  }

  // Function to check if a grid satisfies the property for all cells and their neighbors
  function method CheckGridProperty(grid: Grid, rows: int, cols: int): bool {
    forall r, c, nr, nc | 0 <= r < rows && 0 <= c < cols && (nr, nc) in GetNeighbors(rows, cols, r, c) :: 
      Elevation(RaiseNbr(grid, rows, cols, r, c, nr, nc), nr, nc) >= Elevation(grid, nr, nc) &&
      Elevation(RaiseNbr(grid, rows, cols, r, c, nr, nc), nr, nc) >= Elevation(grid, r, c)
  }

  // Lemma to prove the property for the entire grid
  lemma GridRaiseNbrPreservesElevation(grid: Grid, rows: int, cols: int) {
    requires 0 < rows && 0 < cols;
    assert CheckGridProperty(grid, rows, cols);
  }

}
