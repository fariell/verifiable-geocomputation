function z(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A*x*x + B*y*y + C*x*y + D*x + E*y + F
}

method Theorem(A: real, B: real, C: real, D: real, E: real, F: real, x0: real, y0: real, w: real)
  requires w > 0.0
{
  // Define grid points (row-major: [row][col])
  // Row 0 (top): y = y0 + 2w
  var g00 := z(x0, y0 + 2.0*w, A, B, C, D, E, F);  // (x0, y0+2w)
  var g10 := z(x0 + w, y0 + 2.0*w, A, B, C, D, E, F);
  var g20 := z(x0 + 2.0*w, y0 + 2.0*w, A, B, C, D, E, F);
  
  // Row 1 (middle): y = y0 + w
  var g01 := z(x0, y0 + w, A, B, C, D, E, F);      // (x0, y0+w)
  var g11 := z(x0 + w, y0 + w, A, B, C, D, E, F);  // center
  var g21 := z(x0 + 2.0*w, y0 + w, A, B, C, D, E, F);
  
  // Row 2 (bottom): y = y0
  var g02 := z(x0, y0, A, B, C, D, E, F);          // (x0, y0)
  var g12 := z(x0 + w, y0, A, B, C, D, E, F);
  var g22 := z(x0 + 2.0*w, y0, A, B, C, D, E, F);
  
  // Zevenbergen-Thorne discrete Hessian
  var H_xx := (g01 - 2.0*g11 + g21) / (w*w);
  var H_yy := (g10 - 2.0*g11 + g12) / (w*w);
  var H_xy := (g20 - g00 - g22 + g02) / (4.0*w*w);
  
  // Exact recovery of continuous Hessian components
  assert H_xx == 2.0 * A;
  assert H_yy == 2.0 * B;
  assert H_xy == C;
}
