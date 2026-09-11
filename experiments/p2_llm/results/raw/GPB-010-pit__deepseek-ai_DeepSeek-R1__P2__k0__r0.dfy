datatype Direction = NW | N | NE | W | E | SW | S | SE | NoFlow

type Grid = array2<int>

predicate ValidGrid(grid: Grid) {
  grid.Length0 > 0 && grid.Length1 > 0
}

predicate HasAllNeighbors(grid: Grid, i: int, j: int)
  requires ValidGrid(grid)
{
  0 < i < grid.Length0 - 1 && 0 < j < grid.Length1 - 1
}

predicate IsNoFlow(grid: Grid, i: int, j: int)
  requires ValidGrid(grid) && HasAllNeighbors(grid, i, j)
  reads grid
{
  forall di, dj : int | 
    di in {-1,0,1} && dj in {-1,0,1} && (di != 0 || dj != 0) 
  :: 
    grid[i + di, j + dj] >= grid[i, j]
}

function method GetFlowDirection(grid: Grid, i: int, j: int): Direction
  requires ValidGrid(grid) && HasAllNeighbors(grid, i, j)
  reads grid
  ensures IsNoFlow(grid, i, j) <==> dir == NoFlow
{
  if IsNoFlow(grid, i, j) then NoFlow else N
}

lemma Theorem(grid: Grid, i: int, j: int)
  requires ValidGrid(grid)
  requires HasAllNeighbors(grid, i, j)
  requires IsNoFlow(grid, i, j)
  ensures GetFlowDirection(grid, i, j) == NoFlow
{
}
