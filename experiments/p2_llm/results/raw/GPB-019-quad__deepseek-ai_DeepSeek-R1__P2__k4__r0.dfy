function method QuadraticSurface(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A*x + B*y + C*x*x + D*x*y + E*y*y + F
}

function method CubicSurface(x: real, G: real): real
{
  G * x * x * x
}

function method HornDzDx(grid: (int,int) -> real, i: int, j: int, w: real): real
  requires w > 0.0
{
  (grid(i+1, j) - grid(i-1, j)) / (2.0 * w)
}

function method HornDzDy(grid: (int,int) -> real, i: int, j: int, w: real): real
  requires w > 0.0
{
  (grid(i, j+1) - grid(i, j-1)) / (2.0 * w)
}

function method QuadraticGrid(i: int, j: int, A: real, B: real, C: real, D: real, E: real, F: real, w: real): real
{
  QuadraticSurface(i*w, j*w, A, B, C, D, E, F)
}

function method CubicGrid(i: int, j: int, G: real, w: real): real
{
  CubicSurface(i*w, G)
}

method QuadraticExactness(i: int, j: int, A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
  ensures HornDzDx((i',j') => QuadraticGrid(i',j',A,B,C,D,E,F,w), i, j, w) == A + 2.0*C*(i*w) + D*(j*w)
  ensures HornDzDy((i',j') => QuadraticGrid(i',j',A,B,C,D,E,F,w), i, j, w) == B + D*(i*w) + 2.0*E*(j*w)
{
  // Proof by Dafny's automatic polynomial arithmetic
}

method CubicRemainder(G: real, w: real)
  requires w > 0.0
  ensures HornDzDx((i',j') => CubicGrid(i',j',G,w), 0, 0, w) == G * w * w
{
  // Proof by Dafny's automatic polynomial arithmetic
}
