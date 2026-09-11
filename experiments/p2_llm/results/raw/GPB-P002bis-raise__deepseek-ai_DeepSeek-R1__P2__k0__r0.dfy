function max(a: int, b: int): int {
  if a < b then b else a
}

predicate Is4Neighbor(processed: (int, int), neighbor: (int, int)) {
  (processed.0 == neighbor.0 && (processed.1 == neighbor.1 - 1 || processed.1 == neighbor.1 + 1)) ||
  (processed.1 == neighbor.1 && (processed.0 == neighbor.0 - 1 || processed.0 == neighbor.0 + 1))
}

method RaiseNbr(grid: array2<int>, processed: (int, int), neighbor: (int, int))
  requires grid != null
  requires 0 <= processed.0 < grid.Length0 && 0 <= processed.1 < grid.Length1
  requires 0 <= neighbor.0 < grid.Length0 && 0 <= neighbor.1 < grid.Length1
  requires Is4Neighbor(processed, neighbor)
  modifies grid
  ensures grid[neighbor.0, neighbor.1] >= max(old(grid[neighbor.0, neighbor.1]), old(grid[processed.0, processed.1]))
  ensures forall i, j :: 0 <= i < grid.Length0 && 0 <= j < grid.Length1 && (i, j) != (neighbor.0, neighbor.1) ==> grid[i, j] == old(grid[i, j])
{
  var nbrVal := grid[neighbor.0, neighbor.1];
  var procVal := grid[processed.0, processed.1];
  if nbrVal < procVal {
    grid[neighbor.0, neighbor.1] := procVal;
  }
}
