// Zevenbergen-Thorne discrete Hessian for quadratic surfaces
lemma HessianRecovery(A: real, B: real, C: real, D: real, E: real, F: real, w: real, x0: real, y0: real)
  requires w > 0.0
  ensures (z(x0 + w, y0) - 2.0*z(x0, y0) + z(x0 - w, y0)) / (w*w) == 2.0 * A
  ensures (z(x0, y0 + w) - 2.0*z(x0, y0) + z(x0, y0 - w)) / (w*w) == 2.0 * B
  ensures (z(x0 + w, y0 + w) - z(x0 + w, y0 - w) - z(x0 - w, y0 + w) + z(x0 - w, y0 - w)) / (4.0*w*w) == C
{
  // Quadratic surface definition
  function z(x: real, y: real): real
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }
}
