// Horn finite-difference slope operator exactness on a plane
// Formalization of: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w>0, the Horn finite-difference estimates DzDx and DzDy recover A and B exactly.

module HornPlaneExact {
  // Grid dimensions
  const N: int
  const M: int
  // Grid spacing (positive)
  const w: real
  ghost predicate w_pos() ensures w_pos() == (w > 0.0) { w > 0.0 }
  // Plane parameters
  const A: real
  const B: real
  const C: real

  // Elevation function for the plane
  function elevation(x: int, y: int): real
    reads {}
    ensures elevation(x, y) == A * (x as real) * w + B * (y as real) * w + C

  // Horn finite-difference operators (Horn, 1981)
  function horn_dzdx(i: int, j: int): real
    requires 1 <= i < N-1 && 1 <= j < M-1
    reads {}
    ensures horn_dzdx(i, j) ==
      (elevation(i+1, j-1) + 2.0 * elevation(i+1, j) + elevation(i+1, j+1)
       - elevation(i-1, j-1) - 2.0 * elevation(i-1, j) - elevation(i-1, j+1)) / (8.0 * w)

  function horn_dzdy(i: int, j: int): real
    requires 1 <= i < N-1 && 1 <= j < M-1
    reads {}
    ensures horn_dzdy(i, j) ==
      (elevation(i-1, j+1) + 2.0 * elevation(i, j+1) + elevation(i+1, j+1)
       - elevation(i-1, j-1) - 2.0 * elevation(i, j-1) - elevation(i+1, j-1)) / (8.0 * w)

  // Lemma: Horn operator recovers A exactly for interior points
  lemma horn_dzdx_exact(i: int, j: int)
    requires w_pos()
    requires 1 <= i < N-1 && 1 <= j < M-1
    ensures horn_dzdx(i, j) == A
  {
    // Expand elevation calls in horn_dzdx definition
    calc {
      horn_dzdx(i, j);
      == // Definition
      (elevation(i+1, j-1) + 2.0 * elevation(i+1, j) + elevation(i+1, j+1)
       - elevation(i-1, j-1) - 2.0 * elevation(i-1, j) - elevation(i-1, j+1)) / (8.0 * w);
      == // Expand each elevation term using plane formula
      ( (A * ((i+1) as real) * w + B * ((j-1) as real) * w + C)
        + 2.0 * (A * ((i+1) as real) * w + B * (j as real) * w + C)
        + (A * ((i+1) as real) * w + B * ((j+1) as real) * w + C)
        - (A * ((i-1) as real) * w + B * ((j-1) as real) * w + C)
        - 2.0 * (A * ((i-1) as real) * w + B * (j as real) * w + C)
        - (A * ((i-1) as real) * w + B * ((j+1) as real) * w + C) ) / (8.0 * w);
      == // Distribute and collect terms
      // A terms:
      // (i+1) appears in first three lines: coefficient 1 + 2 + 1 = 4
      // (i-1) appears in last three lines: coefficient -(1 + 2 + 1) = -4
      // Total A contribution: 4*A*(i+1)*w - 4*A*(i-1)*w = 4*A*w*((i+1)-(i-1)) = 4*A*w*2 = 8*A*w
      // B terms:
      // First line: B*(j-1)*w
      // Second: 2*B*j*w
      // Third: B*(j+1)*w
      // Fourth: -B*(j-1)*w
      // Fifth: -2*B*j*w
      // Sixth: -B*(j+1)*w
      // Sum = 0
      // C terms: C + 2C + C - C - 2C - C = 0
      (8.0 * A * w) / (8.0 * w);
      == // Cancel w (w > 0)
      A;
    }
  }

  // Lemma: Horn operator recovers B exactly for interior points
  lemma horn_dzdy_exact(i: int, j: int)
    requires w_pos()
    requires 1 <= i < N-1 && 1 <= j < M-1
    ensures horn_dzdy(i, j) == B
  {
    calc {
      horn_dzdy(i, j);
      == // Definition
      (elevation(i-1, j+1) + 2.0 * elevation(i, j+1) + elevation(i+1, j+1)
       - elevation(i-1, j-1) - 2.0 * elevation(i, j-1) - elevation(i+1, j-1)) / (8.0 * w);
      == // Expand each elevation term
      ( (A * ((i-1) as real) * w + B * ((j+1) as real) * w + C)
        + 2.0 * (A * (i as real) * w + B * ((j+1) as real) * w + C)
        + (A * ((i+1) as real) * w + B * ((j+1) as real) * w + C)
        - (A * ((i-1) as real) * w + B * ((j-1) as real) * w + C)
        - 2.0 * (A * (i as real) * w + B * ((j-1) as real) * w + C)
        - (A * ((i+1) as real) * w + B * ((j-1) as real) * w + C) ) / (8.0 * w);
      == // Collect terms
      // A terms:
      // First: A*(i-1)*w
      // Second: 2*A*i*w
      // Third: A*(i+1)*w
      // Fourth: -A*(i-1)*w
      // Fifth: -2*A*i*w
      // Sixth: -A*(i+1)*w
      // Sum = 0
      // B terms:
      // (j+1) appears in first three lines: coefficient 1 + 2 + 1 = 4
      // (j-1) appears in last three lines: coefficient -(1 + 2 + 1) = -4
      // Total B contribution: 4*B*(j+1)*w - 4*B*(j-1)*w = 4*B*w*((j+1)-(j-1)) = 4*B*w*2 = 8*B*w
      // C terms: C + 2C + C - C - 2C - C = 0
      (8.0 * B * w) / (8.0 * w);
      == // Cancel w
      B;
    }
  }

  // Main theorem: Horn finite-difference estimates recover A and B exactly
  // for all interior grid points.
  theorem horn_exact_on_plane()
    requires w_pos()
    requires N >= 3 && M >= 3  // Ensure interior exists
    ensures forall i, j :: 1 <= i < N-1 && 1 <= j < M-1 ==>
      horn_dzdx(i, j) == A && horn_dzdy(i, j) == B
  {
    forall i: int, j: int | 1 <= i < N-1 && 1 <= j < M-1
      ensures horn_dzdx(i, j) == A && horn_dzdy(i, j) == B
    {
      horn_dzdx_exact(i, j);
      horn_dzdy_exact(i, j);
    }
  }
}
