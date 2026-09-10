method HornFiniteDifference(A: real, B: real, C: real, w: real) returns (DzDx: real, DzDy: real)
  requires w > 0
  ensures DzDx == A
  ensures DzDy == B
{
  // Define the grid points
  var x0: real := 0.0;
  var y0: real := 0.0;
  var x1: real := x0 + w;
  var y1: real := y0 + w;

  // Sample the planar surface at these points
  var z00: real := A * x0 + B * y0 + C;
  var z10: real := A * x1 + B * y0 + C;
  var z01: real := A * x0 + B * y1 + C;
  var z11: real := A * x1 + B * y1 + C;

  // Compute the finite differences
  DzDx := (z10 - z00) / w;
  DzDy := (z01 - z00) / w;

  // Verify the results
  assert DzDx == A;
  assert DzDy == B;
}
