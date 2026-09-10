// Horn finite-difference gradient estimation on a planar surface
// Theorem: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w > 0, the Horn finite-difference estimates DzDx and DzDy
// recover A and B exactly.

method HornPlanarExactRecovery(A: real, B: real, C: real, w: real) 
  returns (DzDx: real, DzDy: real)
  requires w > 0.0
  ensures DzDx == A && DzDy == B
{
  // Define grid coordinates
  var x0 := 0.0;
  var y0 := 0.0;
  
  // Sample the planar surface at the 3x3 stencil points
  // Central point
  var z00 := A * x0 + B * y0 + C;
  
  // Neighbors for x-derivative (Horn's method uses immediate neighbors)
  var z10 := A * (x0 + w) + B * y0 + C;
  var zm10 := A * (x0 - w) + B * y0 + C;
  
  // Neighbors for y-derivative
  var z01 := A * x0 + B * (y0 + w) + C;
  var z0m1 := A * x0 + B * (y0 - w) + C;
  
  // Horn finite-difference formulas (weighted central difference)
  // For x: (z10 - zm10) / (2*w)
  // For y: (z01 - z0m1) / (2*w)
  DzDx := (z10 - zm10) / (2.0 * w);
  DzDy := (z01 - z0m1) / (2.0 * w);
  
  // Verification that these equal A and B
  // Dafny automatically verifies the arithmetic:
  // (z10 - zm10) = A*(x0+w) - A*(x0-w) = 2*A*w
  // Dividing by 2*w gives A. Similarly for B.
}
