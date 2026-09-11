method RaiseNbr(grid: array2<int>, processed: array2<bool>, i: int, j: int, dx: int, dy: int)
  requires 0 <= i < grid.Length0 && 0 <= j < grid.Length1
  requires 0 <= i+dx < grid.Length0 && 0 <= j+dy < grid.Length1
  requires (dx == 0 && (dy == 1 || dy == -1)) || (dy == 0 && (dx == 1 || dx == -1))
  requires processed[i,j]
  modifies grid
  ensures forall x, y :: 0 <= x < grid.Length0 && 0 <= y < grid.Length1 ==> grid[x,y] >= old(grid)[x,y]
  ensures let ni := i+dx, nj := j+dy in
          grid[ni, nj] >= old(grid)[ni, nj] && grid[ni, nj] >= old(grid)[i, j]
{
  let ni := i + dx;
  let nj := j + dy;
  if grid[ni, nj] < grid[i, j] {
    grid[ni, nj] := grid[i, j];
  }
}
