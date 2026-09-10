// Quadratic surface: z = A x^2 + B y^2 + C xy + Dx + Ey + F
// Sampled on a 3x3 window with spacing w > 0
// Zevenbergen-Thorne discrete Hessian recovers (2A, 2B, C) exactly.

method QuadraticSurfaceHessian(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
{
  // Define the 3x3 grid points
  var x0 := -w;
  var x1 := 0.0;
  var x2 := w;
  var y0 := -w;
  var y1 := 0.0;
  var y2 := w;

  // Compute z values at each grid point
  var z00 := A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F;
  var z01 := A*x0*x0 + B*y1*y1 + C*x0*y1 + D*x0 + E*y1 + F;
  var z02 := A*x0*x0 + B*y2*y2 + C*x0*y2 + D*x0 + E*y2 + F;
  var z10 := A*x1*x1 + B*y0*y0 + C*x1*y0 + D*x1 + E*y0 + F;
  var z11 := A*x1*x1 + B*y1*y1 + C*x1*y1 + D*x1 + E*y1 + F;
  var z12 := A*x1*x1 + B*y2*y2 + C*x1*y2 + D*x1 + E*y2 + F;
  var z20 := A*x2*x2 + B*y0*y0 + C*x2*y0 + D*x2 + E*y0 + F;
  var z21 := A*x2*x2 + B*y1*y1 + C*x2*y1 + D*x2 + E*y1 + F;
  var z22 := A*x2*x2 + B*y2*y2 + C*x2*y2 + D*x2 + E*y2 + F;

  // Zevenbergen-Thorne discrete Hessian formulas
  // Second derivative in x: (z20 - 2*z10 + z00) / (w^2)
  var Hxx := (z20 - 2.0*z10 + z00) / (w*w);
  // Second derivative in y: (z02 - 2*z01 + z00) / (w^2)
  var Hyy := (z02 - 2.0*z01 + z00) / (w*w);
  // Mixed derivative: (z22 - z20 - z02 + z00) / (4*w^2)
  var Hxy := (z22 - z20 - z02 + z00) / (4.0*w*w);

  // Expected continuous Hessian components for z = A x^2 + B y^2 + C xy + Dx + Ey + F
  // ∂²z/∂x² = 2A, ∂²z/∂y² = 2B, ∂²z/∂x∂y = C
  var expected_Hxx := 2.0*A;
  var expected_Hyy := 2.0*B;
  var expected_Hxy := C;

  // Prove the discrete computation recovers the exact continuous values
  assert Hxx == expected_Hxx;
  assert Hyy == expected_Hyy;
  assert Hxy == expected_Hxy;
}
