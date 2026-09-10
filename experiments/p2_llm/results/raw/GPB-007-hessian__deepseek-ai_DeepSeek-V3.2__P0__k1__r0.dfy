// P003: Zevenbergen-Thorne Hessian exactness on quadratic surfaces
// Formalization of the property:
//   For a quadratic surface z = A x² + B y² + C xy + D x + E y + F
//   sampled on a 3×3 window with spacing w > 0,
//   the ZT discrete Hessian recovers (2A, 2B, C) exactly.

module P003_curvature {
  // Grid sampling of a quadratic surface at integer offsets
  function sample(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real, i: int, j: int): real
    requires w > 0.0
  {
    let x = w * i as real;
    let y = w * j as real;
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  // Zevenbergen-Thorne discrete Hessian components
  function ZT_Hxx(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real): real
    requires w > 0.0
  {
    let z00 = sample(A, B, C, D, E, F, w, -1, 0);
    let z01 = sample(A, B, C, D, E, F, w,  0, 0);
    let z02 = sample(A, B, C, D, E, F, w,  1, 0);
    (z00 - 2.0*z01 + z02) / (w*w)
  }

  function ZT_Hyy(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real): real
    requires w > 0.0
  {
    let z00 = sample(A, B, C, D, E, F, w, 0, -1);
    let z01 = sample(A, B, C, D, E, F, w, 0,  0);
    let z02 = sample(A, B, C, D, E, F, w, 0,  1);
    (z00 - 2.0*z01 + z02) / (w*w)
  }

  function ZT_Hxy(A: real, B: real, C: real, D: real, E: real, F: real,
                  w: real): real
    requires w > 0.0
  {
    let z00 = sample(A, B, C, D, E, F, w, -1, -1);
    let z01 = sample(A, B, C, D, E, F, w,  1, -1);
    let z02 = sample(A, B, C, D, E, F, w, -1,  1);
    let z03 = sample(A, B, C, D, E, F, w,  1,  1);
    (z00 - z01 - z02 + z03) / (4.0 * w * w)
  }

  // Lemma: ZT_Hxx recovers 2A exactly
  lemma Lemma_Hxx_exact(A: real, B: real, C: real, D: real, E: real, F: real,
                        w: real)
    requires w > 0.0
    ensures ZT_Hxx(A, B, C, D, E, F, w) == 2.0 * A
  {
    // Expand the three samples:
    // z(-1,0) = A*(w*(-1))² + ... = A*w² - D*w + F (since y=0)
    // z(0,0) = F
    // z(1,0) = A*w² + D*w + F
    // Then z(-1,0) - 2*z(0,0) + z(1,0) = (A*w² - D*w + F) - 2F + (A*w² + D*w + F)
    // = 2A*w²
    // Divide by w² gives 2A.
    calc {
      ZT_Hxx(A, B, C, D, E, F, w);
      ==
      (sample(A, B, C, D, E, F, w, -1, 0) - 2.0*sample(A, B, C, D, E, F, w, 0, 0)
       + sample(A, B, C, D, E, F, w, 1, 0)) / (w*w);
      ==
      ((A*(w*(-1))*(w*(-1)) + D*(w*(-1)) + F) - 2.0*F
       + (A*(w*1)*(w*1) + D*(w*1) + F)) / (w*w);
      ==
      ((A*w*w - D*w + F) - 2.0*F + (A*w*w + D*w + F)) / (w*w);
      ==
      (2.0*A*w*w) / (w*w);
      ==
      2.0 * A;
    }
  }

  // Lemma: ZT_Hyy recovers 2B exactly
  lemma Lemma_Hyy_exact(A: real, B: real, C: real, D: real, E: real, F: real,
                        w: real)
    requires w > 0.0
    ensures ZT_Hyy(A, B, C, D, E, F, w) == 2.0 * B
  {
    // Symmetric to Hxx case, with y variation
    calc {
      ZT_Hyy(A, B, C, D, E, F, w);
      ==
      (sample(A, B, C, D, E, F, w, 0, -1) - 2.0*sample(A, B, C, D, E, F, w, 0, 0)
       + sample(A, B, C, D, E, F, w, 0, 1)) / (w*w);
      ==
      ((B*(w*(-1))*(w*(-1)) + E*(w*(-1)) + F) - 2.0*F
       + (B*(w*1)*(w*1) + E*(w*1) + F)) / (w*w);
      ==
      ((B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F)) / (w*w);
      ==
      (2.0*B*w*w) / (w*w);
      ==
      2.0 * B;
    }
  }

  // Lemma: ZT_Hxy recovers C exactly
  lemma Lemma_Hxy_exact(A: real, B: real, C: real, D: real, E: real, F: real,
                        w: real)
    requires w > 0.0
    ensures ZT_Hxy(A, B, C, D, E, F, w) == C
  {
    // Expand the four corner samples:
    // z(-1,-1) = A*w² + B*w² + C*w² - D*w - E*w + F
    // z(1,-1)  = A*w² + B*w² - C*w² + D*w - E*w + F
    // z(-1,1)  = A*w² + B*w² - C*w² - D*w + E*w + F
    // z(1,1)   = A*w² + B*w² + C*w² + D*w + E*w + F
    // Then z00 - z01 - z02 + z03 = (C*w² + C*w² + C*w² + C*w²) = 4C*w²
    // Divide by 4w² gives C.
    calc {
      ZT_Hxy(A, B, C, D, E, F, w);
      ==
      (sample(A, B, C, D, E, F, w, -1, -1) - sample(A, B, C, D, E, F, w, 1, -1)
       - sample(A, B, C, D, E, F, w, -1, 1) + sample(A, B, C, D, E, F, w, 1, 1))
       / (4.0 * w * w);
      == {
        // Expand each sample
        assert sample(A, B, C, D, E, F, w, -1, -1) ==
               A*w*w + B*w*w + C*w*w - D*w - E*w + F;
        assert sample(A, B, C, D, E, F, w, 1, -1) ==
               A*w*w + B*w*w - C*w*w + D*w - E*w + F;
        assert sample(A, B, C, D, E, F, w, -1, 1) ==
               A*w*w + B*w*w - C*w*w - D*w + E*w + F;
        assert sample(A, B, C, D, E, F, w, 1, 1) ==
               A*w*w + B*w*w + C*w*w + D*w + E*w + F;
      }
      ((A*w*w + B*w*w + C*w*w - D*w - E*w + F)
       - (A*w*w + B*w*w - C*w*w + D*w - E*w + F)
       - (A*w*w + B*w*w - C*w*w - D*w + E*w + F)
       + (A*w*w + B*w*w + C*w*w + D*w + E*w + F)) / (4.0 * w * w);
      ==
      // Cancel A and B terms:
      // First term: +A+B+C -D -E +F
      // Subtract second: -(A+B -C +D -E +F) → cancels A,B, -D,-E,+F, leaves +C -D -E +F -(-C +D -E +F) = +C -D -E +F +C -D +E -F = 2C -2D
      // Wait, better to compute systematically:
      // Let S = A*w² + B*w², T = D*w, U = E*w
      // Then:
      // z00 = S + C*w² - T - U + F
      // z01 = S - C*w² + T - U + F
      // z02 = S - C*w² - T + U + F
      // z03 = S + C*w² + T + U + F
      // z00 - z01 - z02 + z03 =
      //   (S + C*w² - T - U + F) - (S - C*w² + T - U + F)
      //   - (S - C*w² - T + U + F) + (S + C*w² + T + U + F)
      // = S + C*w² - T - U + F - S + C*w² - T + U - F
      //   - S + C*w² + T - U - F + S + C*w² + T + U + F
      // Group S: S - S - S + S = 0
      // Group C*w²: +C +C +C +C = 4C*w²
      // Group T: -T -T +T +T = 0
      // Group U: -U +U -U +U = 0
      // Group F: +F -F -F +F = 0
      // So result = 4C*w²
      (4.0 * C * w * w) / (4.0 * w * w);
      ==
      C;
    }
  }

  // Main theorem: ZT Hessian recovers (2A, 2B, C) exactly
  theorem Theorem_ZT_exact_on_quadratic(A: real, B: real, C: real,
                                        D: real, E: real, F: real,
                                        w: real)
    requires w > 0.0
    ensures ZT_Hxx(A, B, C, D, E, F, w) == 2.0 * A
    ensures ZT_Hyy(A, B, C, D, E, F, w) == 2.0 * B
    ensures ZT_Hxy(A, B, C, D, E, F, w) == C
  {
    Lemma_Hxx_exact(A, B, C, D, E, F, w);
    Lemma_Hyy_exact(A, B, C, D, E, F, w);
    Lemma_Hxy_exact(A, B, C, D, E, F, w);
  }
}
