datatype Direction = E | SE | S | SW | W | NW | N | NE | NoFlow

const Directions: set<Direction> = {E, SE, S, SW, W, NW, N, NE};

function method GetOffset(dir: Direction): (int, int, real) {
  match dir
    case E  => ( 1,  0, 1.0)
    case SE => ( 1,  1, 2.0)
    case S  => ( 0,  1, 1.0)
    case SW => (-1,  1, 2.0)
    case W  => (-1,  0, 1.0)
    case NW => (-1, -1, 2.0)
    case N  => ( 0, -1, 1.0)
    case NE => ( 1, -1, 2.0)
    case NoFlow => (0, 0, 0.0)
}

function method D8(grid: array<array<real>>, i: int, j: int): Direction
  requires grid.Length > 0
  requires forall r :: 0 <= r < grid.Length ==> grid[r] != null && grid[r].Length == grid[0].Length
  requires 0 <= i < grid.Length && 0 <= j < grid[0].Length
{
  var bestDir: Direction := NoFlow;
  var bestPower: real := 0.0;
  var dirList := [E, SE, S, SW, W, NW, N, NE];
  var idx := 0;
  
  while idx < |dirList|
    invariant 0 <= idx <= |dirList|
    invariant bestDir == NoFlow
    invariant bestPower == 0.0
  {
    var dir := dirList[idx];
    var (dp, dq, dist2) := GetOffset(dir);
    var ni := i + dq;
    var nj := j + dp;
    
    if ni >= 0 && ni < grid.Length && nj >= 0 && nj < grid[0].Length {
      var drop := grid[i][j] - grid[ni][nj];
      if drop > 0.0 {
        var power := (drop * drop) / dist2;
        if bestDir == NoFlow || power > bestPower {
          bestDir := dir;
          bestPower := power;
        }
      }
    }
    idx := idx + 1;
  }
  bestDir
}

lemma PitConditionImpliesNoFlow(grid: array<array<real>>, i: int, j: int)
  requires grid.Length > 0
  requires forall r :: 0 <= r < grid.Length ==> grid[r] != null && grid[r].Length == grid[0].Length
  requires 0 <= i < grid.Length && 0 <= j < grid[0].Length
  requires forall dir :: dir in Directions ==> 
      var (dp, dq, _) := GetOffset(dir);
      var ni := i + dq;
      var nj := j + dp;
      (0 <= ni < grid.Length && 0 <= nj < grid[0].Length) ==> grid[ni][nj] >= grid[i][j]
  ensures D8(grid, i, j) == NoFlow
{
}
