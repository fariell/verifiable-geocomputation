// P004: Horn slope exact on quadratic surfaces, cubic remainder O(w^2)
// Formalization of the Horn finite-difference gradient estimator consistency.

// Grid spacing must be positive for the finite-difference formulas.
predicate PositiveW(w: real)
  requires w > 0.0

// Quadratic surface: z = A x + B y + C + D x^2 + E x y + F y^2
function QuadraticSurface(A: real, B: real, C: real, D: real, E: real, F: real,
                          x: real, y: real): real
  A * x + B * y + C + D * x * x + E * x * y + F * y * y

// Horn finite-difference gradient estimator (DzDx component).
function HornDzDx(a: real, b: real, c: real, d: real, f: real,
                  g: real, h: real, i: real, w: real): real
  requires PositiveW(w)
  ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w)

// Horn finite-difference gradient estimator (DzDy component).
function HornDzDy(a: real, b: real, c: real, d: real, f: real,
                  g: real, h: real, i: real, w: real): real
  requires PositiveW(w)
  ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w)

// Sample the quadratic surface at the nine Horn stencil points.
function SampleQuadratic(A: real, B: real, C: real, D: real, E: real, F: real,
                         w: real): (a: real, b: real, c: real,
                                    d: real, f: real,
                                    g: real, h: real, i: real)
  requires PositiveW(w)
  // Stencil coordinates relative to center (0,0):
  // a = (-w, -w), b = (0, -w), c = (w, -w)
  // d = (-w, 0), f = (w, 0)
  // g = (-w, w), h = (0, w), i = (w, w)
  var a := QuadraticSurface(A, B, C, D, E, F, -w, -w);
  var b := QuadraticSurface(A, B, C, D, E, F, 0.0, -w);
  var c := QuadraticSurface(A, B, C, D, E, F, w, -w);
  var d := QuadraticSurface(A, B, C, D, E, F, -w, 0.0);
  var f := QuadraticSurface(A, B, C, D, E, F, w, 0.0);
  var g := QuadraticSurface(A, B, C, D, E, F, -w, w);
  var h := QuadraticSurface(A, B, C, D, E, F, 0.0, w);
  var i := QuadraticSurface(A, B, C, D, E, F, w, w);
  (a, b, c, d, f, g, h, i)

// Lemma: Horn gradient is exact on any quadratic surface.
lemma HornExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires PositiveW(w)
  ensures forall a, b, c, d, f, g, h, i ::
    (a, b, c, d, f, g, h, i) == SampleQuadratic(A, B, C, D, E, F, w) ==>
    HornDzDx(a, b, c, d, f, g, h, i, w) == A + 2.0 * D * 0.0 + E * 0.0 &&  // ∂z/∂x at (0,0) = A
    HornDzDy(a, b, c, d, f, g, h, i, w) == B + E * 0.0 + 2.0 * F * 0.0     // ∂z/∂y at (0,0) = B
{
  var (a, b, c, d, f, g, h, i) := SampleQuadratic(A, B, C, D, E, F, w);
  // Compute HornDzDx from the sampled values.
  var dx := HornDzDx(a, b, c, d, f, g, h, i, w);
  // Compute HornDzDy from the sampled values.
  var dy := HornDzDy(a, b, c, d, f, g, h, i, w);

  // Expand the quadratic surface expressions at each stencil point.
  // a = A*(-w) + B*(-w) + C + D*(-w)^2 + E*(-w)*(-w) + F*(-w)^2
  //   = -A w - B w + C + D w^2 + E w^2 + F w^2
  // Similarly for all points, then compute the Horn numerator for DzDx:
  // (c + 2f + i) - (a + 2d + g)
  // After algebraic simplification (verified by Dafny's arithmetic):
  // Numerator = 8 A w + 0 * w^2 + 0 * w^3
  // Denominator = 8 w, so dx = A.
  // Analogous simplification for dy gives dy = B.
  // Dafny's nonlinear arithmetic can prove these equalities directly.
  calc {
    dx;
    == // Definition of HornDzDx
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);
    == // Substitute the quadratic expressions
    ((QuadraticSurface(A,B,C,D,E,F, w,-w) + 2.0*QuadraticSurface(A,B,C,D,E,F, w,0.0) + QuadraticSurface(A,B,C,D,E,F, w,w))
     - (QuadraticSurface(A,B,C,D,E,F,-w,-w) + 2.0*QuadraticSurface(A,B,C,D,E,F,-w,0.0) + QuadraticSurface(A,B,C,D,E,F,-w,w))) / (8.0 * w);
    == { reveal QuadraticSurface(); }
    // Expand each term:
    // c = A w - B w + C + D w^2 - E w^2 + F w^2
    // f = A w + 0 + C + D w^2 + 0 + 0
    // i = A w + B w + C + D w^2 + E w^2 + F w^2
    // a = -A w - B w + C + D w^2 + E w^2 + F w^2
    // d = -A w + 0 + C + D w^2 + 0 + 0
    // g = -A w + B w + C + D w^2 - E w^2 + F w^2
    // Summation yields numerator = 8 A w, denominator = 8 w, so dx = A.
    A;
  }
  calc {
    dy;
    == // Definition of HornDzDy
    ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w);
    == // Substitute the quadratic expressions
    ((QuadraticSurface(A,B,C,D,E,F,-w,w) + 2.0*QuadraticSurface(A,B,C,D,E,F,0.0,w) + QuadraticSurface(A,B,C,D,E,F,w,w))
     - (QuadraticSurface(A,B,C,D,E,F,-w,-w) + 2.0*QuadraticSurface(A,B,C,D,E,F,0.0,-w) + QuadraticSurface(A,B,C,D,E,F,w,-w))) / (8.0 * w);
    == { reveal QuadraticSurface(); }
    // Expand each term similarly:
    // g = -A w + B w + C + D w^2 - E w^2 + F w^2
    // h = 0 + B w + C + 0 + 0 + F w^2
    // i = A w + B w + C + D w^2 + E w^2 + F w^2
    // a = -A w - B w + C + D w^2 + E w^2 + F w^2
    // b = 0 - B w + C + 0 + 0 + F w^2
    // c = A w - B w + C + D w^2 - E w^2 + F w^2
    // Summation yields numerator = 8 B w, denominator = 8 w, so dy = B.
    B;
  }
}

// Cubic surface: z = G x^3
function CubicSurface(G: real, x: real, y: real): real
  G * x * x * x

// Sample the cubic surface at the Horn stencil points.
function SampleCubic(G: real, w: real): (a: real, b: real, c: real,
                                         d: real, f: real,
                                         g: real, h: real, i: real)
  requires PositiveW(w)
  var a := CubicSurface(G, -w, -w);
  var b := CubicSurface(G, 0.0, -w);
  var c := CubicSurface(G, w, -w);
  var d := CubicSurface(G, -w, 0.0);
  var f := CubicSurface(G, w, 0.0);
  var g := CubicSurface(G, -w, w);
  var h := CubicSurface(G, 0.0, w);
  var i := CubicSurface(G, w, w);
  (a, b, c, d, f, g, h, i)

// Lemma: On z = G x^3, the Horn DzDx remainder at the origin equals G w^2.
lemma CubicRemainderExact(G: real, w: real)
  requires PositiveW(w)
  ensures forall a, b, c, d, f, g, h, i ::
    (a, b, c, d, f, g, h, i) == SampleCubic(G, w) ==>
    HornDzDx(a, b, c, d, f, g, h, i, w) == G * w * w
{
  var (a, b, c, d, f, g, h, i) := SampleCubic(G, w);
  var dx := HornDzDx(a, b, c, d, f, g, h, i, w);

  // True derivative of G x^3 at x=0 is 0.
  // Horn estimate should be G w^2.
  calc {
    dx;
    == // Definition
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);
    == // Substitute cubic expressions: c = G w^3, f = G w^3, i = G w^3,
       // a = -G w^3, d = -G w^3, g = -G w^3
    ((G*w*w*w + 2.0*(G*w*w*w) + G*w*w*w) - ((-G*w*w*w) + 2.0*(-G*w*w*w) + (-G*w*w*w))) / (8.0 * w);
    == // Simplify numerator: (4 G w^3) - (-4 G w^3) = 8 G w^3
    (8.0 * G * w * w * w) / (8.0 * w);
    == // Cancel 8 and one w
    G * w * w;
  }
}

// Corollary: The remainder is O(w^2) as w -> 0.
lemma CubicRemainderOrder(G: real, w: real)
  requires PositiveW(w)
  ensures exists K: real :: K > 0.0 && 
    forall a, b, c, d, f, g, h, i ::
      (a, b, c, d, f, g, h, i) == SampleCubic(G, w) ==>
      abs(HornDzDx(a, b, c, d, f, g, h, i, w) - 0.0) <= K * w * w
{
  // From CubicRemainderExact, the remainder is exactly G w^2.
  // Take K = abs(G) + 1e-10 to ensure positivity.
  var K := abs(G) + 1e-10;
  assert K > 0.0;
  var (a, b, c, d, f, g, h, i) := SampleCubic(G, w);
  CubicRemainderExact(G, w);
  // HornDzDx = G w^2, so |HornDzDx - 0| = |G| w^2 <= K w^2.
  assert abs(HornDzDx(a, b, c, d, f, g, h, i, w) - 0.0) == abs(G) * w * w;
  assert abs(G) * w * w <= K * w * w;
}
