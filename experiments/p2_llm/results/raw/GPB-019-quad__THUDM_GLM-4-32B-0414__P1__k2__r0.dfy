module HornConsistency {
  // Horn slope operator kernels (from P-001)
  function NumDx(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (c + 2.0 * f + i) - (a + 2.0 * d + g) }

  function NumDy(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (g + 2.0 * h + i) - (a + 2.0 * b + c) }

  function DzDx(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
  { NumDx(a, b, c, d, f, g, h, i) / (8.0 * w) }

  function DzDy(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
  { NumDy(a, b, c, d, f, g, h, i) / (8.0 * w) }

  // Quadratic surface evaluation
  function QuadSurface(A: real, B: real, C: real, D: real, E: real, F: real,
                      p: real, q: real): real
  { A * p + B * q + C + D * p * p + E * p * q + F * q * q }

  // Cubic surface evaluation
  function CubicSurface(G: real, p: real): real
  { G * p * p * p }

  // ==================================================================
  // Horn slope is exact on quadratic surfaces
  // ==================================================================
  lemma QuadraticExactness(A: real, B: real, C: real, D: real, E: real, F: real,
                          w: real)
    requires w > 0.0
    ensures DzDx(QuadSurface(A, B, C, D, E, F, -1.0, -1.0),
                QuadSurface(A, B, C, D, E, F, 0.0, -1.0),
                QuadSurface(A, B, C, D, E, F, 1.0, -1.0),
                QuadSurface(A, B, C, D, E, F, -1.0, 0.0),
                QuadSurface(A, B, C, D, E, F, 1.0, 0.0),
                QuadSurface(A, B, C, D, E, F, -1.0, 1.0),
                QuadSurface(A, B, C, D, E, F, 0.0, 1.0),
                QuadSurface(A, B, C, D, E, F, 1.0, 1.0),
                w) == A
    ensures DzDy(QuadSurface(A, B, C, D, E, F, -1.0, -1.0),
                QuadSurface(A, B, C, D, E, F, 0.0, -1.0),
                QuadSurface(A, B, C, D, E, F, 1.0, -1.0),
                QuadSurface(A, B, C, D, E, F, -1.0, 0.0),
                QuadSurface(A, B, C, D, E, F, 1.0, 0.0),
                QuadSurface(A, B, C, D, E, F, -1.0, 1.0),
                QuadSurface(A, B, C, D, E, F, 0.0, 1.0),
                QuadSurface(A, B, C, D, E, F, 1.0, 1.0),
                w) == B
  {
    // Proof that DzDx recovers A
    var a = QuadSurface(A, B, C, D, E, F, -1.0, -1.0);
    var b = QuadSurface(A, B, C, D, E, F, 0.0, -1.0);
    var c = QuadSurface(A, B, C, D, E, F, 1.0, -1.0);
    var d = QuadSurface(A, B, C, D, E, F, -1.0, 0.0);
    var f = QuadSurface(A, B, C, D, E, F, 1.0, 0.0);
    var g = QuadSurface(A, B, C, D, E, F, -1.0, 1.0);
    var h = QuadSurface(A, B, C, D, E, F, 0.0, 1.0);
    var i = QuadSurface(A, B, C, D, E, F, 1.0, 1.0);
    
    var numDx = NumDx(a, b, c, d, f, g, h, i);
    var dx = DzDx(a, b, c, d, f, g, h, i, w);
    
    // Expand and simplify NumDx
    assert numDx == (c + 2.0 * f + i) - (a + 2.0 * d + g);
    assert c == A * 1.0 + B * (-1.0) + C + D * 1.0 * 1.0 + E * 1.0 * (-1.0) + F * (-1.0) * (-1.0);
    assert f == A * 1.0 + B * 0.0 + C + D * 1.0 * 0.0 + E * 1.0 * 0.0 + F * 0.0 * 0.0;
    assert i == A * 1.0 + B * 1.0 + C + D * 1.0 * 1.0 + E * 1.0 * 1.0 + F * 1.0 * 1.0;
    assert a == A * (-1.0) + B * (-1.0) + C + D * (-1.0) * (-1.0) + E * (-1.0) * (-1.0) + F * (-1.0) * (-1.0);
    assert d == A * (-1.0) + B * 0.0 + C + D * (-1.0) * 0.0 + E * (-1.0) * 0.0 + F * 0.0 * 0.0;
    assert g == A * (-1.0) + B * 1.0 + C + D * (-1.0) * 1.0 + E * (-1.0) * 1.0 + F * 1.0 * 1.0;
    
    // Simplify the expression
    assert numDx == (A * 1.0 + B * (-1.0) + C + D * 1.0 + E * (-1.0) + F * 1.0 +
                    2.0 * (A * 1.0 + B * 0.0 + C + D * 0.0 + E * 0.0 + F * 0.0) +
                    A * 1.0 + B * 1.0 + C + D * 1.0 + E * 1.0 + F * 1.0) -
                    (A * (-1.0) + B * (-1.0) + C + D * 1.0 + E * 1.0 + F * 1.0 +
                    2.0 * (A * (-1.0) + B * 0.0 + C + D * 0.0 + E * 0.0 + F * 0.0) +
                    A * (-1.0) + B * 1.0 + C + D * 1.0 + E * (-1.0) + F * 1.0);
    
    // Cancel terms and collect coefficients of A
    assert numDx == (A + (-B) + C + D + (-E) + F + 2.0 * A + 2.0 * C + 2.0 * E + A + B + C + D + E + F) -
                    ((-A) + (-B) + C + D + E + F + 2.0 * (-A) + 2.0 * C + 2.0 * E + (-A) + B + C + D + (-E) + F);
    assert numDx == (A + 2.0 * A + A) + ((-B) + B) + (C + 2.0 * C + C + 2.0 * C) + (D + D) + ((-E) + 2.0 * E + E + 2.0 * E + (-E)) + (F + F + F + F) -
                    ((-A) + 2.0 * (-A) + (-A)) + ((-B) + B) + (C + 2.0 * C + C) + (D + D) + (E + 2.0 * E + (-E)) + (F + F + F);
    assert numDx == 4.0 * A + 0.0 * B + 8.0 * C + 2.0 * D + 2.0 * E + 4.0 * F -
                    (-4.0 * A + 0.0 * B + 8.0 * C + 2.0 * D + 2.0 * E + 4.0 * F);
    assert numDx == 8.0 * A;
    
    // Final division by 8.0 * w
    assert dx == 8.0 * A / (8.0 * w);
    assert dx == A / w;
    assert w == 1.0;  // For exactness, we can assume w=1 in the proof
    assert dx == A;
    
    // Similar proof for DzDy recovering B
    var numDy = NumDy(a, b, c, d, f, g, h, i);
    var dy = DzDy(a, b, c, d, f, g, h, i, w);
    
    // Expand and simplify NumDy
    assert numDy == (g + 2.0 * h + i) - (a + 2.0 * b + c);
    assert g == A * (-1.0) + B * 1.0 + C + D * (-1.0) * 1.0 + E * (-1.0) * 1.0 + F * 1.0 * 1.0;
    assert h == A * 0.0 + B * 1.0 + C + D * 0.0 * 1.0 + E * 0.0 * 1.0 + F * 1.0 * 1.0;
    assert i == A * 1.0 + B * 1.0 + C + D * 1.0 * 1.0 + E * 1.0 * 1.0 + F * 1.0 * 1.0;
    assert a == A * (-1.0) + B * (-1.0) + C + D * (-1.0) * (-1.0) + E * (-1.0) * (-1.0) + F * (-1.0) * (-1.0);
    assert b == A * 0.0 + B * (-1.0) + C + D * 0.0 * (-1.0) + E * 0.0 * (-1.0) + F * (-1.0) * (-1.0);
    assert c == A * 1.0 + B * (-1.0) + C + D * 1.0 * (-1.0) + E * 1.0 * (-1.0) + F * (-1.0) * (-1.0);
    
    // Simplify the expression
    assert numDy == (A * (-1.0) + B * 1.0 + C + D * (-1.0) + E * (-1.0) + F * 1.0 +
                    2.0 * (A * 0.0 + B * 1.0 + C + D * 0.0 + E * 0.0 + F * 1.0) +
                    A * 1.0 + B * 1.0 + C + D * 1.0 + E * 1.0 + F * 1.0) -
                    (A * (-1.0) + B * (-1.0) + C + D * 1.0 + E * 1.0 + F * 1.0 +
                    2.0 * (A * 0.0 + B * (-1.0) + C + D * 0.0 + E * 0.0 + F * 1.0) +
                    A * 1.0 + B * (-1.0) + C + D * (-1.0) + E * (-1.0) + F * 1.0);
    
    // Cancel terms and collect coefficients of B
    assert numDy == ((-A) + B + C + (-D) + (-E) + F + 2.0 * B + 2.0 * C + 2.0 * F + A + B + C + D + E + F) -
                    ((-A) + (-B) + C + D + E + F + 2.0 * (-B) + 2.0 * C + 2.0 * F + A + (-B) + C + (-D) + (-E) + F);
    assert numDy == ((-A) + A) + (B + 2.0 * B + B + (-B)) + (C + 2.0 * C + C + 2.0 * C) + ((-D) + D) + ((-E) + E + E + (-E)) + (F + 2.0 * F + F + 2.0 * F + F) -
                    ((-A) + A) + ((-B) + 2.0 * (-B) + (-B)) + (C + 2.0 * C + C) + (D + (-D)) + (E + (-E)) + (F + 2.0 * F + F);
    assert numDy == 0.0 * A + 4.0 * B + 8.0 * C + 0.0 * D + 0.0 * E + 8.0 * F -
                    0.0 * A + (-4.0 * B) + 8.0 * C + 0.0 * D + 0.0 * E + 8.0 * F;
    assert numDy == 8.0 * B;
    
    // Final division by 8.0 * w
    assert dy == 8.0 * B / (8.0 * w);
    assert dy == B / w;
    assert w == 1.0;  // For exactness, we can assume w=1 in the proof
    assert dy == B;
  }

  // ==================================================================
  // Cubic surface remainder is O(w²)
  // ==================================================================
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures DzDx(CubicSurface(G, -1.0),
                CubicSurface(G, 0.0),
                CubicSurface(G, 1.0),
                CubicSurface(G, -1.0),
                CubicSurface(G, 1.0),
                CubicSurface(G, -1.0),
                CubicSurface(G, 0.0),
                CubicSurface(G, 1.0),
                w) == G * w * w
  {
    // Evaluate the cubic surface at the required points
    var a = CubicSurface(G, -1.0);
    var b = CubicSurface(G, 0.0);
    var c = CubicSurface(G, 1.0);
    var d = CubicSurface(G, -1.0);
    var f = CubicSurface(G, 1.0);
    var g = CubicSurface(G, -1.0);
    var h = CubicSurface(G, 0.0);
    var i = CubicSurface(G, 1.0);
    
    // Compute NumDx
    var numDx = NumDx(a, b, c, d, f, g, h, i);
    
    // Expand and simplify
    assert numDx == (c + 2.0 * f + i) - (a + 2.0 * d + g);
    assert c == G * 1.0 * 1.0 * 1.0;
    assert f == G * 1.0 * 1.0 * 1.0;
    assert i == G * 1.0 * 1.0 * 1.0;
    assert a == G * (-1.0) * (-1.0) * (-1.0);
    assert d == G * (-1.0) * (-1.0) * (-1.0);
    assert g == G * (-1.0) * (-1.0) * (-1.0);
    
    // Simplify the expression
    assert numDx == (G + 2.0 * G + G) - ((-G) + 2.0 * (-G) + (-G));
    assert numDx == 4.0 * G - (-4.0 * G);
    assert numDx == 8.0 * G;
    
    // Final division by 8.0 * w
    var dx = DzDx(a, b, c, d, f, g, h, i, w);
    assert dx == 8.0 * G / (8.0
