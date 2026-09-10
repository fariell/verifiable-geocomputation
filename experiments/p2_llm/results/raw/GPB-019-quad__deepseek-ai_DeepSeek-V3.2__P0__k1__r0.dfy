// P004: Horn slope exact on quadratic surfaces, cubic remainder O(w^2)
// Formalization of the property that Horn's finite-difference gradient
// recovers the true planar coefficients exactly for quadratic surfaces,
// and has a remainder of G w^2 for the cubic z = G x^3 at the origin.

module P004_Consistency {
  // Horn finite-difference gradient for a 3×3 window.
  // Window layout:
  //   a b c
  //   d   f
  //   g h i
  // Grid spacing w > 0.
  function HornDzDx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w)
  }

  function HornDzDy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w)
  }

  // General quadratic surface: z = A x + B y + C + D x^2 + E x y + F y^2
  function Quadratic(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real {
    A * x + B * y + C + D * x * x + E * x * y + F * y * y
  }

  // True gradient of quadratic surface is (A + 2D x + E y, B + E x + 2F y).
  // At the origin (x=0, y=0) it is exactly (A, B).
  function TrueGradientX(x: real, y: real, A: real, D: real, E: real): real {
    A + 2.0 * D * x + E * y
  }

  function TrueGradientY(x: real, y: real, B: real, E: real, F: real): real {
    B + E * x + 2.0 * F * y
  }

  // Sample the quadratic surface at the 8 neighbor points around the origin.
  // p,q ∈ { -1, 0, 1 } excluding (0,0).
  function SampleQuadratic(p: int, q: int, w: real, A: real, B: real, C: real, D: real, E: real, F: real): real
    requires w > 0.0
    requires -1 <= p <= 1 && -1 <= q <= 1
    requires (p, q) != (0, 0)
  {
    Quadratic(p * w, q * w, A, B, C, D, E, F)
  }

  // Lemma: Horn gradient on a quadratic surface at the origin recovers (A, B) exactly.
  lemma HornExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures
      HornDzDx(
        SampleQuadratic(-1, -1, w, A, B, C, D, E, F),
        SampleQuadratic( 0, -1, w, A, B, C, D, E, F),
        SampleQuadratic( 1, -1, w, A, B, C, D, E, F),
        SampleQuadratic(-1,  0, w, A, B, C, D, E, F),
        SampleQuadratic( 1,  0, w, A, B, C, D, E, F),
        SampleQuadratic(-1,  1, w, A, B, C, D, E, F),
        SampleQuadratic( 0,  1, w, A, B, C, D, E, F),
        SampleQuadratic( 1,  1, w, A, B, C, D, E, F),
        w
      ) == TrueGradientX(0.0, 0.0, A, D, E)
    ensures
      HornDzDy(
        SampleQuadratic(-1, -1, w, A, B, C, D, E, F),
        SampleQuadratic( 0, -1, w, A, B, C, D, E, F),
        SampleQuadratic( 1, -1, w, A, B, C, D, E, F),
        SampleQuadratic(-1,  0, w, A, B, C, D, E, F),
        SampleQuadratic( 1,  0, w, A, B, C, D, E, F),
        SampleQuadratic(-1,  1, w, A, B, C, D, E, F),
        SampleQuadratic( 0,  1, w, A, B, C, D, E, F),
        SampleQuadratic( 1,  1, w, A, B, C, D, E, F),
        w
      ) == TrueGradientY(0.0, 0.0, B, E, F)
  {
    // Expand all samples using the quadratic definition.
    var a := Quadratic(-w, -w, A, B, C, D, E, F);
    var b := Quadratic( 0.0, -w, A, B, C, D, E, F);
    var c := Quadratic( w, -w, A, B, C, D, E, F);
    var d := Quadratic(-w,  0.0, A, B, C, D, E, F);
    var f := Quadratic( w,  0.0, A, B, C, D, E, F);
    var g := Quadratic(-w,  w, A, B, C, D, E, F);
    var h := Quadratic( 0.0,  w, A, B, C, D, E, F);
    var i := Quadratic( w,  w, A, B, C, D, E, F);

    // Compute HornDzDx numerator.
    var numDx := (c + 2.0 * f + i) - (a + 2.0 * d + g);
    // Substitute quadratic expressions and simplify.
    // a = A*(-w) + B*(-w) + C + D*w*w + E*w*w + F*w*w
    //   = -A w - B w + C + (D + E + F) w^2
    // Similarly for others.
    // Systematic simplification shows that the numerator equals 8 A w.
    // This is a symbolic identity; we assert it as a fact.
    assert numDx == 8.0 * A * w by {
      calc {
        numDx;
        ==
          (Quadratic( w, -w, A, B, C, D, E, F) +
           2.0 * Quadratic( w,  0.0, A, B, C, D, E, F) +
           Quadratic( w,  w, A, B, C, D, E, F))
          -
          (Quadratic(-w, -w, A, B, C, D, E, F) +
           2.0 * Quadratic(-w,  0.0, A, B, C, D, E, F) +
           Quadratic(-w,  w, A, B, C, D, E, F));
        ==
          // Expand each Quadratic call.
          ((A*w + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w)) +
           2.0 * (A*w + B*0.0 + C + D*w*w + E*w*0.0 + F*0.0) +
           (A*w + B*w + C + D*w*w + E*w*w + F*w*w))
          -
          ((A*(-w) + B*(-w) + C + D*w*w + E*(-w)*(-w) + F*(-w)*(-w)) +
           2.0 * (A*(-w) + B*0.0 + C + D*w*w + E*(-w)*0.0 + F*0.0) +
           (A*(-w) + B*w + C + D*w*w + E*(-w)*w + F*w*w));
        ==
          // Simplify each term.
          ((A*w - B*w + C + D*w*w - E*w*w + F*w*w) +
           2.0 * (A*w + C + D*w*w) +
           (A*w + B*w + C + D*w*w + E*w*w + F*w*w))
          -
          ((-A*w - B*w + C + D*w*w + E*w*w + F*w*w) +
           2.0 * (-A*w + C + D*w*w) +
           (-A*w + B*w + C + D*w*w - E*w*w + F*w*w));
        ==
          // Combine like terms.
          (A*w - B*w + C + D*w*w - E*w*w + F*w*w +
           2.0*A*w + 2.0*C + 2.0*D*w*w +
           A*w + B*w + C + D*w*w + E*w*w + F*w*w)
          -
          (-A*w - B*w + C + D*w*w + E*w*w + F*w*w +
           -2.0*A*w + 2.0*C + 2.0*D*w*w +
           -A*w + B*w + C + D*w*w - E*w*w + F*w*w);
        ==
          // Summation of the first bracket.
          ( (A*w + 2.0*A*w + A*w) + (-B*w + B*w) + (C + 2.0*C + C) +
            (D*w*w + 2.0*D*w*w + D*w*w) + (-E*w*w + E*w*w) + (F*w*w + F*w*w) );
        ==
          (4.0*A*w) + 0.0 + 4.0*C + 4.0*D*w*w + 0.0 + 2.0*F*w*w;
        ==
          4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w;
        // Summation of the second bracket.
        var second :=
          (-A*w - 2.0*A*w - A*w) + (-B*w + B*w) + (C + 2.0*C + C) +
          (D*w*w + 2.0*D*w*w + D*w*w) + (E*w*w - E*w*w) + (F*w*w + F*w*w);
        assert second == -4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w;
        // Subtract second from first.
        ==
          (4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w) -
          (-4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w);
        ==
          4.0*A*w - (-4.0*A*w);
        ==
          8.0 * A * w;
      }
    }
    // Therefore HornDzDx = (8 A w) / (8 w) = A.
    assert HornDzDx(a, b, c, d, f, g, h, i, w) == A by {
      calc {
        HornDzDx(a, b, c, d, f, g, h, i, w);
        == numDx / (8.0 * w);
        == (8.0 * A * w) / (8.0 * w);
        == A;
      }
    }
    // True gradient at origin is A.
    assert TrueGradientX(0.0, 0.0, A, D, E) == A;

    // Similarly for DzDy.
    var numDy := (g + 2.0 * h + i) - (a + 2.0 * b + c);
    assert numDy == 8.0 * B * w by {
      // Symmetric expansion; analogous to above.
      calc {
        numDy;
        ==
          (Quadratic(-w, w, A, B, C, D, E, F) +
           2.0 * Quadratic(0.0, w, A, B, C, D, E, F) +
           Quadratic(w, w, A, B, C, D, E, F))
          -
          (Quadratic(-w, -w, A, B, C, D, E, F) +
           2.0 * Quadratic(0.0, -w, A, B, C, D, E, F) +
           Quadratic(w, -w, A, B, C, D, E, F));
        ==
          // Expand.
          ((-A*w + B*w + C + D*w*w - E*w*w + F*w*w) +
           2.0 * (0.0 + B*w + C + 0.0 + 0.0 + F*w*w) +
           (A*w + B*w + C + D*w*w + E*w*w + F*w*w))
          -
          ((-A*w - B*w + C + D*w*w + E*w*w + F*w*w) +
           2.0 * (0.0 - B*w + C + 0.0 + 0.0 + F*w*w) +
           (A*w - B*w + C + D*w*w - E*w*w + F*w*w));
        ==
          // Combine.
          ((-A*w + B*w + C + D*w*w - E*w*w + F*w*w) +
           2.0*B*w + 2.0*C + 2.0*F*w*w +
           (A*w + B*w + C + D*w*w + E*w*w + F*w*w))
          -
          ((-A*w - B*w + C + D*w*w + E*w*w + F*w*w) +
           -2.0*B*w + 2.0*C + 2.0*F*w*w +
           (A*w - B*w + C + D*w*w - E*w*w + F*w*w));
        ==
          // First bracket.
          ((-A*w + A*w) + (B*w + 2.0*B*w + B*w) + (C + 2.0*C + C) +
           (D*w*w + D*w*w) + (-E*w*w + E*w*w) + (F*w*w + 2.0*F*w*w + F*w*w));
        ==
          0.0 + 4.0*B*w + 4.0*C + 2.0*D*w*w + 0.0 + 4.0*F*w*w;
        ==
          4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w;
        // Second bracket.
        var second2 :=
          (-A*w + A*w) + (-B*w - 2.0*B*w - B*w) + (C + 2.0*C + C) +
          (D*w*w + D*w*w) + (E*w*w - E*w*w) + (F*w*w + 2.0*F*w*w + F*w*w);
        assert second2 == -4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w;
        // Subtract.
        ==
          (4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w) -
          (-4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w);
        ==
          4.0*B*w - (-4.0*B*w);
        ==
          8.0 * B * w;
      }
    }
    assert HornDzDy(a, b, c, d, f, g, h, i, w) == B by {
      calc {
        HornDzDy(a, b, c, d, f, g, h, i, w);
        == numDy / (8.0 * w);
        == (8.0 * B * w) / (8.0 * w);
        == B;
      }
    }
    assert TrueGradientY(0.0, 0.0, B, E, F) == B;
  }

  // Cubic surface: z = G x^3.
  function CubicX3(x: real, G: real): real {
    G * x * x * x
  }

  // True derivative at x is 3 G x^2. At origin it is 0.
  function TrueCubicDeriv(x: real, G: real): real {
    3.0 * G * x * x
  }

  // Sample the cubic at the 8 neighbor points (y coordinate irrelevant).
  function SampleCubic(p: int, q: int, w: real, G: real): real
    requires w > 0.0
    requires -1 <= p <= 1 && -1 <= q <= 1
    requires (p, q) != (0, 0)
  {
    CubicX3(p * w, G)
  }

  // Lemma: HornDzDx on z = G x^3 at the origin equals G w^2.
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures
      HornDzDx(
        SampleCubic(-1, -1, w, G),
        SampleCubic( 0, -1, w, G),
        SampleCubic( 1, -1,
