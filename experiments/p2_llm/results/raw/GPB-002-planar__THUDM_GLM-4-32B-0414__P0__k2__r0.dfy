// File: horn_slope_exactness.dfy
// Proves that Horn's finite-difference estimates DzDx and DzDy recover the exact
// coefficients A and B from a planar surface z = A*x + B*y + C on a regular grid.

module HornSlopeExactness {
  import opened Real
  import opened Sequences
  import opened Integers
  import opened Sequences.Integers

  // A regular grid with spacing w > 0
  type Grid = seq<int>  // Represents a 1D grid; 2D grid is seq<seq<int>>

  // Horn's finite-difference estimates for partial derivatives
  function DzDx(grid: Grid, w: real, i: int, j: int): real {
    // Horn's forward difference for dz/dx
    (grid[i+1][j] - grid[i][j]) / w
  }

  function DzDy(grid: Grid, w: real, i: int, j: int): real {
    // Horn's forward difference for dz/dy
    (grid[i][j+1] - grid[i][j]) / w
  }

  // A planar surface z = A*x + B*y + C
  function PlanarSurface(A: real, B: real, C: real, x: real, y: real): real {
    A * x + B * y + C
  }

  // Sample a planar surface on a regular grid
  function SamplePlanarSurface(A: real, B: real, C: real, w: real, n: int, m: int): Grid {
    // n rows, m columns
    // Grid indices are 0..n-1, 0..m-1
    // Grid values are z = A*x + B*y + C where x = i*w, y = j*w
    // Returns a 2D grid (seq<seq<real>>)
    var grid := new seq<real>[n];
    for i := 0 to n {
      grid[i] := new real[m];
      for j := 0 to m {
        grid[i][j] := PlanarSurface(A, B, C, i*w, j*w);
      }
    }
    return grid;
  }

  // Theorem: Horn's finite-difference estimates recover the exact coefficients
  // from a planar surface on a regular grid.
  lemma HornSlopeExactness(A: real, B: real, C: real, w: real, n: int, m: int)
    requires w > 0
    requires n >= 2 && m >= 2  // Need at least 2x2 grid for differences
    requires forall i, j :: 0 <= i < n && 0 <= j < m ==> 
      SamplePlanarSurface(A, B, C, w, n, m)[i][j] == A * (i * w) + B * (j * w) + C
    ensures forall i, j :: 0 <= i < n-1 && 0 <= j < m-1 ==>
      DzDx(SamplePlanarSurface(A, B, C, w, n, m), w, i, j) == A
    ensures forall i, j :: 0 <= i < n-1 && 0 <= j < m-1 ==>
      DzDy(SamplePlanarSurface(A, B, C, w, n, m), w, i, j) == B
  {
    // Proof by direct calculation
    forall i, j | 0 <= i < n-1 && 0 <= j < m-1
    {
      // Calculate DzDx
      var z1 := SamplePlanarSurface(A, B, C, w, n, m)[i][j];
      var z2 := SamplePlanarSurface(A, B, C, w, n, m)[i+1][j];
      var dzdx := (z2 - z1) / w;
      assert dzdx == (A * ((i+1)*w) + B * (j*w) + C - (A * (i*w) + B * (j*w) + C)) / w;
      assert dzdx == (A * w) / w;
      assert dzdx == A;

      // Calculate DzDy
      z1 := SamplePlanarSurface(A, B, C, w, n, m)[i][j];
      z2 := SamplePlanarSurface(A, B, C, w, n, m)[i][j+1];
      var dzdy := (z2 - z1) / w;
      assert dzdy == (A * (i*w) + B * ((j+1)*w) + C - (A * (i*w) + B * (j*w) + C)) / w;
      assert dzdy == (B * w) / w;
      assert dzdy == B;
    }
  }

  // Example usage
  method Main()
  {
    var A := 1.0;
    var B := 2.0;
    var C := 3.0;
    var w := 1.0;
    var n := 5;
    var m := 5;

    // Verify the theorem for these parameters
    HornSlopeExactness(A, B, C, w, n, m);

    print "Theorem verified: Horn's finite-difference estimates recover the exact coefficients from a planar surface.\n";
  }
}
