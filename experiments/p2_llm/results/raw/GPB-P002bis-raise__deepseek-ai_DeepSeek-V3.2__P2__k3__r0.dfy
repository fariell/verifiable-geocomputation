method RaiseNbrPreservesElevation(
  grid: array2<int>,
  processedRow: int, processedCol: int,
  neighborRow: int, neighborCol: int
)
  requires grid != null
  requires 0 <= processedRow < grid.Length0 && 0 <= processedCol < grid.Length1
  requires 0 <= neighborRow < grid.Length0 && 0 <= neighborCol < grid.Length1
  requires |processedRow - neighborRow| + |processedCol - neighborCol| == 1  // 4-neighbor
  requires grid[processedRow, processedCol] >= old(grid)[processedRow, processedCol]  // already processed
  requires forall r, c :: 0 <= r < grid.Length0 && 0 <= c < grid.Length1 ==> grid[r, c] >= old(grid)[r, c]
  ensures forall r, c :: 0 <= r < grid.Length0 && 0 <= c < grid.Length1 ==> grid[r, c] >= old(grid)[r, c]
  ensures grid[neighborRow, neighborCol] >= old(grid)[neighborRow, neighborCol]
  ensures grid[neighborRow, neighborCol] >= max(old(grid)[neighborRow, neighborCol], old(grid)[processedRow, processedCol])
{
  // Assume the RaiseNbr operation is performed
  assume grid[neighborRow, neighborCol] := max(grid[neighborRow, neighborCol], grid[processedRow, processedCol]);

  // Postcondition 1: No cell elevation decreased
  assert forall r, c :: 0 <= r < grid.Length0 && 0 <= c < grid.Length1 ==> grid[r, c] >= old(grid)[r, c] by {
    forall r, c | 0 <= r < grid.Length0 && 0 <= c < grid.Length1
      ensures grid[r, c] >= old(grid)[r, c]
    {
      if r == neighborRow && c == neighborCol {
        // Updated neighbor
        assert grid[r, c] >= old(grid)[r, c] by {
          assert grid[r, c] == max(old(grid)[r, c], grid[processedRow, processedCol]);
          assert grid[processedRow, processedCol] >= old(grid)[processedRow, processedCol];
        }
      } else {
        // Unchanged cell
        assert grid[r, c] == old(grid)[r, c];
      }
    }
  }

  // Postcondition 2: Neighbor lifted at least to max(original neighbor, processed cell fill)
  assert grid[neighborRow, neighborCol] >= max(old(grid)[neighborRow, neighborCol], old(grid)[processedRow, processedCol]) by {
    calc >= {
      grid[neighborRow, neighborCol];
      max(old(grid)[neighborRow, neighborCol], grid[processedRow, processedCol]);
      max(old(grid)[neighborRow, neighborCol], old(grid)[processedRow, processedCol]);
    }
  }
}
