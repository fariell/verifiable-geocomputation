datatype Direction = NW | N | NE | W | E | SW | S | SE | NoFlow

const D8: set<(int, int)> :=
  set{(-1,-1), (-1,0), (-1,1),
      (0,-1),           (0,1),
      (1,-1),  (1,0),  (1,1)};

function convert(dx: int, dy: int): Direction {
  if dx == -1 && dy == -1 then NW
  else if dx == -1 && dy == 0 then N
  else if dx == -1 && dy == 1 then NE
  else if dx == 0 && dy == -1 then W
  else if dx == 0 && dy == 1 then E
  else if dx == 1 && dy == -1 then SW
  else if dx == 1 && dy == 0 then S
  else if dx == 1 && dy == 1 then SE
  else NoFlow  // Not called for D8 members
}

ghost function flow_direction(grid: array2<int>, i: int, j: int): Direction
  requires 0 <= i < grid.Length0
  requires 0 <= j < grid.Length1
{
  if forall dx, dy | (dx,dy) in D8 ::
      !(0 <= i+dx < grid.Length0 && 0 <= j+dy < grid.Length1) ||
      grid[i+dx, j+dy] >= grid[i, j]
  then NoFlow
  else
    var (dx,dy) :| (dx,dy) in D8 &&
        0 <= i+dx < grid.Length0 &&
        0 <= j+dy < grid.Length1 &&
        grid[i+dx, j+dy] < grid[i, j];
    convert(dx,dy)
}

ghost lemma Theorem(grid: array2<int>, i: int, j: int)
  requires 0 <= i < grid.Length0
  requires 0 <= j < grid.Length1
  requires forall dx, dy ::
      (dx,dy) in D8 ==>
      (i+dx < 0 || i+dx >= grid.Length0 || j+dy < 0 || j+dy >= grid.Length1) ||
      grid[i+dx, j+dy] >= grid[i, j]
  ensures flow_direction(grid, i, j) == NoFlow
{
  // Proof follows directly from flow_direction definition
}
