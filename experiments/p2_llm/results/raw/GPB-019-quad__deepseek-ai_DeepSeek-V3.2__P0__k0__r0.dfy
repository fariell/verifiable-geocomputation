// P004: Horn slope exact on quadratic surfaces, cubic remainder O(w^2)
// Formalization of the property:
// 1. For any quadratic surface z = A x + B y + C + D x^2 + E x y + F y^2,
//    the Horn finite-difference gradient (DzDx, DzDy) recovers (A, B) exactly.
// 2. For the cubic surface z = G x^3, the DzDx remainder at the origin equals G w^2,
//    which is O(w^2).

module P004_Consistency {
  // Horn finite-difference gradient for a 3×3 stencil.
  // Stencil layout:
  //   a b c
  //   d   f
  //   g h i
  // with spacing w in both x and y directions.
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

  // Quadratic surface definition
  function QuadraticSurface(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
  {
    A * x + B * y + C + D * x * x + E * x * y + F * y * y
  }

  // Sample the quadratic surface at the 8 neighbor points of a 3×3 stencil.
  // The stencil is centered at (0,0) with spacing w.
  // Returns the tuple (a, b, c, d, f, g, h, i) as per the layout.
  function QuadraticStencil(A: real, B: real, C: real, D: real, E: real, F: real, w: real): (a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real)
    requires w > 0.0
  {
    var a := QuadraticSurface(A, B, C, D, E, F, -w, -w);
    var b := QuadraticSurface(A, B, C, D, E, F,  0.0, -w);
    var c := QuadraticSurface(A, B, C, D, E, F,  w, -w);
    var d := QuadraticSurface(A, B, C, D, E, F, -w,  0.0);
    var f := QuadraticSurface(A, B, C, D, E, F,  w,  0.0);
    var g := QuadraticSurface(A, B, C, D, E, F, -w,  w);
    var h := QuadraticSurface(A, B, C, D, E, F,  0.0, w);
    var i := QuadraticSurface(A, B, C, D, E, F,  w,  w);
    (a, b, c, d, f, g, h, i)
  }

  // Lemma: Horn gradient is exact for any quadratic surface.
  lemma HornExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures forall a, b, c, d, f, g, h, i ::
      (a, b, c, d, f, g, h, i) == QuadraticStencil(A, B, C, D, E, F, w) ==>
      HornDzDx(a, b, c, d, f, g, h, i, w) == A &&
      HornDzDy(a, b, c, d, f, g, h, i, w) == B
  {
    var (a, b, c, d, f, g, h, i) := QuadraticStencil(A, B, C, D, E, F, w);
    // Compute DzDx
    var numDx := (c + 2.0 * f + i) - (a + 2.0 * d + g);
    // Expand each term using the quadratic definition
    // a = A*(-w) + B*(-w) + C + D*w^2 + E*w^2 + F*w^2
    // c = A*w + B*(-w) + C + D*w^2 - E*w^2 + F*w^2
    // f = A*w + B*0 + C + D*w^2 + 0 + 0
    // i = A*w + B*w + C + D*w^2 + E*w^2 + F*w^2
    // d = A*(-w) + B*0 + C + D*w^2 + 0 + 0
    // g = A*(-w) + B*w + C + D*w^2 - E*w^2 + F*w^2
    // After substitution and simplification, all quadratic terms cancel.
    // The linear terms sum to 8 * A * w.
    assert numDx == 8.0 * A * w by {
      calc {
        numDx;
        ==
        (QuadraticSurface(A, B, C, D, E, F, w, -w) + 2.0 * QuadraticSurface(A, B, C, D, E, F, w, 0.0) + QuadraticSurface(A, B, C, D, E, F, w, w))
        - (QuadraticSurface(A, B, C, D, E, F, -w, -w) + 2.0 * QuadraticSurface(A, B, C, D, E, F, -w, 0.0) + QuadraticSurface(A, B, C, D, E, F, -w, w));
        ==
        ((A*w + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w)) + 2.0*(A*w + B*0 + C + D*w*w + E*w*0 + F*0) + (A*w + B*w + C + D*w*w + E*w*w + F*w*w))
        - ((A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w)) + 2.0*(A*(-w) + B*0 + C + D*(-w)*(-w) + E*(-w)*0 + F*0) + (A*(-w) + B*w + C + D*(-w)*(-w) + E*(-w)*w + F*w*w));
        ==
        // Collect linear terms in A:
        // First bracket: A*w + 2*A*w + A*w = 4*A*w
        // Second bracket: A*(-w) + 2*A*(-w) + A*(-w) = -4*A*w
        // Difference: 4*A*w - (-4*A*w) = 8*A*w
        // All other terms (B, C, D, E, F) cancel exactly.
        8.0 * A * w;
      }
    }
    // Therefore DzDx = (8 * A * w) / (8 * w) = A
    assert HornDzDx(a, b, c, d, f, g, h, i, w) == A;

    // Similarly for DzDy
    var numDy := (g + 2.0 * h + i) - (a + 2.0 * b + c);
    assert numDy == 8.0 * B * w by {
      calc {
        numDy;
        ==
        (QuadraticSurface(A, B, C, D, E, F, -w, w) + 2.0 * QuadraticSurface(A, B, C, D, E, F, 0.0, w) + QuadraticSurface(A, B, C, D, E, F, w, w))
        - (QuadraticSurface(A, B, C, D, E, F, -w, -w) + 2.0 * QuadraticSurface(A, B, C, D, E, F, 0.0, -w) + QuadraticSurface(A, B, C, D, E, F, w, -w));
        ==
        // Collect linear terms in B:
        // First bracket: B*w + 2*B*w + B*w = 4*B*w
        // Second bracket: B*(-w) + 2*B*(-w) + B*(-w) = -4*B*w
        // Difference: 4*B*w - (-4*B*w) = 8*B*w
        // All other terms cancel.
        8.0 * B * w;
      }
    }
    assert HornDzDy(a, b, c, d, f, g, h, i, w) == B;
  }

  // Cubic surface z = G x^3
  function CubicSurface(G: real, x: real, y: real): real
  {
    G * x * x * x
  }

  // Stencil for cubic surface centered at origin.
  function CubicStencil(G: real, w: real): (a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real)
    requires w > 0.0
  {
    var a := CubicSurface(G, -w, -w);
    var b := CubicSurface(G,  0.0, -w);
    var c := CubicSurface(G,  w, -w);
    var d := CubicSurface(G, -w,  0.0);
    var f := CubicSurface(G,  w,  0.0);
    var g := CubicSurface(G, -w,  w);
    var h := CubicSurface(G,  0.0, w);
    var i := CubicSurface(G,  w,  w);
    (a, b, c, d, f, g, h, i)
  }

  // Lemma: For z = G x^3, the Horn DzDx remainder at the origin equals G w^2.
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures forall a, b, c, d, f, g, h, i ::
      (a, b, c, d, f, g, h, i) == CubicStencil(G, w) ==>
      HornDzDx(a, b, c, d, f, g, h, i, w) == G * w * w
  {
    var (a, b, c, d, f, g, h, i) := CubicStencil(G, w);
    // Compute DzDx
    var numDx := (c + 2.0 * f + i) - (a + 2.0 * d + g);
    // Substitute cubic values:
    // a = G * (-w)^3 = -G w^3
    // c = G * w^3
    // f = G * w^3
    // i = G * w^3
    // d = -G w^3
    // g = -G w^3
    // Then:
    // c + 2f + i = G w^3 + 2 G w^3 + G w^3 = 4 G w^3
    // a + 2d + g = -G w^3 + 2(-G w^3) + (-G w^3) = -4 G w^3
    // Difference = 8 G w^3
    assert numDx == 8.0 * G * w * w * w by {
      calc {
        numDx;
        ==
        (CubicSurface(G, w, -w) + 2.0 * CubicSurface(G, w, 0.0) + CubicSurface(G, w, w))
        - (CubicSurface(G, -w, -w) + 2.0 * CubicSurface(G, -w, 0.0) + CubicSurface(G, -w, w));
        ==
        (G*w*w*w + 2.0*G*w*w*w + G*w*w*w) - (G*(-w)*(-w)*(-w) + 2.0*G*(-w)*(-w)*(-w) + G*(-w)*(-w)*(-w));
        ==
        (4.0 * G * w * w * w) - (-4.0 * G * w * w * w);
        ==
        8.0 * G * w * w * w;
      }
    }
    // DzDx = (8 G w^3) / (8 w) = G w^2
    assert HornDzDx(a, b, c, d, f, g, h, i, w) == G * w * w;
  }

  // Corollary: The remainder is O(w^2) as w -> 0.
  // This is immediate because the remainder equals G w^2, which is proportional to w^2.
  lemma CubicRemainderOrder(G: real, w: real)
    requires w > 0.0
    ensures exists K: real :: K == abs(G) &&
      forall a, b, c, d, f, g, h, i ::
        (a, b, c, d, f, g, h, i) == CubicStencil(G, w) ==>
        abs(HornDzDx(a, b, c, d, f, g, h, i, w)) <= K * w * w
  {
    var K := abs(G);
    var (a, b, c, d, f, g, h, i) := CubicStencil(G, w);
    CubicRemainder(G, w);
    // HornDzDx = G w^2
    assert HornDzDx(a, b, c, d, f, g, h, i, w) == G * w * w;
    // Therefore |HornDzDx| = |G| w^2 = K w^2
    assert abs(HornDzDx(a, b, c, d, f, g, h, i, w)) == K * w * w;
  }
}
