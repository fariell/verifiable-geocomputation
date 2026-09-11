// P-004 / GPB-019 algebraic entry: Horn exact on quadratics, cubic O(w²).
// Formal verification of Horn slope algorithm properties.

module HornSlopeProperties {
  // Grid spacing must be positive
  ghost function method PositiveGridSpacing(w: real): bool
    ensures PositiveGridSpacing(w) == (w > 0.0)
  {
    w > 0.0
  }

  // Quadratic surface coefficients
  ghost function method QuadraticCoefficients(A: real, B: real, C: real, 
                                             D: real, E: real, F: real): (A: real, B: real, C: real, D: real, E: real, F: real)
    ensures QuadraticCoefficients(A, B, C, D, E, F) == (A, B, C, D, E, F)
  {
    (A, B, C, D, E, F)
  }

  // Sample point on quadratic surface
  ghost function method SampleQuadratic(p: real, q: real, w: real, 
                                       A: real, B: real, C: real, 
                                       D: real, E: real, F: real): real
    requires PositiveGridSpacing(w)
    ensures SampleQuadratic(p, q, w, A, B, C, D, E, F) == 
            A * (p * w) + B * (q * w) + C + D * (p * w) * (p * w) + 
            E * (p * w) * (q * w) + F * (q * w) * (q * w)
  {
    A * (p * w) + B * (q * w) + C + D * (p * w) * (p * w) + 
    E * (p * w) * (q * w) + F * (q * w) * (q * w)
  }

  // Horn slope algorithm for DzDx
  ghost function method HornDzDx(a: real, b: real, c: real, 
                               d: real, f: real, 
                               g: real, h: real, i: real, 
                               w: real): real
    requires PositiveGridSpacing(w)
    ensures HornDzDx(a, b, c, d, f, g, h, i, w) == 
            ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w)
  {
    (c + 2.0 * f + i - a - 2.0 * d - g) / (8.0 * w)
  }

  // Horn slope algorithm for DzDy
  ghost function method HornDzDy(a: real, b: real, c: real, 
                               d: real, f: real, 
                               g: real, h: real, i: real, 
                               w: real): real
    requires PositiveGridSpacing(w)
    ensures HornDzDy(a, b, c, d, f, g, h, i, w) == 
            ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w)
  {
    (g + 2.0 * h + i - a - 2.0 * b - c) / (8.0 * w)
  }

  // Window of 3x3 points for quadratic surface
  ghost function method WindowQuadratic(w: real, 
                                       A: real, B: real, C: real, 
                                       D: real, E: real, F: real): 
    (a: real, b: real, c: real, 
     d: real, f: real, 
     g: real, h: real, i: real)
    requires PositiveGridSpacing(w)
  {
    // Sample points at (-1,-1), (0,-1), (1,-1), etc.
    var a := SampleQuadratic(-1.0, -1.0, w, A, B, C, D, E, F);
    var b := SampleQuadratic(0.0, -1.0, w, A, B, C, D, E, F);
    var c := SampleQuadratic(1.0, -1.0, w, A, B, C, D, E, F);
    var d := SampleQuadratic(-1.0, 0.0, w, A, B, C, D, E, F);
    var f := SampleQuadratic(1.0, 0.0, w, A, B, C, D, E, F);
    var g := SampleQuadratic(-1.0, 1.0, w, A, B, C, D, E, F);
    var h := SampleQuadratic(0.0, 1.0, w, A, B, C, D, E, F);
    var i := SampleQuadratic(1.0, 1.0, w, A, B, C, D, E, F);
    (a, b, c, d, f, g, h, i)
  }

  // Cubic surface z = G x^3
  ghost function method SampleCubic(p: real, w: real, G: real): real
    requires PositiveGridSpacing(w)
    ensures SampleCubic(p, w, G) == G * (p * w) * (p * w) * (p * w)
  {
    G * (p * w) * (p * w) * (p * w)
  }

  // Window of 3x3 points for cubic surface (z = G x^3)
  ghost function method WindowCubic(w: real, G: real): 
    (a: real, b: real, c: real, 
     d: real, f: real, 
     g: real, h: real, i: real)
    requires PositiveGridSpacing(w)
  {
    // Sample points at (-1,-1), (0,-1), (1,-1), etc.
    // For z = G x^3, y doesn't affect the value
    var a := SampleCubic(-1.0, w, G);
    var b := SampleCubic(0.0, w, G);
    var c := SampleCubic(1.0, w, G);
    var d := SampleCubic(-1.0, w, G);
    var f := SampleCubic(1.0, w, G);
    var g := SampleCubic(-1.0, w, G);
    var h := SampleCubic(0.0, w, G);
    var i := SampleCubic(1.0, w, G);
    (a, b, c, d, f, g, h, i)
  }

  // Horn slope is exact on quadratic surfaces
  lemma HornExactOnQuadratic(A: real, B: real, C: real, 
                            D: real, E: real, F: real, 
                            w: real)
    requires PositiveGridSpacing(w)
    // Horn DzDx recovers the true gradient coefficient A
    ensures HornDzDx(WindowQuadratic(w, A, B, C, D, E, F).a,
                    WindowQuadratic(w, A, B, C, D, E, F).b,
                    WindowQuadratic(w, A, B, C, D, E, F).c,
                    WindowQuadratic(w, A, B, C, D, E, F).d,
                    WindowQuadratic(w, A, B, C, D, E, F).f,
                    WindowQuadratic(w, A, B, C, D, E, F).g,
                    WindowQuadratic(w, A, B, C, D, E, F).h,
                    WindowQuadratic(w, A, B, C, D, E, F).i,
                    w) == A
    // Horn DzDy recovers the true gradient coefficient B
    ensures HornDzDy(WindowQuadratic(w, A, B, C, D, E, F).a,
                    WindowQuadratic(w, A, B, C, D, E, F).b,
                    WindowQuadratic(w, A, B, C, D, E, F).c,
                    WindowQuadratic(w, A, B, C, D, E, F).d,
                    WindowQuadratic(w, A, B, C, D, E, F).f,
                    WindowQuadratic(w, A, B, C, D, E, F).g,
                    WindowQuadratic(w, A, B, C, D, E, F).h,
                    WindowQuadratic(w, A, B, C, D, E, F).i,
                    w) == B
  {
    // Extract window points
    var (a, b, c, d, f, g, h, i) := WindowQuadratic(w, A, B, C, D, E, F);
    
    // Compute Horn DzDx
    var hornDzDx := HornDzDx(a, b, c, d, f, g, h, i, w);
    
    // Compute Horn DzDy
    var hornDzDy := HornDzDy(a, b, c, d, f, g, h, i, w);
    
    // Verify Horn DzDx equals A
    assert hornDzDx == A;
    
    // Verify Horn DzDy equals B
    assert hornDzDy == B;
  }

  // Horn slope remainder on cubic surface z = G x^3
  lemma HornCubicRemainder(G: real, w: real)
    requires PositiveGridSpacing(w)
    // Horn DzDx remainder at origin is G w^2
    ensures HornDzDx(WindowCubic(w, G).a,
                    WindowCubic(w, G).b,
                    WindowCubic(w, G).c,
                    WindowCubic(w, G).d,
                    WindowCubic(w, G).f,
                    WindowCubic(w, G).g,
                    WindowCubic(w, G).h,
                    WindowCubic(w, G).i,
                    w) - G * (0.0 * w) == G * (w * w)
  {
    // Extract window points
    var (a, b, c, d, f, g, h, i) := WindowCubic(w, G);
    
    // Compute Horn DzDx
    var hornDzDx := HornDzDx(a, b, c, d, f, g, h, i, w);
    
    // The true gradient at origin is 0 (since dz/dx = 3Gx^2, which is 0 at x=0)
    var trueGradient := 0.0;
    
    // The remainder is the difference between Horn estimate and true gradient
    var remainder := hornDzDx - trueGradient;
    
    // Verify remainder is G w^2
    assert remainder == G * (w * w);
  }
}
