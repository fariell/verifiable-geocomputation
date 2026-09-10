method HornFiniteDifference(A: real, B: real, C: real, w: real) returns (DzDx: real, DzDy: real)
  requires w > 0
  ensures DzDx == A
  ensures DzDy == B
{
  // Define the grid points
  var x0: real := 0;
  var y0: real := 0;
  var x1: real := w;
  var y1: real := w;

  // Sample the planar surface at the grid points
  var z00: real := A * x0 + B * y0 + C;
  var z01: real := A * x0 + B * y1 + C;
  var z10: real := A * x1 + B * y0 + C;
  var z11: real := A * x1 + B * y1 + C;

  // Compute the finite-difference estimates
  DzDx := (z10 - z00) / w;
  DzDy := (z01 - z00) / w;

  // Verify the estimates
  assert DzDx == A;
  assert DzDy == B;
}
```

This Dafny code formalizes the Horn finite-difference estimates for the planar surface \( z = A \cdot x + B \cdot y + C \) sampled on a regular grid with spacing \( w > 0 \). The method ensures that the finite-difference estimates \( DzDx \) and \( DzDy \) recover \( A \) and \( B \) exactly, as specified. The assertions at the end of the method are used to verify that the estimates match the coefficients \( A \) and \( B \).
