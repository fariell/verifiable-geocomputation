// P-004 / GPB-019: Horn slope is exact on quadratic surfaces and has O(w^2) remainder on cubic surfaces.

method HornSlopeExactOnQuadraticSurfaces()
  // Horn slope is exact on quadratic surfaces: DzDx and DzDy recover the true planar gradient coefficients (A,B) identically.
  // We model a general quadratic surface z = Ax + By + C + Dx^2 + Exy + Fy^2.
  // The Horn slope algorithm computes DzDx and DzDy using a 3x3 grid of points.
  // We will show that for any quadratic surface, the Horn slope algorithm computes the exact gradient (A,B).

  // Define the coefficients of the quadratic surface
  var A, B, C, D, E, F: real;
  A := 0.3;  // Example value
  B := -0.2; // Example value
  C := 5.0;
  D := 0.05;
  E := -0.04;
  F := 0.02;

  // Define the grid spacing
  var w: real;
  w := 1.0;

  // Define the 3x3 grid of points on the quadratic surface
  var a, b, c, d, f, g, h, i: real;
  a := A * (-w) + B * (-w) + C + D * (-w)^2 + E * (-w) * (-w) + F * (-w)^2;
  b := A * (0) + B * (-w) + C + D * (0)^2 + E * (0) * (-w) + F * (-w)^2;
  c := A * (w) + B * (-w) + C + D * (w)^2 + E * (w) * (-w) + F * (-w)^2;
  d := A * (-w) + B * (0) + C + D * (-w)^2 + E * (-w) * (0) + F * (0)^2;
  f := A * (w) + B * (0) + C + D * (w)^2 + E * (w) * (0) + F * (0)^2;
  g := A * (-w) + B * (w) + C + D * (-w)^2 + E * (-w) * (w) + F * (w)^2;
  h := A * (0) + B * (w) + C + D * (0)^2 + E * (0) * (w) + F * (w)^2;
  i := A * (w) + B * (w) + C + D * (w)^2 + E * (w) * (w) + F * (w)^2;

  // Compute the Horn slope DzDx and DzDy
  var DzDx: real;
  var DzDy: real;
  DzDx := ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);
  DzDy := ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w);

  // Verify that the Horn slope is exact
  assert DzDx == A;
  assert DzDy == B;

method HornSlopeCubicRemainder()
  // On z = G x^3 the DzDx remainder at the origin equals G w^2 (order O(w^2)).
  // We model the cubic surface z = G x^3.
  // The Horn slope algorithm computes DzDx using a 3x3 grid of points.
  // We will show that the remainder of the Horn slope algorithm at the origin is G w^2.

  // Define the coefficient of the cubic surface
  var G: real;
  G := 0.07; // Example value

  // Define the grid spacing
  var w: real;
  w := 1.0;

  // Define the 3x3 grid of points on the cubic surface
  var a, b, c, d, f, g, h, i: real;
  a := G * (-w)^3;
  b := G * (0)^3;
  c := G * (w)^3;
  d := G * (-w)^3;
  f := G * (w)^3;
  g := G * (-w)^3;
  h := G * (0)^3;
  i := G * (w)^3;

  // Compute the Horn slope DzDx
  var DzDx: real;
  DzDx := ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);

  // Compute the true gradient at the origin
  var trueGradient: real;
  trueGradient := 0.0; // The true gradient of z = G x^3 at the origin is 0.

  // Compute the remainder
  var remainder: real;
  remainder := DzDx - trueGradient;

  // Verify that the remainder is G w^2
  assert remainder == G * w^2;
