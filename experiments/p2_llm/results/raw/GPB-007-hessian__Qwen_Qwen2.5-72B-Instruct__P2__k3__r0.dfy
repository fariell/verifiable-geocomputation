method ZevenbergenThorneHessian(A: real, B: real, C: real, D: real, E: real, F: real, w: real) returns (h11: real, h22: real, h12: real)
  requires w > 0
  ensures h11 == 2 * A
  ensures h22 == 2 * B
  ensures h12 == C
{
  // Define the 3x3 window points
  var x0 := 0.0;
  var y0 := 0.0;
  var x1 := w;
  var y1 := w;
  var x2 := 2 * w;
  var y2 := 2 * w;

  // Compute the function values at the 3x3 window points
  var z00 := A * x0 * x0 + B * y0 * y0 + C * x0 * y0 + D * x0 + E * y0 + F;
  var z01 := A * x0 * x0 + B * y1 * y1 + C * x0 * y1 + D * x0 + E * y1 + F;
  var z02 := A * x0 * x0 + B * y2 * y2 + C * x0 * y2 + D * x0 + E * y2 + F;
  var z10 := A * x1 * x1 + B * y0 * y0 + C * x1 * y0 + D * x1 + E * y0 + F;
  var z11 := A * x1 * x1 + B * y1 * y1 + C * x1 * y1 + D * x1 + E * y1 + F;
  var z12 := A * x1 * x1 + B * y2 * y2 + C * x1 * y2 + D * x1 + E * y2 + F;
  var z20 := A * x2 * x2 + B * y0 * y0 + C * x2 * y0 + D * x2 + E * y0 + F;
  var z21 := A * x2 * x2 + B * y1 * y1 + C * x2 * y1 + D * x2 + E * y1 + F;
  var z22 := A * x2 * x2 + B * y2 * y2 + C * x2 * y2 + D * x2 + E * y2 + F;

  // Compute the discrete Hessian components
  h11 := (z20 + z02 - 2 * z11) / (w * w);
  h22 := (z02 + z20 - 2 * z11) / (w * w);
  h12 := (z22 + z00 - z20 - z02) / (4 * w * w);

  // Verify the computed Hessian components
  assert h11 == 2 * A;
  assert h22 == 2 * B;
  assert h12 == C;
}
