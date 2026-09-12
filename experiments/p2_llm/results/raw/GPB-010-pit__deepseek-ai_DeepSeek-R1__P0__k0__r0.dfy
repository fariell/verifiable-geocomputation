datatype Direction = E | SE | S | SW | W | NW | N | NE | NoFlow

function method D8(grid: array2<real>, i: int, j: int): Direction
  requires 1 <= i < grid.Length0 - 1
  requires 1 <= j < grid.Length1 - 1
{
  var best := NoFlow;
  var best_p := 0.0;
  
  // Process E neighbor (0,1)
  if grid[i, j] - grid[i, j+1] > 0.0 {
    let drop := grid[i, j] - grid[i, j+1];
    let p := drop * drop;
    if best == NoFlow || p > best_p {
      best, best_p := E, p;
    }
  }
  
  // Process SE neighbor (1,1)
  if grid[i, j] - grid[i+1, j+1] > 0.0 {
    let drop := grid[i, j] - grid[i+1, j+1];
    let p := (drop * drop) / 2.0;
    if best == NoFlow || p > best_p {
      best, best_p := SE, p;
    }
  }
  
  // Process S neighbor (1,0)
  if grid[i, j] - grid[i+1, j] > 0.0 {
    let drop := grid[i, j] - grid[i+1, j];
    let p := drop * drop;
    if best == NoFlow || p > best_p {
      best, best_p := S, p;
    }
  }
  
  // Process SW neighbor (1,-1)
  if grid[i, j] - grid[i+1, j-1] > 0.0 {
    let drop := grid[i, j] - grid[i+1, j-1];
    let p := (drop * drop) / 2.0;
    if best == NoFlow || p > best_p {
      best, best_p := SW, p;
    }
  }
  
  // Process W neighbor (0,-1)
  if grid[i, j] - grid[i, j-1] > 0.0 {
    let drop := grid[i, j] - grid[i, j-1];
    let p := drop * drop;
    if best == NoFlow || p > best_p {
      best, best_p := W, p;
    }
  }
  
  // Process NW neighbor (-1,-1)
  if grid[i, j] - grid[i-1, j-1] > 0.0 {
    let drop := grid[i, j] - grid[i-1, j-1];
    let p := (drop * drop) / 2.0;
    if best == NoFlow || p > best_p {
      best, best_p := NW, p;
    }
  }
  
  // Process N neighbor (-1,0)
  if grid[i, j] - grid[i-1, j] > 0.0 {
    let drop := grid[i, j] - grid[i-1, j];
    let p := drop * drop;
    if best == NoFlow || p > best_p {
      best, best_p := N, p;
    }
  }
  
  // Process NE neighbor (-1,1)
  if grid[i, j] - grid[i-1, j+1] > 0.0 {
    let drop := grid[i, j] - grid[i-1, j+1];
    let p := (drop * drop) / 2.0;
    if best == NoFlow || p > best_p {
      best, best_p := NE, p;
    }
  }
  
  best
}

lemma Theorem(grid: array2<real>, i: int, j: int)
  requires 1 <= i < grid.Length0 - 1
  requires 1 <= j < grid.Length1 - 1
  requires forall di: int, dj: int :: 
      (di,dj) in { (0,1), (1,1), (1,0), (1,-1), (0,-1), (-1,-1), (-1,0), (-1,1) } 
      ==> grid[i+di, j+dj] >= grid[i, j]
  ensures D8(grid, i, j) == NoFlow
{
}
