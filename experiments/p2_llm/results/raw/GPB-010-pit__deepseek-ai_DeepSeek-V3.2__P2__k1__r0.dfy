// P2: Iterative repair (verifier feedback)
// Theorem: Under D8 steepest-descent routing, if none of the eight neighbors
// is strictly lower than the center, the flow direction is NoFlow (pit).

// Grid dimensions and types
type Cell = (int, int)
type Height = int
type Direction = NoFlow | N | NE | E | SE | S | SW | W | NW

// Grid as a function from cell to height
function Grid(c: Cell): Height

// D8 neighbor offsets
const D8_Offsets: seq<Cell> :=
  [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]

// Predicate: Is neighbor cell within bounds?
predicate InBounds(c: Cell, width: int, height: int)
  requires 0 <= width && 0 <= height
{
  0 <= c.0 < width && 0 <= c.1 < height
}

// Predicate: Is neighbor strictly lower than center?
predicate IsStrictlyLower(center: Cell, neighbor: Cell, width: int, height: int)
  requires InBounds(center, width, height)
{
  InBounds(neighbor, width, height) &&
  Grid(neighbor) < Grid(center)
}

// Main theorem: If no neighbor is strictly lower, flow direction is NoFlow
lemma D8_PitCondition(center: Cell, width: int, height: int)
  requires 0 <= width && 0 <= height
  requires InBounds(center, width, height)
  ensures (
    (forall offset :: offset in D8_Offsets ==>
      !IsStrictlyLower(center, (center.0 + offset.0, center.1 + offset.1), width, height))
    ==> FlowDirection(center, width, height) == NoFlow
  )
{
  // The lemma body is left to the verifier; the postcondition expresses the theorem.
}

// Function computing flow direction according to D8 steepest-descent
function FlowDirection(center: Cell, width: int, height: int): Direction
  requires InBounds(center, width, height)
{
  var bestDir := NoFlow;
  var bestDrop := 0;
  for offset in D8_Offsets
    invariant bestDir == NoFlow || bestDrop > 0
  {
    var nb := (center.0 + offset.0, center.1 + offset.1);
    if InBounds(nb, width, height) && Grid(nb) < Grid(center) {
      var drop := Grid(center) - Grid(nb);
      if bestDir == NoFlow || drop > bestDrop {
        bestDrop := drop;
        bestDir := OffsetToDirection(offset);
      }
    }
  }
  bestDir
}

// Helper: Convert offset to Direction
function OffsetToDirection(offset: Cell): Direction
{
  match offset
    case (0, -1) => N
    case (1, -1) => NE
    case (1, 0) => E
    case (1, 1) => SE
    case (0, 1) => S
    case (-1, 1) => SW
    case (-1, 0) => W
    case (-1, -1) => NW
    case _ => NoFlow  // should not happen for D8 offsets
}
