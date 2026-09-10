// Horn finite-difference slope estimator exactness on planar surfaces
// Formalization of GPB-019 algebraic half (P-001)

module HornExactness {
  // Grid dimensions
  ghost const N: int
  ghost const M: int
  assume N >= 3 && M >= 3  // Need interior points for finite differences

  // Grid spacing
  ghost const w: real
  assume w > 0.0

  // Plane parameters
  ghost const A: real
  ghost const B: real
  ghost const C: real

  // Elevation function for plane z = A*x + B*y + C
  function elevation(i: int, j: int): real
    requires 0 <= i < N && 0 <= j < M
  {
    A * (w * i as real) + B * (w * j as real) + C
  }

  // Horn finite-difference operators (1981)
  function hornDzDx(i: int, j: int): real
    requires 1 <= i < N-1 && 1 <= j < M-1  // Interior points
  {
    // Central difference in x-direction, using 3x3 neighborhood
    ((elevation(i+1, j-1) + 2.0 * elevation(i+1, j) + elevation(i+1, j+1)) -
     (elevation(i-1, j-1) + 2.0 * elevation(i-1, j) + elevation(i-1, j+1))) / (8.0 * w)
  }

  function hornDzDy(i: int, j: int): real
    requires 1 <= i < N-1 && 1 <= j < M-1
  {
    // Central difference in y-direction, using 3x3 neighborhood
    ((elevation(i-1, j+1) + 2.0 * elevation(i, j+1) + elevation(i+1, j+1)) -
     (elevation(i-1, j-1) + 2.0 * elevation(i, j-1) + elevation(i+1, j-1))) / (8.0 * w)
  }

  // Lemma: Horn operators recover exact plane coefficients
  lemma HornExactOnPlane()
    ensures forall i, j :: 
      1 <= i < N-1 && 1 <= j < M-1 ==> 
        hornDzDx(i, j) == A && hornDzDy(i, j) == B
  {
    // Expand elevation function for all points in the 3x3 neighborhood
    forall i, j | 1 <= i < N-1 && 1 <= j < M-1
      ensures hornDzDx(i, j) == A && hornDzDy(i, j) == B
    {
      // Helper to compute elevation at any grid point
      calc {
        // Compute numerator for DzDx
        (elevation(i+1, j-1) + 2.0 * elevation(i+1, j) + elevation(i+1, j+1)) -
        (elevation(i-1, j-1) + 2.0 * elevation(i-1, j) + elevation(i-1, j+1));
        ==
        // Expand using elevation = A*(w*i) + B*(w*j) + C
        (A*w*(i+1) + B*w*(j-1) + C + 2.0*(A*w*(i+1) + B*w*j + C) + A*w*(i+1) + B*w*(j+1) + C) -
        (A*w*(i-1) + B*w*(j-1) + C + 2.0*(A*w*(i-1) + B*w*j + C) + A*w*(i-1) + B*w*(j+1) + C);
        ==
        // Simplify algebraically
        { 
          // Combine terms with A
          var A_terms: real := 
            A*w*( (i+1) + 2*(i+1) + (i+1) - ((i-1) + 2*(i-1) + (i-1)) );
          // Combine terms with B  
          var B_terms: real :=
            B*w*( (j-1) + 2*j + (j+1) - ((j-1) + 2*j + (j+1)) );
          // Constant terms cancel completely
          var const_terms: real := C + 2*C + C - (C + 2*C + C);
          
          assert A_terms == 8.0 * A * w;
          assert B_terms == 0.0;
          assert const_terms == 0.0;
        }
        8.0 * A * w;
      }
      // Therefore hornDzDx = (8.0 * A * w) / (8.0 * w) = A
      assert hornDzDx(i, j) == A;

      // Similar calculation for DzDy
      calc {
        // Compute numerator for DzDy
        (elevation(i-1, j+1) + 2.0 * elevation(i, j+1) + elevation(i+1, j+1)) -
        (elevation(i-1, j-1) + 2.0 * elevation(i, j-1) + elevation(i+1, j-1));
        ==
        // Expand using elevation formula
        (A*w*(i-1) + B*w*(j+1) + C + 2.0*(A*w*i + B*w*(j+1) + C) + A*w*(i+1) + B*w*(j+1) + C) -
        (A*w*(i-1) + B*w*(j-1) + C + 2.0*(A*w*i + B*w*(j-1) + C) + A*w*(i+1) + B*w*(j-1) + C);
        ==
        // Simplify algebraically
        {
          // Combine terms with A
          var A_terms: real :=
            A*w*( (i-1) + 2*i + (i+1) - ((i-1) + 2*i + (i+1)) );
          // Combine terms with B
          var B_terms: real :=
            B*w*( (j+1) + 2*(j+1) + (j+1) - ((j-1) + 2*(j-1) + (j-1)) );
          // Constant terms cancel
          var const_terms: real := C + 2*C + C - (C + 2*C + C);
          
          assert A_terms == 0.0;
          assert B_terms == 8.0 * B * w;
          assert const_terms == 0.0;
        }
        8.0 * B * w;
      }
      // Therefore hornDzDy = (8.0 * B * w) / (8.0 * w) = B
      assert hornDzDy(i, j) == B;
    }
  }

  // Main theorem: Horn finite-difference estimates recover A and B exactly
  // for all interior points of a planar surface on a regular grid
  theorem HornExactnessTheorem()
    requires N >= 3 && M >= 3
    requires w > 0.0
    ensures forall i, j :: 
      1 <= i < N-1 && 1 <= j < M-1 ==> 
        hornDzDx(i, j) == A && hornDzDy(i, j) == B
  {
    HornExactOnPlane();
  }
}
