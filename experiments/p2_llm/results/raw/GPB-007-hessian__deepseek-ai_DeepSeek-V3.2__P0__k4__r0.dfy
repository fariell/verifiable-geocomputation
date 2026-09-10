// P003: Zevenbergen-Thorne Hessian exactness on quadratic surfaces
// Formalization of the statement:
//   For a quadratic surface z = A x² + B y² + C xy + D x + E y + F
//   sampled on a 3×3 window with spacing w > 0,
//   the ZT discrete Hessian recovers (2A, 2B, C) exactly.

module P003_curvature {
  // Quadratic surface definition
  function quadratic(A: real, B: real, C: real, D: real, E: real, F: real,
                     x: real, y: real): real
    reads
  {
    A * x * x + B * y * y + C * x * y + D * x + E * y + F
  }

  // Sample the quadratic surface on a 3×3 grid centered at (0,0)
  // with spacing w > 0.
  // Indices: (i,j) where i,j ∈ {-1,0,1}
  function sample(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real, i: int, j: int): real
    requires w > 0.0
    requires -1 <= i <= 1 && -1 <= j <= 1
  {
    quadratic(A, B, C, D, E, F, real(i) * w, real(j) * w)
  }

  // Zevenbergen-Thorne discrete Hessian formulas
  function zt_hxx(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real): real
    requires w > 0.0
  {
    // hxx = (z(-1,0) - 2*z(0,0) + z(1,0)) / w²
    (sample(A, B, C, D, E, F, w, -1, 0) -
     2.0 * sample(A, B, C, D, E, F, w, 0, 0) +
     sample(A, B, C, D, E, F, w, 1, 0)) / (w * w)
  }

  function zt_hyy(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real): real
    requires w > 0.0
  {
    // hyy = (z(0,-1) - 2*z(0,0) + z(0,1)) / w²
    (sample(A, B, C, D, E, F, w, 0, -1) -
     2.0 * sample(A, B, C, D, E, F, w, 0, 0) +
     sample(A, B, C, D, E, F, w, 0, 1)) / (w * w)
  }

  function zt_hxy(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real): real
    requires w > 0.0
  {
    // hxy = (z(-1,-1) - z(-1,1) - z(1,-1) + z(1,1)) / (4 w²)
    (sample(A, B, C, D, E, F, w, -1, -1) -
     sample(A, B, C, D, E, F, w, -1, 1) -
     sample(A, B, C, D, E, F, w, 1, -1) +
     sample(A, B, C, D, E, F, w, 1, 1)) / (4.0 * w * w)
  }

  // Lemma: ZT Hessian recovers (2A, 2B, C) exactly for any quadratic
  // and any spacing w > 0.
  lemma ZT_exact_on_quadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures zt_hxx(A, B, C, D, E, F, w) == 2.0 * A
    ensures zt_hyy(A, B, C, D, E, F, w) == 2.0 * B
    ensures zt_hxy(A, B, C, D, E, F, w) == C
  {
    // Expand all sample calls and simplify algebraically.
    // We'll prove each component separately.

    // Helper: value of quadratic at (x,y)
    calc {
      quadratic(A, B, C, D, E, F, 0.0, 0.0);
      ==
      A * 0.0 * 0.0 + B * 0.0 * 0.0 + C * 0.0 * 0.0 + D * 0.0 + E * 0.0 + F;
      ==
      F;
    }

    // hxx proof
    calc {
      zt_hxx(A, B, C, D, E, F, w);
      == // definition
      (quadratic(A, B, C, D, E, F, -w, 0.0) -
       2.0 * quadratic(A, B, C, D, E, F, 0.0, 0.0) +
       quadratic(A, B, C, D, E, F, w, 0.0)) / (w * w);
      == // expand each term
      ((A * w * w + B * 0.0 + C * (-w) * 0.0 + D * (-w) + E * 0.0 + F) -
       2.0 * F +
       (A * w * w + B * 0.0 + C * w * 0.0 + D * w + E * 0.0 + F)) / (w * w);
      == // simplify
      (A * w * w - D * w + F - 2.0 * F + A * w * w + D * w + F) / (w * w);
      == // cancel D*w and F terms
      (2.0 * A * w * w) / (w * w);
      ==
      2.0 * A;
    }

    // hyy proof (symmetric)
    calc {
      zt_hyy(A, B, C, D, E, F, w);
      ==
      (quadratic(A, B, C, D, E, F, 0.0, -w) -
       2.0 * quadratic(A, B, C, D, E, F, 0.0, 0.0) +
       quadratic(A, B, C, D, E, F, 0.0, w)) / (w * w);
      ==
      ((A * 0.0 + B * w * w + C * 0.0 * (-w) + D * 0.0 + E * (-w) + F) -
       2.0 * F +
       (A * 0.0 + B * w * w + C * 0.0 * w + D * 0.0 + E * w + F)) / (w * w);
      ==
      (B * w * w - E * w + F - 2.0 * F + B * w * w + E * w + F) / (w * w);
      ==
      (2.0 * B * w * w) / (w * w);
      ==
      2.0 * B;
    }

    // hxy proof
    calc {
      zt_hxy(A, B, C, D, E, F, w);
      ==
      (quadratic(A, B, C, D, E, F, -w, -w) -
       quadratic(A, B, C, D, E, F, -w, w) -
       quadratic(A, B, C, D, E, F, w, -w) +
       quadratic(A, B, C, D, E, F, w, w)) / (4.0 * w * w);
      == // expand each term
      ((A * w * w + B * w * w + C * w * w - D * w - E * w + F) -
       (A * w * w + B * w * w - C * w * w - D * w + E * w + F) -
       (A * w * w + B * w * w - C * w * w + D * w - E * w + F) +
       (A * w * w + B * w * w + C * w * w + D * w + E * w + F)) / (4.0 * w * w);
      == // group and cancel
      // A*w² terms: (1 - 1 - 1 + 1) = 0
      // B*w² terms: (1 - 1 - 1 + 1) = 0
      // C*w² terms: (1 - (-1) - (-1) + 1) = 4
      // D*w terms: (-1 - (-1) - 1 + 1) = 0
      // E*w terms: (-1 - 1 - (-1) + 1) = 0
      // F terms: (1 - 1 - 1 + 1) = 0
      (4.0 * C * w * w) / (4.0 * w * w);
      ==
      C;
    }
  }
}
