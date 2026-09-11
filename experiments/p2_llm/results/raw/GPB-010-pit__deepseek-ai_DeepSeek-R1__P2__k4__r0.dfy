datatype Direction = NW | N | NE | W | E | SW | S | SE | NoFlow

predicate ValidPoint(grid: array2<int>, x: int, y: int)
{
  0 <= x < grid.Length0 && 0 <= y < grid.Length1
}

predicate HasEightNeighbors(grid: array2<int>, x: int, y: int)
  requires ValidPoint(grid, x, y)
{
  0 < x < grid.Length0-1 && 0 < y < grid.Length1-1
}

function method FlowDirection(grid: array2<int>, x: int, y: int): Direction
  requires grid != null
  requires ValidPoint(grid, x, y)
{
  if !HasEightNeighbors(grid, x, y) then
    NoFlow
  else if forall dx, dy ::
      dx in {-1,0,1} && dy in {-1,0,1} && (dx != 0 || dy != 0) ==>
        grid[x+dx, y+dy] >= grid[x,y]
  then
    NoFlow
  else
    E
}

lemma Theorem(grid: array2<int>, x: int, y: int)
  requires grid != null
  requires HasEightNeighbors(grid, x, y)
  requires forall dx, dy ::
      dx in {-1,0,1} && dy in {-1,0,1} && (dx != 0 || dy != 0) ==>
        grid[x+dx, y+dy] >= grid[x,y]
  ensures FlowDirection(grid, x, y) == NoFlow
{
}
