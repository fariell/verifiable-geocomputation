// Horn finite-difference slope operator exactness on a plane
// Formalization of: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w>0, the Horn finite-difference estimates DzDx and DzDy recover A and B exactly.

module HornPlaneExactness {
  // Grid dimensions
  ghost const N: int := 3  // minimal size for Horn operator (3x3 window)
  ghost const M: int := 3

  // Plane parameters
  ghost const A: real
  ghost const B: real
  ghost const C: real

  // Grid spacing
  ghost const w: real
  ghost predicate wPositive() { w > 0.0 }

  // Grid coordinates: center cell is at (1,1) in a 0-based 3x3 window
  function xCoord(i: int): real
    requires 0 <= i < N
  {
    (i - 1) as real * w
  }

  function yCoord(j: int): real
    requires 0 <= j < M
  {
    (j - 1) as real * w
  }

  // Elevation on the plane
  function z(i: int, j: int): real
    requires 0 <= i < N && 0 <= j < M
  {
    A * xCoord(i) + B * yCoord(j) + C
  }

  // Horn (1981) finite-difference slope operators
  // For a 3x3 window centered at (i,j) = (1,1)
  function hornDzDx(): real
    requires wPositive()
  {
    // Coefficients from Horn (1981), Table 1, "slope: first derivative"
    // ∂z/∂x ≈ (z(i+1,j-1) + 2*z(i+1,j) + z(i+1,j+1) - z(i-1,j-1) - 2*z(i-1,j) - z(i-1,j+1)) / (8*w)
    (z(2,0) + 2.0*z(2,1) + z(2,2) - z(0,0) - 2.0*z(0,1) - z(0,2)) / (8.0 * w)
  }

  function hornDzDy(): real
    requires wPositive()
  {
    // ∂z/∂y ≈ (z(i-1,j+1) + 2*z(i,j+1) + z(i+1,j+1) - z(i-1,j-1) - 2*z(i,j-1) - z(i+1,j-1)) / (8*w)
    (z(0,2) + 2.0*z(1,2) + z(2,2) - z(0,0) - 2.0*z(1,0) - z(2,0)) / (8.0 * w)
  }

  // Lemma: Horn operators exactly recover A and B on a plane
  lemma hornExactOnPlane()
    requires wPositive()
    ensures hornDzDx() == A
    ensures hornDzDy() == B
  {
    // Expand z(i,j) = A*xCoord(i) + B*yCoord(j) + C
    // For DzDx numerator:
    // z(2,0) = A*xCoord(2) + B*yCoord(0) + C = A*w + B*(-w) + C = A*w - B*w + C
    // z(2,1) = A*xCoord(2) + B*yCoord(1) + C = A*w + B*0 + C = A*w + C
    // z(2,2) = A*xCoord(2) + B*yCoord(2) + C = A*w + B*w + C = A*w + B*w + C
    // z(0,0) = A*xCoord(0) + B*yCoord(0) + C = A*(-w) + B*(-w) + C = -A*w - B*w + C
    // z(0,1) = A*xCoord(0) + B*yCoord(1) + C = A*(-w) + B*0 + C = -A*w + C
    // z(0,2) = A*xCoord(0) + B*yCoord(2) + C = A*(-w) + B*w + C = -A*w + B*w + C

    // Compute numerator for DzDx:
    // numDx = (A*w - B*w + C) + 2*(A*w + C) + (A*w + B*w + C)
    //        - [(-A*w - B*w + C) + 2*(-A*w + C) + (-A*w + B*w + C)]
    // Group A terms:
    //   positive side: A*w + 2*A*w + A*w = 4*A*w
    //   negative side: -(-A*w - 2*A*w - A*w) = -(-4*A*w) = 4*A*w
    //   total A: 4*A*w + 4*A*w = 8*A*w
    // Group B terms:
    //   positive side: -B*w + B*w = 0
    //   negative side: -(-B*w + B*w) = -0 = 0
    //   total B: 0
    // Group C terms:
    //   positive side: C + 2*C + C = 4*C
    //   negative side: -(C + 2*C + C) = -4*C
    //   total C: 4*C - 4*C = 0
    // So numDx = 8*A*w
    // Then hornDzDx() = (8*A*w) / (8*w) = A

    // Similarly for DzDy numerator:
    // z(0,2) = -A*w + B*w + C
    // z(1,2) = A*0 + B*w + C = B*w + C
    // z(2,2) = A*w + B*w + C
    // z(0,0) = -A*w - B*w + C
    // z(1,0) = A*0 - B*w + C = -B*w + C
    // z(2,0) = A*w - B*w + C
    // numDy = (-A*w + B*w + C) + 2*(B*w + C) + (A*w + B*w + C)
    //        - [(-A*w - B*w + C) + 2*(-B*w + C) + (A*w - B*w + C)]
    // Group A terms:
    //   positive side: -A*w + A*w = 0
    //   negative side: -(-A*w + A*w) = -0 = 0
    // Group B terms:
    //   positive side: B*w + 2*B*w + B*w = 4*B*w
    //   negative side: -(-B*w - 2*B*w - B*w) = -(-4*B*w) = 4*B*w
    //   total B: 4*B*w + 4*B*w = 8*B*w
    // Group C terms:
    //   positive side: C + 2*C + C = 4*C
    //   negative side: -(C + 2*C + C) = -4*C
    //   total C: 0
    // So numDy = 8*B*w
    // Then hornDzDy() = (8*B*w) / (8*w) = B

    // The above reasoning is encoded as a calculation:
    calc {
      hornDzDx();
      ==
      (z(2,0) + 2.0*z(2,1) + z(2,2) - z(0,0) - 2.0*z(0,1) - z(0,2)) / (8.0 * w);
      ==
      ( (A*w + B*(-w) + C) + 2.0*(A*w + B*0 + C) + (A*w + B*w + C)
        - ((A*(-w) + B*(-w) + C) + 2.0*(A*(-w) + B*0 + C) + (A*(-w) + B*w + C))
      ) / (8.0 * w);
      ==
      ( (A*w - B*w + C) + 2.0*(A*w + C) + (A*w + B*w + C)
        - ((-A*w - B*w + C) + 2.0*(-A*w + C) + (-A*w + B*w + C))
      ) / (8.0 * w);
      ==
      ( (4.0*A*w + 4.0*C) - (-4.0*A*w + 4.0*C) ) / (8.0 * w);
      ==
      (8.0 * A * w) / (8.0 * w);
      ==
      A;
    }
    calc {
      hornDzDy();
      ==
      (z(0,2) + 2.0*z(1,2) + z(2,2) - z(0,0) - 2.0*z(1,0) - z(2,0)) / (8.0 * w);
      ==
      ( (A*(-w) + B*w + C) + 2.0*(A*0 + B*w + C) + (A*w + B*w + C)
        - ((A*(-w) + B*(-w) + C) + 2.0*(A*0 + B*(-w) + C) + (A*w + B*(-w) + C))
      ) / (8.0 * w);
      ==
      ( (-A*w + B*w + C) + 2.0*(B*w + C) + (A*w + B*w + C)
        - ((-A*w - B*w + C) + 2.0*(-B*w + C) + (A*w - B*w + C))
      ) / (8.0 * w);
      ==
      ( (4.0*B*w + 4.0*C) - (-4.0*B*w + 4.0*C) ) / (8.0 * w);
      ==
      (8.0 * B * w) / (8.0 * w);
      ==
      B;
    }
  }
}
