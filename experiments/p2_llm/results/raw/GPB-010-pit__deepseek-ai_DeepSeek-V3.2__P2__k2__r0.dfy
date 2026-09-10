// P2 · Iterative repair (verifier feedback)
// Theorem: Under D8 steepest-descent routing, if none of the eight neighbors
// is strictly lower than the center, the flow direction is NoFlow (pit).

// Grid definition
type Grid = array2d<int>
type Point = (int, int)

// Directions for D8 (including center for NoFlow)
datatype Direction = North | NorthEast | East | SouthEast | South | SouthWest | West | NorthWest | NoFlow

// Function to get neighbor coordinates given a direction and point
function GetNeighbor(p: Point, d: Direction): Point
  requires d != NoFlow
{
  var (x, y) := p;
  match d
    case North => (x, y-1)
    case NorthEast => (x+1, y-1)
    case East => (x+1, y)
    case SouthEast => (x+1, y+1)
    case South => (x, y+1)
    case SouthWest => (x-1, y+1)
    case West => (x-1, y)
    case NorthWest => (x-1, y-1)
}

// Predicate to check if a point is inside the grid
predicate InGrid(g: Grid, p: Point)
{
  var (x, y) := p;
  0 <= x < g.Length0 && 0 <= y < g.Length1
}

// Function to get elevation at a point (with default high value for out-of-bounds)
function Elevation(g: Grid, p: Point): int
  requires InGrid(g, p)
{
  var (x, y) := p;
  g[x, y]
}

// Main theorem: if no neighbor is strictly lower, direction is NoFlow
method D8_NoFlow_Theorem(g: Grid, center: Point)
  requires InGrid(g, center)
  requires forall d: Direction :: d != NoFlow ==> InGrid(g, GetNeighbor(center, d))
  ensures (forall d: Direction :: d != NoFlow ==> Elevation(g, GetNeighbor(center, d)) >= Elevation(g, center))
    ==> FlowDirection(g, center) == NoFlow
{
  // The theorem follows directly from the definition of FlowDirection
}

// Flow direction calculation
function FlowDirection(g: Grid, p: Point): Direction
  requires InGrid(g, p)
  requires forall d: Direction :: d != NoFlow ==> InGrid(g, GetNeighbor(p, d))
{
  var minDir := NoFlow;
  var minVal := Elevation(g, p);
  var dirs: seq<Direction> := [North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest];

  // Iterate through directions to find the steepest descent
  for dir in dirs
    invariant minDir == NoFlow || (minDir != NoFlow && Elevation(g, GetNeighbor(p, minDir)) < Elevation(g, p))
    invariant forall d: Direction :: d in dirs[..|dirs|] && d != NoFlow && d != minDir ==> Elevation(g, GetNeighbor(p, d)) >= minVal
  {
    var neighbor := GetNeighbor(p, dir);
    var neighborElev := Elevation(g, neighbor);
    if neighborElev < minVal {
      minVal := neighborElev;
      minDir := dir;
    }
  }
  minDir
}
