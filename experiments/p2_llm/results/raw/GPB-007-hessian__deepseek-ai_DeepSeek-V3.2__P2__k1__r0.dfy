// Zevenbergen-Thorne discrete Hessian on a quadratic surface
// Theorem: For z = A x^2 + B y^2 + C xy + Dx + Ey + F sampled on a 3x3 window
// with spacing w > 0, the discrete Hessian recovers (2A, 2B, C) exactly.

method ZTHessianExactRecovery(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
  ensures true
{
  // Define the quadratic surface function
  function z(x: real, y: real): real
  {
    A * x * x + B * y * y + C * x * y + D * x + E * y + F
  }

  // Sample points on a 3x3 grid centered at (0,0) with spacing w
  var z00 := z(-w, -w);
  var z01 := z(-w, 0.0);
  var z02 := z(-w, w);
  var z10 := z(0.0, -w);
  var z11 := z(0.0, 0.0);
  var z12 := z(0.0, w);
  var z20 := z(w, -w);
  var z21 := z(w, 0.0);
  var z22 := z(w, w);

  // Zevenbergen-Thorne discrete Hessian formulas
  var Hxx := (z20 - 2.0 * z10 + z00) / (w * w);
  var Hyy := (z02 - 2.0 * z01 + z00) / (w * w);
  var Hxy := (z22 - z20 - z02 + z00) / (4.0 * w * w);

  // Expected values from the continuous Hessian of z(x,y)
  // ∂²z/∂x² = 2A, ∂²z/∂y² = 2B, ∂²z/∂x∂y = C
  var expected_Hxx := 2.0 * A;
  var expected_Hyy := 2.0 * B;
  var expected_Hxy := C;

  // The theorem claims exact equality for quadratic surfaces
  assert Hxx == expected_Hxx;
  assert Hyy == expected_Hyy;
  assert Hxy == expected_Hxy;
}
