datatype Dir = E | SE | S | SW | W | NW | N | NE | NoFlow

function method D8(grid: array2<real>, i: int, j: int): Dir
  requires 0 <= i < grid.Length0
  requires 0 <= j < grid.Length1
{
  var bestDir := NoFlow;
  var bestP := 0.0;

  // Process E (1,0)
  if 0 <= j+1 < grid.Length1 {
    let drop := grid[i,j] - grid[i, j+1];
    if drop > 0.0 {
      let p := drop * drop;
      if bestDir == NoFlow || p > bestP {
        bestDir := E;
        bestP := p;
      }
    }
  }
  // Process SE (1,1)
  if 0 <= i+1 < grid.Length0 && 0 <= j+1 < grid.Length1 {
    let drop := grid[i,j] - grid[i+1, j+1];
    if drop > 0.0 {
      let p := (drop * drop) / 2.0;
      if bestDir == NoFlow || p > bestP {
        bestDir := SE;
        bestP := p;
      }
    }
  }
  // Process S (0,1)
  if 0 <= i+1 < grid.Length0 {
    let drop := grid[i,j] - grid[i+1, j];
    if drop > 0.0 {
      let p := drop * drop;
      if bestDir == NoFlow || p > bestP {
        bestDir := S;
        bestP := p;
      }
    }
  }
  // Process SW (-1,1)
  if 0 <= i+1 < grid.Length0 && 0 <= j-1 {
    let drop := grid[i,j] - grid[i+1, j-1];
    if drop > 0.0 {
      let p := (drop * drop) / 2.0;
      if bestDir == NoFlow || p > bestP {
        bestDir := SW;
        bestP := p;
      }
    }
  }
  // Process W (-1,0)
  if 0 <= j-1 {
    let drop := grid[i,j] - grid[i, j-1];
    if drop > 0.0 {
      let p := drop * drop;
      if bestDir == NoFlow || p > bestP {
        bestDir := W;
        bestP := p;
      }
    }
  }
  // Process NW (-1,-1)
  if 0 <= i-1 && 0 <= j-1 {
    let drop := grid[i,j] - grid[i-1, j-1];
    if drop > 0.0 {
      let p := (drop * drop) / 2.0;
      if bestDir == NoFlow || p > bestP {
        bestDir := NW;
        bestP := p;
      }
    }
  }
  // Process N (0,-1)
  if 0 <= i-1 {
    let drop := grid[i,j] - grid[i-1, j];
    if drop > 0.0 {
      let p := drop * drop;
      if bestDir == NoFlow || p > bestP {
        bestDir := N;
        bestP := p;
      }
    }
  }
  // Process NE (1,-1)
  if 0 <= i-1 && 0 <= j+1 < grid.Length1 {
    let drop := grid[i,j] - grid[i-1, j+1];
    if drop > 0.0 {
      let p := (drop * drop) / 2.0;
      if bestDir == NoFlow || p > bestP {
        bestDir := NE;
        bestP := p;
      }
    }
  }

  bestDir
}

lemma PitLemma(grid: array2<real>, i: int, j: int)
  requires 0 <= i < grid.Length0
  requires 0 <= j < grid.Length1
  requires forall dx,dy :: 
      (dx,dy) in set{(1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1), (0,-1), (1,-1)} ==> 
        let ni := i + dy, nj := j + dx in
        (0 <= ni < grid.Length0 && 0 <= nj < grid.Length1) ==> 
        grid[ni, nj] >= grid[i, j]
  ensures D8(grid, i, j) == NoFlow
{
  // Proof follows from condition and D8 definition
}
