// P004: Horn slope exact on quadratic surfaces, cubic remainder O(w^2)
// Formalization of the Horn gradient estimator's consistency properties.

// Horn finite-difference gradient estimator for a 3×3 grid.
// Grid points are labeled as:
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

// A general quadratic surface: z = A x + B y + C + D x² + E x y + F y²
function QuadraticSurface(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
{
  A * x + B * y + C + D * x * x + E * x * y + F * y * y
}

// Sample the quadratic surface at the 8 neighbor points of a 3×3 grid centered at (0,0).
// The grid spacing is w, and the center point (0,0) is omitted (not used by Horn).
function QuadraticWindow(A: real, B: real, C: real, D: real, E: real, F: real, w: real): 
  (a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real)
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
// The computed DzDx equals the true partial derivative ∂z/∂x = A + 2D x + E y at (0,0) = A.
// Similarly, DzDy equals B.
lemma HornExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
  ensures HornDzDx(QuadraticWindow(A, B, C, D, E, F, w), w) == A
  ensures HornDzDy(QuadraticWindow(A, B, C, D, E, F, w), w) == B
{
  var (a, b, c, d, f, g, h, i) := QuadraticWindow(A, B, C, D, E, F, w);
  // Expand each term according to the quadratic definition.
  // Compute the numerator of DzDx: (c + 2f + i) - (a + 2d + g)
  // Substitute the expressions and simplify.
  // The following equalities are derived by algebraic simplification:
  //   c = A*w + B*(-w) + C + D*w² + E*w*(-w) + F*(-w)²
  //     = A*w - B*w + C + D*w² - E*w² + F*w²
  //   f = A*w + B*0 + C + D*w² + E*w*0 + F*0² = A*w + C + D*w²
  //   i = A*w + B*w + C + D*w² + E*w*w + F*w² = A*w + B*w + C + D*w² + E*w² + F*w²
  //   a = A*(-w) + B*(-w) + C + D*(-w)² + E*(-w)*(-w) + F*(-w)²
  //     = -A*w - B*w + C + D*w² + E*w² + F*w²
  //   d = A*(-w) + B*0 + C + D*(-w)² + E*(-w)*0 + F*0² = -A*w + C + D*w²
  //   g = A*(-w) + B*w + C + D*(-w)² + E*(-w)*w + F*w² = -A*w + B*w + C + D*w² - E*w² + F*w²
  // Then compute the linear combination.
  // The constant C and quadratic terms D, E, F cancel out.
  // The remaining terms in the numerator are 8 * A * w.
  // Division by 8*w gives A.
  // Similarly for DzDy.
  // Dafny can verify this by direct computation.
  calc {
    HornDzDx(a, b, c, d, f, g, h, i, w);
    ==
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);
    ==
    A;
  }
  calc {
    HornDzDy(a, b, c, d, f, g, h, i, w);
    ==
    ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w);
    ==
    B;
  }
}

// Cubic surface: z = G * x³ (no y dependence).
function CubicSurface(G: real, x: real, y: real): real
{
  G * x * x * x
}

// Sample the cubic surface at the 8 neighbor points.
function CubicWindow(G: real, w: real): 
  (a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real)
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

// The true partial derivative at the origin for z = G x³ is 0.
function TrueDzDxCubic(G: real): real
{
  0.0
}

// Lemma: The remainder (error) of HornDzDx on z = G x³ at the origin is exactly G * w².
lemma CubicRemainderExact(G: real, w: real)
  requires w > 0.0
  ensures HornDzDx(CubicWindow(G, w), w) - TrueDzDxCubic(G) == G * w * w
{
  var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);
  // Expand each term:
  //   a = G * (-w)³ = -G * w³
  //   b = G * 0³ = 0
  //   c = G * w³
  //   d = G * (-w)³ = -G * w³
  //   f = G * w³
  //   g = G * (-w)³ = -G * w³
  //   h = G * 0³ = 0
  //   i = G * w³
  // Compute numerator of DzDx: (c + 2f + i) - (a + 2d + g)
  //   = (G w³ + 2 G w³ + G w³) - (-G w³ + 2(-G w³) + (-G w³))
  //   = (4 G w³) - (-4 G w³) = 8 G w³
  // Divide by 8w: G w².
  // True derivative at origin is 0, so remainder = G w².
  calc {
    HornDzDx(a, b, c, d, f, g, h, i, w) - TrueDzDxCubic(G);
    ==
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w) - 0.0;
    ==
    G * w * w;
  }
}

// Corollary: The remainder is O(w²) as w → 0.
// Specifically, |remainder| ≤ |G| * w² for all w > 0.
lemma CubicRemainderOrder(G: real, w: real)
  requires w > 0.0
  ensures |HornDzDx(CubicWindow(G, w), w) - TrueDzDxCubic(G)| <= |G| * w * w
{
  CubicRemainderExact(G, w);
  // The exact equality implies the inequality.
}
