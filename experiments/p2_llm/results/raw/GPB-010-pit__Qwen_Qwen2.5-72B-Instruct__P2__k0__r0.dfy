method SteepestDescentFlowDirection(elevation: array2<int>, x: int, y: int) returns (flowDirection: int)
  requires 0 <= x < elevation.Width && 0 <= y < elevation.Height;
  requires elevation != null;
  ensures (flowDirection == 8) ==>
    forall dx, dy :: -1 <= dx <= 1 && -1 <= dy <= 1 && (dx != 0 || dy != 0) ==>
      elevation[x, y] <= elevation[x + dx, y + dy];
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
    flowDirection := 4 * (minDy + 1) + (minDx + 1);
  }
}

method CheckSteepestDescentFlowDirection(elevation: array2<int>, x: int, y: int)
  requires 0 <= x < elevation.Width && 0 <= y < elevation.Height;
  requires elevation != null;
{
  var flowDirection := SteepestDescentFlowDirection(elevation, x, y);
  assert (flowDirection == 8) ==>
    forall dx, dy :: -1 <= dx <= 1 && -1 <= dy <= 1 && (dx != 0 || dy != 0) ==>
      elevation[x, y] <= elevation[x + dx, y + dy];
}
