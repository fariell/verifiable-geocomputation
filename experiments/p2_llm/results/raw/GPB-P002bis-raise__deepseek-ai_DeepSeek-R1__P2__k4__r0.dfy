function abs(x: int): int {
  if x >= 0 then x else -x
}

function max(a: int, b: int): int {
  if a >= b then a else b
}

method RaiseNbr(grid: array2<int>, processed: array2<bool>, c_row: int, c_col: int, dx: int, dy: int)
  requires grid != null && processed != null
  requires grid.Length0 == processed.Length0 && grid.Length1 == processed.Length1
  requires 0 <= c_row < grid.Length0 && 0 <= c_col < grid.Length1
  requires processed[c_row, c_col] == true
  requires abs(dx) + abs(dy) == 1
  requires 0 <= c_row+dx < grid.Length0 && 0 <= c_col+dy < grid.Length1
  modifies grid
  ensures grid[c_row, c_col] == old(grid[c_row, c_col])
  ensures forall i,j :: 0<=i<grid.Length0 && 0<=j<grid.Length1 && (i != c_row+dx || j != c_col+dy) ==> grid[i,j] == old(grid[i,j])
  ensures grid[c_row+dx, c_col+dy] >= old(grid[c_row+dx, c_col+dy])
  ensures grid[c_row+dx, c_col+dy] >= old(grid[c_row, c_col])
  ensures grid[c_row+dx, c_col+dy] == max(old(grid[c_row+dx, c_col+dy]), old(grid[c_row, c_col]))
{
  var n_row := c_row + dx;
  var n_col := c_col + dy;
  var neighbor_old := grid[n_row, n_col];
  var fill := grid[c_row, c_col];
  grid[n_row, n_col] := max(neighbor_old, fill);
}
