// Zevenbergen-Thorne Hessian on a quadratic surface
// Theorem: On a quadratic surface z = A x^2 + B y^2 + C xy + Dx + Ey + F
// sampled on a 3x3 window with spacing w>0,
// the Zevenbergen-Thorne discrete Hessian recovers (2A, 2B, C) exactly.

method ZTHessianTheorem(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
{
  // Define the quadratic surface function
  function f(x: real, y: real): real
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  // Sample points on a 3x3 grid centered at (0,0) with spacing w
  var z00 := f(-w, -w);
  var z01 := f(-w, 0.0);
  var z02 := f(-w, w);
  var z10 := f(0.0, -w);
  var z11 := f(0.0, 0.0);
  var z12 := f(0.0, w);
  var z20 := f(w, -w);
  var z21 := f(w, 0.0);
  var z22 := f(w, w);

  // Zevenbergen-Thorne discrete Hessian formulas
  // Hxx = (z20 - 2*z10 + z00) / (w^2)
  // Hyy = (z02 - 2*z01 + z00) / (w^2)
  // Hxy = (z22 - z20 - z02 + z00) / (4*w^2)
  var Hxx := (z20 - 2.0*z10 + z00) / (w*w);
  var Hyy := (z02 - 2.0*z01 + z00) / (w*w);
  var Hxy := (z22 - z20 - z02 + z00) / (4.0*w*w);

  // Expected continuous Hessian components for the quadratic surface:
  // ∂²f/∂x² = 2A, ∂²f/∂y² = 2B, ∂²f/∂x∂y = C
  var expected_Hxx := 2.0*A;
  var expected_Hyy := 2.0*B;
  var expected_Hxy := C;

  // Prove the equality (within real arithmetic, no rounding)
  assert Hxx == expected_Hxx;
  assert Hyy == expected_Hyy;
  assert Hxy == expected_Hxy;
}
