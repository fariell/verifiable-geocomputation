module D8 {
  datatype Direction = E | SE | S | SW | W | NW | N | NE | NoFlow

  const dirs: seq<(Direction, int, int, real)> := [
    (E,  1, 0, 1.0),
    (SE, 1, 1, 2.0),
    (S,  0, 1, 1.0),
    (SW, -1, 1, 2.0),
    (W, -1, 0, 1.0),
    (NW, -1, -1, 2.0),
    (N,  0, -1, 1.0),
    (NE, 1, -1, 2.0)
  ];

  function method d8_at(grid: array2<real>, i: int, j: int): Direction
    requires 0 <= i < grid.Length0
    requires 0 <= j < grid.Length1
  {
    var idx := 0;
    var best := NoFlow;
    var best_p := 0.0;
    while idx < |dirs|
      invariant 0 <= idx <= |dirs|
      invariant best == NoFlow
      invariant best_p == 0.0
    {
      var d := dirs[idx];
      var ni := i + d.1;
      var nj := j + d.2;
      if 0 <= ni < grid.Length0 && 0 <= nj < grid.Length1 {
        var drop := grid[i,j] - grid[ni,nj];
        if drop > 0.0 {
          var p := (drop * drop) / d.3;
          if best == NoFlow || p > best_p {
            best, best_p := d.0, p;
          }
        }
      }
      idx := idx + 1;
    }
    best
  }

  lemma PitCondition(grid: array2<real>, i: int, j: int)
    requires 0 <= i < grid.Length0 && 0 <= j < grid.Length1
    requires forall di, dj : int ::
      di in {-1,0,1} && dj in {-1,0,1} && (di != 0 || dj != 0) ==>
        0 <= i+di < grid.Length0 && 0 <= j+dj < grid.Length1
    requires forall di, dj : int ::
      di in {-1,0,1} && dj in {-1,0,1} && (di != 0 || dj != 0) ==>
        grid[i+di, j+dj] >= grid[i,j]
    ensures d8_at(grid, i, j) == NoFlow
  {
    forall idx | 0 <= idx < |dirs| 
      ensures let d := dirs[idx] in 
              0 <= i + d.1 < grid.Length0 && 
              0 <= j + d.2 < grid.Length1 &&
              grid[i, j] - grid[i + d.1, j + d.2] <= 0.0
    {
      var d := dirs[idx];
      assert d.1 in {-1,0,1} && d.2 in {-1,0,1} && (d.1 != 0 || d.2 != 0);
    }
  }
}
