// Zevenbergen-Thorne discrete Hessian on a quadratic surface
// Theorem: For z = A x² + B y² + C xy + Dx + Ey + F sampled on a 3×3 window
// with spacing w > 0, the discrete Hessian recovers (2A, 2B, C) exactly.

method ZTHessianExactRecovery(A: real, B: real, C: real, D: real, E: real, F: real, w: real) 
  returns (Hxx: real, Hyy: real, Hxy: real)
  requires w > 0.0
  ensures Hxx == 2.0 * A
  ensures Hyy == 2.0 * B
  ensures Hxy == C
{
  // Define quadratic function
  function z(x: real, y: real): real
  {
    A * x * x + B * y * y + C * x * y + D * x + E * y + F
  }

  // Sample points on a 3×3 grid centered at (0,0) with spacing w
  // Indices: (i,j) where i,j ∈ {-1,0,1}
  var z00 := z(0.0, 0.0);
  var zp0 := z(w, 0.0);
  var zm0 := z(-w, 0.0);
  var z0p := z(0.0, w);
  var z0m := z(0.0, -w);
  var zpp := z(w, w);
  var zpm := z(w, -w);
  var zmp := z(-w, w);
  var zmm := z(-w, -w);

  // Zevenbergen-Thorne discrete Hessian formulas
  // Hxx = (z10 - 2*z00 + z(-1)0) / w²
  Hxx := (zp0 - 2.0 * z00 + zm0) / (w * w);
  // Hyy = (z01 - 2*z00 + z0(-1)) / w²
  Hyy := (z0p - 2.0 * z00 + z0m) / (w * w);
  // Hxy = (z11 - z1(-1) - z(-1)1 + z(-1)(-1)) / (4*w²)
  Hxy := (zpp - zpm - zmp + zmm) / (4.0 * w * w);

  // Verification that the computed values equal 2A, 2B, C
  // This is done by Dafny automatically via the postconditions.
  // We add assertions to guide the proof.
  assert zp0 == A * w * w + D * w + F;
  assert zm0 == A * w * w - D * w + F;
  assert z0p == B * w * w + E * w + F;
  assert z0m == B * w * w - E * w + F;
  assert zpp == A * w * w + B * w * w + C * w * w + D * w + E * w + F;
  assert zpm == A * w * w + B * w * w - C * w * w + D * w - E * w + F;
  assert zmp == A * w * w + B * w * w - C * w * w - D * w + E * w + F;
  assert zmm == A * w * w + B * w * w + C * w * w - D * w - E * w + F;
  assert z00 == F;
}
