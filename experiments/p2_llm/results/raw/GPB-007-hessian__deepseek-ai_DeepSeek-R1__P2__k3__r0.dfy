function quad(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A * x * x + B * y * y + C * x * y + D * x + E * y + F
}

method Main(A: real, B: real, C: real, D: real, E: real, F: real, x0: real, y0: real, w: real)
  requires w > 0.0
{
  // Define grid points
  var x1 := x0 - w;
  var x2 := x0;
  var x3 := x0 + w;
  var y1 := y0 - w;
  var y2 := y0;
  var y3 := y0 + w;

  // Compute z-values at grid points
  var z11 := quad(x1, y3, A, B, C, D, E, F);
  var z12 := quad(x2, y3, A, B, C, D, E, F);
  var z13 := quad(x3, y3, A, B, C, D, E, F);
  var z21 := quad(x1, y2, A, B, C, D, E, F);
  var z22 := quad(x2, y2, A, B, C, D, E, F);
  var z23 := quad(x3, y2, A, B, C, D, E, F);
  var z31 := quad(x1, y1, A, B, C, D, E, F);
  var z32 := quad(x2, y1, A, B, C, D, E, F);
  var z33 := quad(x3, y1, A, B, C, D, E, F);

  // Compute discrete Hessian components
  var dxx := (z11 - 2.0*z12 + z13 + 2.0*z21 - 4.0*z22 + 2.0*z23 + z31 - 2.0*z32 + z33) / (6.0 * w * w);
  var dyy := (z11 + 2.0*z12 + z13 - 2.0*z21 - 4.0*z22 - 2.0*z23 + z31 + 2.0*z32 + z33) / (6.0 * w * w);
  var dxy := (z11 - z13 - z31 + z33) / (4.0 * w * w);

  // Verify recovery of Hessian components
  assert dxx == 2.0 * A;
  assert dyy == 2.0 * B;
  assert dxy == C;
}
