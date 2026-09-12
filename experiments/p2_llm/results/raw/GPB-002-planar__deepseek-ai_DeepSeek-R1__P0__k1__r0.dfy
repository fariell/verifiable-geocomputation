// This Dafny module proves that the Horn finite-difference operator
// exactly recovers the slope parameters A and B of a planar surface
// z = A*x + B*y + C on a regular grid with spacing w>0.

const A: real
const B: real
const C: real
const w: real

function grid(i: int, j: int): real
{
  A * i * w + B * j * w + C
}

function DzDx(i: int, j: int): real
{
  (grid(i+1, j) - grid(i-1, j)) / (2.0 * w)
}

function DzDy(i: int, j: int): real
{
  (grid(i, j+1) - grid(i, j-1)) / (2.0 * w)
}

lemma LemmaExactRecovery(i: int, j: int)
  requires w > 0.0
  ensures DzDx(i, j) == A
  ensures DzDy(i, j) == B
{
  // For DzDx
  assert grid(i+1, j) == A * (i+1) * w + B * j * w + C;
  assert grid(i-1, j) == A * (i-1) * w + B * j * w + C;
  assert grid(i+1, j) - grid(i-1, j) == 2 * A * w;
  assert DzDx(i, j) == (2 * A * w) / (2.0 * w) == A;

  // For DzDy
  assert grid(i, j+1) == A * i * w + B * (j+1) * w + C;
  assert grid(i, j-1) == A * i * w + B * (j-1) * w + C;
  assert grid(i, j+1) - grid(i, j-1) == 2 * B * w;
  assert DzDy(i, j) == (2 * B * w) / (2.0 * w) == B;
}
