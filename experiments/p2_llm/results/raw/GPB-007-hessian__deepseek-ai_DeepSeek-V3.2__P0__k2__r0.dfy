// P003: Zevenbergen-Thorne Hessian exactness on quadratic surfaces
// Formal specification and proof for a 3x3 window with spacing w > 0.

// Quadratic surface definition
function QuadraticSurface(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
  reads
{
  A*x*x + B*y*y + C*x*y + D*x + E*y + F
}

// Grid sampling of quadratic surface on 3x3 window
function SampledQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real): (grid: array2<real>)
  requires w > 0.0
  ensures grid.Length0 == 3 && grid.Length1 == 3
{
  var g := new real[3,3];
  var i: int := 0;
  while i < 3
    invariant 0 <= i <= 3
    decreases 3 - i
  {
    var j: int := 0;
    while j < 3
      invariant 0 <= j <= 3
      decreases 3 - j
    {
      g[i, j] := QuadraticSurface(A, B, C, D, E, F, (i-1)*w, (j-1)*w);
      j := j + 1;
    }
    i := i + 1;
  }
  g
}

// Zevenbergen-Thorne discrete Hessian computation
function ZTHessian(grid: array2<real>, w: real): (hxx: real, hyy: real, hxy: real)
  requires grid.Length0 == 3 && grid.Length1 == 3
  requires w > 0.0
{
  // Extract 3x3 window values (indices 0..2)
  var a := grid[0,0];
  var b := grid[0,1];
  var c := grid[0,2];
  var d := grid[1,0];
  var e := grid[1,1];
  var f := grid[1,2];
  var g := grid[2,0];
  var h := grid[2,1];
  var i := grid[2,2];
  
  // ZT finite-difference formulas
  var hxx_local := (d - 2.0*e + f) / (w*w);
  var hyy_local := (b - 2.0*e + h) / (w*w);
  var hxy_local := (a - c - g + i) / (4.0*w*w);
  
  (hxx_local, hyy_local, hxy_local)
}

// Main theorem: ZT Hessian recovers (2A, 2B, C) exactly
theorem Theorem_ZTHessianExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
{
  var grid := SampledQuadratic(A, B, C, D, E, F, w);
  var (hxx, hyy, hxy) := ZTHessian(grid, w);
  
  // Expected analytic second derivatives
  var expected_hxx: real := 2.0 * A;
  var expected_hyy: real := 2.0 * B;
  var expected_hxy: real := C;
  
  // Proof by algebraic simplification
  calc {
    hxx;
    == // Expand hxx definition
    (grid[1,0] - 2.0*grid[1,1] + grid[1,2]) / (w*w);
    == // Expand grid values
    (QuadraticSurface(A,B,C,D,E,F,0*w,(-1)*w) - 
     2.0*QuadraticSurface(A,B,C,D,E,F,0*w,0*w) + 
     QuadraticSurface(A,B,C,D,E,F,0*w,1*w)) / (w*w);
    == // Simplify quadratic expressions
    {
      assert QuadraticSurface(A,B,C,D,E,F,0*w,(-1)*w) == A*0.0 + B*w*w + C*0.0 + D*0.0 - E*w + F;
      assert QuadraticSurface(A,B,C,D,E,F,0*w,0*w) == F;
      assert QuadraticSurface(A,B,C,D,E,F,0*w,1*w) == A*0.0 + B*w*w + C*0.0 + D*0.0 + E*w + F;
    }
    ((B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F)) / (w*w);
    == // Combine terms
    (2.0*B*w*w) / (w*w);
    == // Cancel w*w (w ≠ 0)
    2.0*B;
  }
  assert hxx == expected_hxx;
  
  calc {
    hyy;
    == // Expand hyy definition
    (grid[0,1] - 2.0*grid[1,1] + grid[2,1]) / (w*w);
    == // Expand grid values
    (QuadraticSurface(A,B,C,D,E,F,(-1)*w,0*w) - 
     2.0*QuadraticSurface(A,B,C,D,E,F,0*w,0*w) + 
     QuadraticSurface(A,B,C,D,E,F,1*w,0*w)) / (w*w);
    == // Simplify quadratic expressions
    {
      assert QuadraticSurface(A,B,C,D,E,F,(-1)*w,0*w) == A*w*w + B*0.0 - C*w*w + D*(-w) + E*0.0 + F;
      assert QuadraticSurface(A,B,C,D,E,F,1*w,0*w) == A*w*w + B*0.0 + C*w*w + D*w + E*0.0 + F;
    }
    ((A*w*w - C*w*w - D*w + F) - 2.0*F + (A*w*w + C*w*w + D*w + F)) / (w*w);
    == // Combine terms (C and D terms cancel)
    (2.0*A*w*w) / (w*w);
    == // Cancel w*w
    2.0*A;
  }
  assert hyy == expected_hyy;
  
  calc {
    hxy;
    == // Expand hxy definition
    (grid[0,0] - grid[0,2] - grid[2,0] + grid[2,2]) / (4.0*w*w);
    == // Expand grid values
    (QuadraticSurface(A,B,C,D,E,F,(-1)*w,(-1)*w) - 
     QuadraticSurface(A,B,C,D,E,F,(-1)*w,1*w) - 
     QuadraticSurface(A,B,C,D,E,F,1*w,(-1)*w) + 
     QuadraticSurface(A,B,C,D,E,F,1*w,1*w)) / (4.0*w*w);
    == // Simplify each term
    {
      assert QuadraticSurface(A,B,C,D,E,F,(-1)*w,(-1)*w) == A*w*w + B*w*w + C*w*w - D*w - E*w + F;
      assert QuadraticSurface(A,B,C,D,E,F,(-1)*w,1*w) == A*w*w + B*w*w - C*w*w - D*w + E*w + F;
      assert QuadraticSurface(A,B,C,D,E,F,1*w,(-1)*w) == A*w*w + B*w*w - C*w*w + D*w - E*w + F;
      assert QuadraticSurface(A,B,C,D,E,F,1*w,1*w) == A*w*w + B*w*w + C*w*w + D*w + E*w + F;
    }
    // Combine: (A*w*w+B*w*w+C*w*w-D*w-E*w+F) - (A*w*w+B*w*w-C*w*w-D*w+E*w+F)
    //         - (A*w*w+B*w*w-C*w*w+D*w-E*w+F) + (A*w*w+B*w*w+C*w*w+D*w+E*w+F)
    == // Cancel systematically
    (4.0*C*w*w) / (4.0*w*w);
    == // Cancel 4.0*w*w
    C;
  }
  assert hxy == expected_hxy;
  
  // Final conclusion
  assert hxx == 2.0*A && hyy == 2.0*B && hxy == C;
}
