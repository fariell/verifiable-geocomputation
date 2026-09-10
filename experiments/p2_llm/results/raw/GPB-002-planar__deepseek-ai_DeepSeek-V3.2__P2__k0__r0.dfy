// Horn finite-difference gradient estimation on a planar surface
// Theorem: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w > 0, the Horn finite-difference estimates DzDx and DzDy
// recover A and B exactly.

method HornPlanarExactRecovery(A: real, B: real, C: real, w: real) 
  returns (DzDx: real, DzDy: real)
  requires w > 0.0
  ensures DzDx == A && DzDy == B
{
  // Define grid points around a central point (x0, y0)
  var x0 := 0.0;
  var y0 := 0.0;

  // Sample the planar surface z = A*x + B*y + C at the 3x3 stencil points
  // Central point
  var z00 := A * x0 + B * y0 + C;
  // East and West neighbors
  var z10 := A * (x0 + w) + B * y0 + C;
  var zm10 := A * (x0 - w) + B * y0 + C;
  // North and South neighbors
  var z01 := A * x0 + B * (y0 + w) + C;
  var z0m1 := A * x0 + B * (y0 - w) + C;
  // Diagonal neighbors (used in Horn's method)
  var z11 := A * (x0 + w) + B * (y0 + w) + C;
  var zm1m1 := A * (x0 - w) + B * (y0 - w) + C;
  var z1m1 := A * (x0 + w) + B * (y0 - w) + C;
  var zm11 := A * (x0 - w) + B * (y0 + w) + C;

  // Horn finite-difference gradient estimation (3x3 Sobel-like kernel)
  // Dz/Dx estimate
  DzDx := ( (z11 + 2.0 * z10 + z1m1) - (zm11 + 2.0 * zm10 + zm1m1) ) / (8.0 * w);
  // Dz/Dy estimate
  DzDy := ( (z11 + 2.0 * z01 + zm11) - (z1m1 + 2.0 * z0m1 + zm1m1) ) / (8.0 * w);

  // Verification that these simplify to A and B exactly
  // The following assertions are proved by Dafny's real arithmetic
  assert DzDx == A by {
    calc {
      DzDx;
      ==
      ( (z11 + 2.0 * z10 + z1m1) - (zm11 + 2.0 * zm10 + zm1m1) ) / (8.0 * w);
      ==
      ( (A*(x0+w) + B*(y0+w) + C + 2.0*(A*(x0+w) + B*y0 + C) + A*(x0+w) + B*(y0-w) + C)
        - (A*(x0-w) + B*(y0+w) + C + 2.0*(A*(x0-w) + B*y0 + C) + A*(x0-w) + B*(y0-w) + C)
      ) / (8.0 * w);
      ==
      ( (A*x0 + A*w + B*y0 + B*w + C + 2.0*A*x0 + 2.0*A*w + 2.0*B*y0 + 2.0*C + A*x0 + A*w + B*y0 - B*w + C)
        - (A*x0 - A*w + B*y0 + B*w + C + 2.0*A*x0 - 2.0*A*w + 2.0*B*y0 + 2.0*C + A*x0 - A*w + B*y0 - B*w + C)
      ) / (8.0 * w);
      ==
      ( (4.0*A*x0 + 4.0*A*w + 4.0*B*y0 + 4.0*C)
        - (4.0*A*x0 - 4.0*A*w + 4.0*B*y0 + 4.0*C)
      ) / (8.0 * w);
      ==
      (8.0 * A * w) / (8.0 * w);
      ==
      A;
    }
  }

  assert DzDy == B by {
    calc {
      DzDy;
      ==
      ( (z11 + 2.0 * z01 + zm11) - (z1m1 + 2.0 * z0m1 + zm1m1) ) / (8.0 * w);
      ==
      ( (A*(x0+w) + B*(y0+w) + C + 2.0*(A*x0 + B*(y0+w) + C) + A*(x0-w) + B*(y0+w) + C)
        - (A*(x0+w) + B*(y0-w) + C + 2.0*(A*x0 + B*(y0-w) + C) + A*(x0-w) + B*(y0-w) + C)
      ) / (8.0 * w);
      ==
      ( (A*x0 + A*w + B*y0 + B*w + C + 2.0*A*x0 + 2.0*B*y0 + 2.0*B*w + 2.0*C + A*x0 - A*w + B*y0 + B*w + C)
        - (A*x0 + A*w + B*y0 - B*w + C + 2.0*A*x0 + 2.0*B*y0 - 2.0*B*w + 2.0*C + A*x0 - A*w + B*y0 - B*w + C)
      ) / (8.0 * w);
      ==
      ( (4.0*A*x0 + 4.0*B*y0 + 4.0*B*w + 4.0*C)
        - (4.0*A*x0 + 4.0*B*y0 - 4.0*B*w + 4.0*C)
      ) / (8.0 * w);
      ==
      (8.0 * B * w) / (8.0 * w);
      ==
      B;
    }
  }
}
