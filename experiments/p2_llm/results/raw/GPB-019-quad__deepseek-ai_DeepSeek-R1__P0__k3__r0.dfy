// P0: Zero-shot auto-formalization for Horn slope properties
// Horn slope is exact on quadratic surfaces: recovers A and B exactly.
// On cubic z = G x^3: DzDx remainder at origin is G w^2.

function horn_dzdx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
{
  ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w)
}

function horn_dzdy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
{
  ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w)
}

function quadratic(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A*x + B*y + C + D*x*x + E*x*y + F*y*y
}

function cubic_x(x: real, y: real, G: real): real
{
  G * (x*x*x)
}

lemma QuadraticExact(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
  ensures horn_dzdx(
      quadratic(-w, -w, A, B, C, D, E, F),
      quadratic(0.0, -w, A, B, C, D, E, F),
      quadratic(w, -w, A, B, C, D, E, F),
      quadratic(-w, 0.0, A, B, C, D, E, F),
      quadratic(w, 0.0, A, B, C, D, E, F),
      quadratic(-w, w, A, B, C, D, E, F),
      quadratic(0.0, w, A, B, C, D, E, F),
      quadratic(w, w, A, B, C, D, E, F),
      w
  ) == A
  ensures horn_dzdy(
      quadratic(-w, -w, A, B, C, D, E, F),
      quadratic(0.0, -w, A, B, C, D, E, F),
      quadratic(w, -w, A, B, C, D, E, F),
      quadratic(-w, 0.0, A, B, C, D, E, F),
      quadratic(w, 0.0, A, B, C, D, E, F),
      quadratic(-w, w, A, B, C, D, E, F),
      quadratic(0.0, w, A, B, C, D, E, F),
      quadratic(w, w, A, B, C, D, E, F),
      w
  ) == B
{
  // Proof follows from algebraic expansion and cancellation
}

lemma CubicRemainder(G: real, w: real)
  requires w > 0.0
  ensures horn_dzdx(
      cubic_x(-w, -w, G),
      cubic_x(0.0, -w, G),
      cubic_x(w, -w, G),
      cubic_x(-w, 0.0, G),
      cubic_x(w, 0.0, G),
      cubic_x(-w, w, G),
      cubic_x(0.0, w, G),
      cubic_x(w, w, G),
      w
  ) == G * w * w
{
  // Proof follows from algebraic expansion and simplification
}
