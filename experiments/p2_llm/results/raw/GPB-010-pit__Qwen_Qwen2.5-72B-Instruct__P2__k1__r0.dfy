method SteepestDescentFlowDirection(elevation: array2<int>, x: int, y: int) returns (flowDirection: int)
  requires 0 <= x < elevation.Width && 0 <= y < elevation.Height
  requires elevation != null
  ensures (flowDirection == 8) ==>
    forall dx, dy :: -1 <= dx <= 1 && -1 <= dy <= 1 && (dx != 0 || dy != 0) ==>
      elevation[x, y] <= elevation[x + dx, y + dy]
{
  var minElevation := elevation[x, y];
  var minDx := 0;
  var minDy := 0;

  for dx in -1..1 do
    for dy in -1..1 do
      if dx != 0 || dy != 0 {
        var nx := x + dx;
        var ny := y + dy;
        if 0 <= nx < elevation.Width && 0 <= ny < elevation.Height {
          if elevation[nx, ny] < minElevation {
            minElevation := elevation[nx, ny];
            minDx := dx;
            minDy := dy;
          }
        }
      }

  if minDx == 0 && minDy == 0 {
    flowDirection := 8; // NoFlow
  } else {
    flowDirection := FlowDirection(minDx, minDy);
  }
}

function FlowDirection(dx: int, dy: int): int
  requires -1 <= dx <= 1 && -1 <= dy <= 1
  requires dx != 0 || dy != 0
{
  if dx == -1 && dy == -1 { 1 }
  else if dx == 0 && dy == -1 { 2 }
  else if dx == 1 && dy == -1 { 3 }
  else if dx == -1 && dy == 0 { 4 }
  else if dx == 1 && dy == 0 { 6 }
  else if dx == -1 && dy == 1 { 7 }
  else if dx == 0 && dy == 1 { 8 }
  else { 5 } // dx == 1 && dy == 1
}

lemma NoFlowIfNoLowerNeighbor(elevation: array2<int>, x: int, y: int)
  requires 0 <= x < elevation.Width && 0 <= y < elevation.Height
  requires elevation != null
  ensures (forall dx, dy :: -1 <= dx <= 1 && -1 <= dy <= 1 && (dx != 0 || dy != 0) ==>
           elevation[x, y] <= elevation[x + dx, y + dy]) ==>
           SteepestDescentFlowDirection(elevation, x, y) == 8
{
  var flowDirection := SteepestDescentFlowDirection(elevation, x, y);
  if flowDirection != 8 {
    var minDx, minDy := 0, 0;
    for dx in -1..1 do
      for dy in -1..1 do
        if dx != 0 || dy != 0 {
          var nx := x + dx;
          var ny := y + dy;
          if 0 <= nx < elevation.Width && 0 <= ny < elevation.Height {
            if elevation[nx, ny] < elevation[x, y] {
              minDx := dx;
              minDy := dy;
            }
          }
        }
    assert minDx != 0 || minDy != 0; // There must be a strictly lower neighbor
  }
}
