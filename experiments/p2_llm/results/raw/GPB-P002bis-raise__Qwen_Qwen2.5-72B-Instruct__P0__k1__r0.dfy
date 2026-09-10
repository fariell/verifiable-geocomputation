module PCOMP_1 {

  // Define the grid and its properties
  type Elevation = real
  type Grid = array2<Elevation>

  // Define the 4-neighborhood
  const NBR4: set<(int, int)> := { (-1, 0), (1, 0), (0, -1), (0, 1) }

  // Define the function to get the 4-neighbors of a cell
  function method Get4Neighbors(grid: Grid, r: int, c: int): set<(int, int)>
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
  {
    { (nr, nc) | (dr, dc) in NBR4 :: 0 <= nr < grid.Rows && 0 <= nc < grid.Cols }
  }

  // Define the function to get the elevation of a cell
  function method GetElevation(grid: Grid, r: int, c: int): Elevation
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
  {
    grid[r, c]
  }

  // Define the function to raise a 4-neighbor
  method RaiseNbr(grid: Grid, r: int, c: int, fill: Elevation)
    modifies grid
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires fill >= GetElevation(grid, r, c)
  {
    for (dr, dc) in NBR4 {
      var nr := r + dr;
      var nc := c + dc;
      if 0 <= nr < grid.Rows && 0 <= nc < grid.Cols {
        var originalElevation := GetElevation(grid, nr, nc);
        var newElevation := max(originalElevation, fill);
        grid[nr, nc] := newElevation;
      }
    }
  }

  // Define the property to be proven
  lemma LocalRaiseStepPreservesElevation(grid: Grid, r: int, c: int, fill: Elevation)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires fill >= GetElevation(grid, r, c)
  {
    var originalGrid := grid;
    RaiseNbr(grid, r, c, fill);
    forall nr, nc | (nr, nc) in Get4Neighbors(grid, r, c) {
      assert GetElevation(grid, nr, nc) >= GetElevation(originalGrid, nr, nc);
      assert GetElevation(grid, nr, nc) >= max(GetElevation(originalGrid, nr, nc), fill);
    }
  }

  // Define the main theorem
  theorem MainTheorem(grid: Grid, r: int, c: int, fill: Elevation)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires fill >= GetElevation(grid, r, c)
  {
    LocalRaiseStepPreservesElevation(grid, r, c, fill);
  }
}
