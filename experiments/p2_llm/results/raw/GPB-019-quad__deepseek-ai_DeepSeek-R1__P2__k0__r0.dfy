// P2 · Iterative repair (verifier feedback)

function method HornDzDx(x: real, y: real, w: real, z: (real,real) -> real): real
  requires w != 0.0
{
  (z(x+w, y) - z(x-w, y)) / (2.0 * w)
}

function method HornDzDy(x: real, y: real, w: real, z: (real,real) -> real): real
  requires w != 0.0
{
  (z(x, y+w) - z(x, y-w)) / (2.0 * w)
}

lemma LemmaQuadraticExactness(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w != 0.0
  ensures HornDzDx(0.0, 0.0, w, (x,y) => A*x + B*y + C*x*x + D*x*y + E*y*y + F) == A
  ensures HornDzDy(0.0, 0.0, w, (x,y) => A*x + B*y + C*x*x + D*x*y + E*y*y + F) == B
{
}

lemma LemmaCubicRemainder(G: real, w: real)
  requires w != 0.0
  ensures HornDzDx(0.0, 0.0, w, (x,y) => G*x*x*x) == G * w * w
{
}
