// Formalization of Zevenbergen-Thorne Hessian exactness on quadratic surfaces
// Quadratic surface: z = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// Sampled on 3x3 window with spacing w > 0
// ZT Hessian recovers (2A, 2B, C) exactly

// Grid indexing: center cell is (0,0), neighbors at offsets ±w
// We'll define the 3x3 window coordinates relative to center

// First, define the quadratic surface function
function quadratic(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
  reads
{
  A*x*x + B*y*y + C*x*y + D*x + E*y + F
}

// Zevenbergen-Thorne discrete Hessian formulas
// For a 3x3 grid with spacing w, centered at (0,0)
// Indices: (-1,-1) (0,-1) (1,-1)
//          (-1, 0) (0, 0) (1, 0)
//          (-1, 1) (0, 1) (1, 1)

// Function to compute ZT Hessian from 9 sampled values
function ZTHessian(
  z_m1_m1: real, z_0_m1: real, z_1_m1: real,
  z_m1_0: real,  z_0_0: real,  z_1_0: real,
  z_m1_1: real,  z_0_1: real,  z_1_1: real,
  w: real
): (hxx: real, hyy: real, hxy: real)
  requires w > 0.0
{
  // Second derivatives using central differences
  var hxx := (z_m1_0 - 2.0*z_0_0 + z_1_0) / (w*w);
  var hyy := (z_0_m1 - 2.0*z_0_0 + z_0_1) / (w*w);
  var hxy := (z_m1_m1 - z_1_m1 - z_m1_1 + z_1_1) / (4.0*w*w);
  (hxx, hyy, hxy)
}

// Main theorem: For any quadratic surface and any w > 0,
// the ZT Hessian recovers exactly (2A, 2B, C)
theorem ZTHessianExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
  ensures 
    var (hxx, hyy, hxy) := ZTHessian(
      quadratic(A, B, C, D, E, F, -w, -w),
      quadratic(A, B, C, D, E, F, 0.0, -w),
      quadratic(A, B, C, D, E, F, w, -w),
      quadratic(A, B, C, D, E, F, -w, 0.0),
      quadratic(A, B, C, D, E, F, 0.0, 0.0),
      quadratic(A, B, C, D, E, F, w, 0.0),
      quadratic(A, B, C, D, E, F, -w, w),
      quadratic(A, B, C, D, E, F, 0.0, w),
      quadratic(A, B, C, D, E, F, w, w),
      w
    );
    hxx == 2.0*A && hyy == 2.0*B && hxy == C
{
  // Expand all 9 sampled values
  var z_m1_m1 := quadratic(A, B, C, D, E, F, -w, -w);
  var z_0_m1 := quadratic(A, B, C, D, E, F, 0.0, -w);
  var z_1_m1 := quadratic(A, B, C, D, E, F, w, -w);
  var z_m1_0 := quadratic(A, B, C, D, E, F, -w, 0.0);
  var z_0_0 := quadratic(A, B, C, D, E, F, 0.0, 0.0);
  var z_1_0 := quadratic(A, B, C, D, E, F, w, 0.0);
  var z_m1_1 := quadratic(A, B, C, D, E, F, -w, w);
  var z_0_1 := quadratic(A, B, C, D, E, F, 0.0, w);
  var z_1_1 := quadratic(A, B, C, D, E, F, w, w);
  
  // Compute ZT Hessian
  var hxx := (z_m1_0 - 2.0*z_0_0 + z_1_0) / (w*w);
  var hyy := (z_0_m1 - 2.0*z_0_0 + z_0_1) / (w*w);
  var hxy := (z_m1_m1 - z_1_m1 - z_m1_1 + z_1_1) / (4.0*w*w);
  
  // Now prove each component equals the analytic value
  
  // Proof for hxx = 2A
  calc {
    z_m1_0 - 2.0*z_0_0 + z_1_0;
    == // Expand z_m1_0
    (A*(-w)*(-w) + B*0.0*0.0 + C*(-w)*0.0 + D*(-w) + E*0.0 + F) 
    - 2.0*(A*0.0*0.0 + B*0.0*0.0 + C*0.0*0.0 + D*0.0 + E*0.0 + F)
    + (A*w*w + B*0.0*0.0 + C*w*0.0 + D*w + E*0.0 + F);
    == // Simplify
    (A*w*w - D*w + F) - 2.0*F + (A*w*w + D*w + F);
    == // Combine terms
    2.0*A*w*w;
  }
  assert hxx == 2.0*A*w*w / (w*w) by {
    // Since w > 0, division is well-defined
  }
  assert hxx == 2.0*A;
  
  // Proof for hyy = 2B
  calc {
    z_0_m1 - 2.0*z_0_0 + z_0_1;
    == // Expand z_0_m1
    (A*0.0*0.0 + B*(-w)*(-w) + C*0.0*(-w) + D*0.0 + E*(-w) + F)
    - 2.0*(A*0.0*0.0 + B*0.0*0.0 + C*0.0*0.0 + D*0.0 + E*0.0 + F)
    + (A*0.0*0.0 + B*w*w + C*0.0*w + D*0.0 + E*w + F);
    == // Simplify
    (B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F);
    == // Combine terms
    2.0*B*w*w;
  }
  assert hyy == 2.0*B*w*w / (w*w);
  assert hyy == 2.0*B;
  
  // Proof for hxy = C
  calc {
    z_m1_m1 - z_1_m1 - z_m1_1 + z_1_1;
    == // Expand z_m1_m1
    (A*(-w)*(-w) + B*(-w)*(-w) + C*(-w)*(-w) + D*(-w) + E*(-w) + F)
    - // Subtract z_1_m1
    (A*w*w + B*(-w)*(-w) + C*w*(-w) + D*w + E*(-w) + F)
    - // Subtract z_m1_1
    (A*(-w)*(-w) + B*w*w + C*(-w)*w + D*(-w) + E*w + F)
    + // Add z_1_1
    (A*w*w + B*w*w + C*w*w + D*w + E*w + F);
    == // Expand and group by term type
    
    // A terms: A*w² - A*w² - A*w² + A*w² = 0
    // B terms: B*w² - B*w² - B*w² + B*w² = 0
    // C terms: C*w² - (-C*w²) - (-C*w²) + C*w² = 4C*w²
    // D terms: -D*w - D*w + D*w + D*w = 0
    // E terms: -E*w + E*w - E*w + E*w = 0
    // F terms: F - F - F + F = 0
    
    // Let's compute systematically:
    var A_terms := A*w*w - A*w*w - A*w*w + A*w*w;
    var B_terms := B*w*w - B*w*w - B*w*w + B*w*w;
    var C_terms := C*w*w - (C*w*(-w)) - (C*(-w)*w) + C*w*w;
    var D_terms := -D*w - D*w + D*w + D*w;
    var E_terms := -E*w + E*w - E*w + E*w;
    var F_terms := F - F - F + F;
    
    // Simplify C_terms:
    // C*w*(-w) = -C*w²
    // C*(-w)*w = -C*w²
    // So: C*w² - (-C*w²) - (-C*w²) + C*w² = C*w² + C*w² + C*w² + C*w² = 4C*w²
    C_terms := 4.0*C*w*w;
    
    A_terms + B_terms + C_terms + D_terms + E_terms + F_terms;
    ==
    4.0*C*w*w;
  }
  assert hxy == 4.0*C*w*w / (4.0*w*w);
  assert hxy == C;
}
