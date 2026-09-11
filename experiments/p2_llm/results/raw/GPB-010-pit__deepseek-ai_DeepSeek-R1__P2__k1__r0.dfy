datatype Direction = NW | N | NE | W | E | SW | S | SE | NoFlow

function method OffsetToDirection(dx: int, dy: int): Direction {
  if dx == -1 && dy == -1 then NW
  else if dx == -1 && dy == 0 then N
  else if dx == -1 && dy == 1 then NE
  else if dx == 0 && dy == -1 then W
  else if dx == 0 && dy == 1 then E
  else if dx == 1 && dy == -1 then SW
  else if dx == 1 && dy == 0 then S
  else if dx == 1 && dy == 1 then SE
  else NoFlow
}

function method FlowDirection(grid: array2<int>, i: int, j: int): Direction
  requires grid != null
  requires 0 <= i < grid.Length0 && 0 <= j < grid.Length1
{
  var center := grid[i, j];
  var dirs := [(-1,-1), (-1,0), (-1,1), (0,-1), (0,1), (1,-1), (1,0), (1,1)];
  var bestDrop := 0;
  var bestDir: Direction := NoFlow;

  for k := 0 to 7
    invariant bestDir == NoFlow || bestDrop > 0
  {
    var dx := dirs[k].0;
    var dy := dirs[k].1;
    var ni := i + dx;
    var nj := j + dy;
    if 0 <= ni < grid.Length0 && 0 <= nj < grid.Length1 {
      var neighbor := grid[ni, nj];
      if neighbor < center {
        var drop := center - neighbor;
        if bestDir == NoFlow || drop > bestDrop {
          bestDrop := drop;
          bestDir := OffsetToDirection(dx, dy);
        }
      }
    }
  }
  bestDir
}

lemma Theorem(grid: array2<int>, i: int, j: int)
  requires grid != null
  requires 0 <= i < grid.Length0 && 0 <= j < grid.Length1
  requires forall dx: int, dy: int ::
      dx in {-1,0,1} && dy in {-1,0,1} && (dx != 0 || dy != 0) ==>
        (i+dx < 0 || i+dx >= grid.Length0 || j+dy < 0 || j+dy >= grid.Length1) ||
        grid[i+dx, j+dy] >= grid[i, j]
  ensures FlowDirection(grid, i, j) == NoFlow
{
}
