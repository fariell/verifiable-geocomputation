// Horn finite-difference slope operator exactness on a plane
// Formalization of: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w>0, the Horn finite-difference estimates DzDx and DzDy recover A and B exactly.

module HornPlaneExactness {
  // Grid dimensions
  const N: int
  const M: int
  ghost predicate GridSizeValid()
    reads {}
    ensures GridSizeValid() ==> N >= 1 && M >= 1
  {
    N >= 1 && M >= 1
  }

  // Grid spacing
  const w: real
  axiom w_positive: w > 0.0

  // Plane parameters
  const A: real
  const B: real
  const C: real

  // Elevation function for the plane
  function elevation(i: int, j: int): real
    requires 0 <= i < N && 0 <= j < M
    reads {}
  {
    A * (i as real) * w + B * (j as real) * w + C
  }

  // Horn finite-difference operator (central difference for interior cells)
  function hornDzDx(i: int, j: int): real
    requires GridSizeValid()
    requires 1 <= i < N-1 && 0 <= j < M
    reads {}
  {
    (elevation(i+1, j) - elevation(i-1, j)) / (2.0 * w)
  }

  function hornDzDy(i: int, j: int): real
    requires GridSizeValid()
    requires 0 <= i < N && 1 <= j < M-1
    reads {}
  {
    (elevation(i, j+1) - elevation(i, j-1)) / (2.0 * w)
  }

  // Main theorem: Horn operator recovers exact slopes A and B for interior cells
  lemma HornExactOnPlane(i: int, j: int)
    requires GridSizeValid()
    requires 1 <= i < N-1 && 1 <= j < M-1
    ensures hornDzDx(i, j) == A
    ensures hornDzDy(i, j) == B
    decreases i, j
  {
    // Expand elevation definitions
    calc == {
      hornDzDx(i, j);
      (elevation(i+1, j) - elevation(i-1, j)) / (2.0 * w);
      // Substitute elevation formula
      ( (A * ((i+1) as real) * w + B * (j as real) * w + C) -
        (A * ((i-1) as real) * w + B * (j as real) * w + C) ) / (2.0 * w);
      // Cancel B*j*w + C terms
      (A * w * ((i+1) as real - (i-1) as real)) / (2.0 * w);
      // Simplify (i+1) - (i-1) = 2
      (A * w * 2.0) / (2.0 * w);
      // Cancel 2 and w
      A;
    }

    calc == {
      hornDzDy(i, j);
      (elevation(i, j+1) - elevation(i, j-1)) / (2.0 * w);
      // Substitute elevation formula
      ( (A * (i as real) * w + B * ((j+1) as real) * w + C) -
        (A * (i as real) * w + B * ((j-1) as real) * w + C) ) / (2.0 * w);
      // Cancel A*i*w + C terms
      (B * w * ((j+1) as real - (j-1) as real)) / (2.0 * w);
      // Simplify (j+1) - (j-1) = 2
      (B * w * 2.0) / (2.0 * w);
      // Cancel 2 and w
      B;
    }
  }

  // Corollary: The property holds for all interior cells
  lemma HornExactEverywhere()
    requires GridSizeValid()
    ensures forall i, j :: 
      1 <= i < N-1 && 1 <= j < M-1 ==> 
      hornDzDx(i, j) == A && hornDzDy(i, j) == B
  {
    forall i, j | 1 <= i < N-1 && 1 <= j < M-1
      ensures hornDzDx(i, j) == A && hornDzDy(i, j) == B
    {
      HornExactOnPlane(i, j);
    }
  }
}
