method QuadraticExactness(A: real, B: real, C: real, w: real, i: int, j: int)
  requires w > 0.0
{
  // Define quadratic surface: z = A*x + B*y + C
  function z(i': int, j': int): real
    requires w > 0.0
  {
    let x := i' as real * w;
    let y := j' as real * w;
    A*x + B*y + C
  }

  // Horn slope operator for x-direction
  function DzDx(): real
    requires w > 0.0
  {
    (z(i+1, j) - z(i-1, j)) / (2.0 * w)
  }

  // Horn slope operator for y-direction
  function DzDy(): real
    requires w > 0.0
  {
    (z(i, j+1) - z(i, j-1)) / (2.0 * w)
  }

  // Verify exact gradient recovery
  assert DzDx() == A;
  assert DzDy() == B;
}

method CubicRemainder(G: real, w: real)
  requires w > 0.0
{
  // Define cubic surface: z = G*x^3
  function z(i': int, j': int): real
    requires w > 0.0
  {
    let x := i' as real * w;
    G * x * x * x
  }

  // Horn slope operator at origin (0,0)
  function DzDx(): real
    requires w > 0.0
  {
    (z(1, 0) - z(-1, 0)) / (2.0 * w)
  }

  // Verify remainder term
  assert DzDx() == G * w * w;
}
