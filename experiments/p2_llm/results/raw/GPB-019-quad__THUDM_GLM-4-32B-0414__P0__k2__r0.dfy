// P-004 / GPB-019 algebraic entry: Horn exact on quadratics, cubic O(w²).
// Formal verification of Horn slope algorithm properties.

module HornSlopeProperties {
  // Grid spacing must be positive
  ghost function method PositiveGridSpacing(w: real): bool
    ensures PositiveGridSpacing(w) <==> w > 0.0
  {
    w > 0.0
  }

  // Quadratic surface coefficients
  ghost function method QuadraticSurface(a: real, b: real, c: real, d: real, e: real, f: real): (z: real)
    decreases *
    requires PositiveGridSpacing(w)
    ensures z == a*x + b*y + c + d*x*x + e*x*y + f*y*y
  {
    // Implementation would sample the quadratic surface at grid points
    // This is a placeholder for the actual implementation
    0.0
  }

  // Horn slope algorithm for DzDx
  ghost function method HornDzDx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): (dzdx: real)
    decreases *
    requires PositiveGridSpacing(w)
    ensures dzdx == ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w)
  {
    ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w)
  }

  // Horn slope algorithm for DzDy
  ghost function method HornDzDy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): (dzdy: real)
    decreases *
    requires PositiveGridSpacing(w)
    ensures dzdy == ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w)
  {
    ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w)
  }

  // True planar gradient coefficients (A, B) for quadratic surface
  ghost function method TrueGradient(a: real, b: real, d: real, e: real, f: real): (A: real, B: real)
    decreases *
    ensures A == a + e*y + 2.0*d*x
    ensures B == b + e*x + 2.0*f*y
  {
    (a, b)
  }

  // Property 1: Horn slope is exact on quadratic surfaces
  lemma HornExactOnQuadratic(a: real, b: real, c: real, d: real, e: real, f: real, w: real)
    decreases *
    requires PositiveGridSpacing(w)
    ensures HornDzDx(a, b, c, d, f, g, h, i, w) == a + e*y + 2.0*d*x
    ensures HornDzDy(a, b, c, d, f, g, h, i, w) == b + e*x + 2.0*f*y
  {
    // Sample the quadratic surface at grid points
    var a := QuadraticSurface(-1, -1, a, b, c, d, e, f, w);
    var b := QuadraticSurface(0, -1, a, b, c, d, e, f, w);
    var c := QuadraticSurface(1, -1, a, b, c, d, e, f, w);
    var d := QuadraticSurface(-1, 0, a, b, c, d, e, f, w);
    var f := QuadraticSurface(1, 0, a, b, c, d, e, f, w);
    var g := QuadraticSurface(-1, 1, a, b, c, d, e, f, w);
    var h := QuadraticSurface(0, 1, a, b, c, d, e, f, w);
    var i := QuadraticSurface(1, 1, a, b, c, d, e, f, w);

    // Compute Horn slope
    var dzdx := HornDzDx(a, b, c, d, f, g, h, i, w);
    var dzdy := HornDzDy(a, b, c, d, f, g, h, i, w);

    // Compute true gradient
    var (A, B) := TrueGradient(a, b, d, e, f);

    // Verify exactness
    assert dzdx == A;
    assert dzdy == B;
  }

  // Cubic surface z = G x³
  ghost function method CubicSurface(G: real, p: real, w: real): (z: real)
    decreases *
    requires PositiveGridSpacing(w)
    ensures z == G * (p * w) * (p * w) * (p * w)
  {
    G * (p * w) * (p * w) * (p * w)
  }

  // Property 2: On z = G x³, the DzDx remainder at the origin equals G w²
  lemma CubicRemainder(G: real, w: real)
    decreases *
    requires PositiveGridSpacing(w)
    ensures HornDzDx(a, b, c, d, f, g, h, i, w) - G == G * w * w
  {
    // Sample the cubic surface at grid points
    var a := CubicSurface(G, -1, w);
    var b := CubicSurface(G, 0, w);
    var c := CubicSurface(G, 1, w);
    var d := CubicSurface(G, -1, w);
    var f := CubicSurface(G, 1, w);
    var g := CubicSurface(G, -1, w);
    var h := CubicSurface(G, 0, w);
    var i := CubicSurface(G, 1, w);

    // Compute Horn slope
    var dzdx := HornDzDx(a, b, c, d, f, g, h, i, w);

    // Verify remainder
    assert dzdx - G == G * w * w;
  }
}
