// Formalization of D8 steepest-descent routing pit condition
// Property: If no neighbor is strictly lower than the center, flow direction is NoFlow.

// Grid dimensions are positive
predicate ValidGridDimensions(rows: int, cols: int)
  reads {}
{
  rows > 0 && cols > 0
}

// Valid grid coordinates
predicate InGrid(rows: int, cols: int, r: int, c: int)
  reads {}
  requires ValidGridDimensions(rows, cols)
{
  0 <= r < rows && 0 <= c < cols
}

// D8 neighbor offsets: (dr, dc, distance^2)
type Dir = (name: string, dr: int, dc: int, dist2: int)

// D8 neighbor directions in order: E, SE, S, SW, W, NW, N, NE
const DIRS: seq<Dir> := [
  ("E",  0,  1, 1),
  ("SE", 1,  1, 2),
  ("S",  1,  0, 1),
  ("SW", 1, -1, 2),
  ("W",  0, -1, 1),
  ("NW", -1, -1, 2),
  ("N", -1,  0, 1),
  ("NE", -1,  1, 2)
];

// Height grid as a 2D array
type Grid = array2<int>

// Check if a neighbor is strictly lower than center
predicate NeighborLower(grid: Grid, r: int, c: int, dr: int, dc: int)
  reads grid
  requires InGrid(grid.Length0, grid.Length1, r, c)
  requires InGrid(grid.Length0, grid.Length1, r + dr, c + dc)
{
  grid[r + dr, c + dc] < grid[r, c]
}

// Check if any D8 neighbor is strictly lower
predicate HasLowerNeighbor(grid: Grid, r: int, c: int)
  reads grid
  requires ValidGridDimensions(grid.Length0, grid.Length1)
  requires InGrid(grid.Length0, grid.Length1, r, c)
{
  exists dr, dc :: 
    (dr, dc) in [(0,1),(1,1),(1,0),(1,-1),(0,-1),(-1,-1),(-1,0),(-1,1)] &&
    InGrid(grid.Length0, grid.Length1, r + dr, c + dc) &&
    NeighborLower(grid, r, c, dr, dc)
}

// D8 flow direction result
datatype FlowResult = 
  | Direction(name: string, dr: int, dc: int)
  | NoFlow

// D8 steepest-descent routing function
function D8Flow(grid: Grid, r: int, c: int): FlowResult
  reads grid
  requires ValidGridDimensions(grid.Length0, grid.Length1)
  requires InGrid(grid.Length0, grid.Length1, r, c)
{
  var best: FlowResult := NoFlow;
  var bestPower: int := 0;
  
  for dir in DIRS
    invariant best == NoFlow || exists d :: d in DIRS && best == Direction(d.name, d.dr, d.dc)
    invariant forall d :: d in DIRS && Direction(d.name, d.dr, d.dc) == best ==>
              bestPower == ((grid[r, c] - grid[r + d.dr, c + d.dc])^2) / d.dist2
  {
    var rr := r + dir.dr;
    var cc := c + dir.dc;
    
    if InGrid(grid.Length0, grid.Length1, rr, cc) && grid[rr, cc] < grid[r, c] {
      var drop := grid[r, c] - grid[rr, cc];
      var power := drop * drop / dir.dist2;
      
      if best == NoFlow || power > bestPower {
        best := Direction(dir.name, dir.dr, dir.dc);
        bestPower := power;
      }
    }
  }
  
  best
}

// Main theorem: If no neighbor is strictly lower, result is NoFlow
theorem D8PitNoFlow(grid: Grid, r: int, c: int)
  requires ValidGridDimensions(grid.Length0, grid.Length1)
  requires InGrid(grid.Length0, grid.Length1, r, c)
  requires !HasLowerNeighbor(grid, r, c)
  ensures D8Flow(grid, r, c) == NoFlow
{
  // Expand the definition of HasLowerNeighbor
  assert forall dr, dc :: 
    (dr, dc) in [(0,1),(1,1),(1,0),(1,-1),(0,-1),(-1,-1),(-1,0),(-1,1)] &&
    InGrid(grid.Length0, grid.Length1, r + dr, c + dc) ==>
    !NeighborLower(grid, r, c, dr, dc);
  
  // Show that all D8 directions either are out of bounds or not strictly lower
  forall dir: Dir | dir in DIRS
    ensures !(InGrid(grid.Length0, grid.Length1, r + dir.dr, c + dir.dc) && 
              grid[r + dir.dr, c + dir.dc] < grid[r, c])
  {
    // This follows from the precondition and DIRS covering all 8 neighbors
    assert (dir.dr, dir.dc) in [(0,1),(1,1),(1,0),(1,-1),(0,-1),(-1,-1),(-1,0),(-1,1)];
  }
  
  // Therefore, in D8Flow, no neighbor qualifies for the if-condition
  // So best remains NoFlow throughout the loop
  var result := D8Flow(grid, r, c);
  assert result == NoFlow;
}

// Helper lemma: DIRS contains all 8 neighbor offsets
lemma DIRSCoverage()
  ensures forall dr, dc :: 
    (dr, dc) in [(0,1),(1,1),(1,0),(1,-1),(0,-1),(-1,-1),(-1,0),(-1,1)] ==>
    exists dir :: dir in DIRS && dir.dr == dr && dir.dc == dc
{
  // Verified by construction of DIRS
}
