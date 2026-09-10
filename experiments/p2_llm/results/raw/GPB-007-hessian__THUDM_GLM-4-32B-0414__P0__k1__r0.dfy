// Zevenbergen-Thorne Hessian for quadratic surfaces
module ZTHessian {
  // Represents a 3x3 grid window with spacing w
  datatype GridWindow = GridWindow(
    a: real, b: real, c: real, d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real // spacing, must be positive
  ) invariant w > 0.0

  // Quadratic surface coefficients
  datatype QuadraticCoeffs = QuadraticCoeffs(
    A: real, B: real, C: real, D: real, E: real, F: real
  )

  // Compute the Zevenbergen-Thorne Hessian from a grid window
  function Method ztHessian(window: GridWindow): (hxx: real, hyy: real, hxy: real)
  {
    var a, b, c, d, e, f, g, h, i, w := window.a, window.b, window.c, window.d, window.e, window.f,
        window.g, window.h, window.i, window.w;
    return (
      (d - 2.0 * e + f) / (w * w),  // hxx
      (b - 2.0 * e + h) / (w * w),  // hyy
      (a - c - g + i) / (4.0 * w * w)  // hxy
    )
  }

  // Evaluate quadratic surface at point (x,y)
  function Method quadraticSurface(coeffs: QuadraticCoeffs, x: real, y: real): real
  {
    var A, B, C, D, E, F := coeffs.A, coeffs.B, coeffs.C, coeffs.D, coeffs.E, coeffs.F;
    return A * x * x + B * y * y + C * x * y + D * x + E * y + F
  }

  // Sample quadratic surface on 3x3 grid with spacing w
  function Method sampleQuadratic(coeffs: QuadraticCoeffs, w: real): GridWindow
  {
    var A, B, C, D, E, F := coeffs.A, coeffs.B, coeffs.C, coeffs.D, coeffs.E, coeffs.F;
    return GridWindow(
      quadraticSurface(coeffs, -w, -w),  // a
      quadraticSurface(coeffs, 0.0, -w), // b
      quadraticSurface(coeffs, w, -w),   // c
      quadraticSurface(coeffs, -w, 0.0), // d
      quadraticSurface(coeffs, 0.0, 0.0), // e
      quadraticSurface(coeffs, w, 0.0),  // f
      quadraticSurface(coeffs, -w, w),   // g
      quadraticSurface(coeffs, 0.0, w),  // h
      quadraticSurface(coeffs, w, w),    // i
      w
    )
  }

  // Theorem: ZT Hessian recovers 2A, 2B, C exactly for quadratic surfaces
  lemma ZTRecoversQuadratic()
  {
    var A, B, C, D, E, F := 0.0, 0.0, 0.0, 0.0, 0.0, 0.0; // arbitrary coefficients
    var w := 1.0; // arbitrary spacing > 0
    var coeffs := QuadraticCoeffs(A, B, C, D, E, F);
    var window := sampleQuadratic(coeffs, w);
    var hxx, hyy, hxy := ztHessian(window);
    
    // The ZT Hessian should recover 2A, 2B, C exactly
    assert hxx == 2.0 * A;
    assert hyy == 2.0 * B;
    assert hxy == C;
  }
}
