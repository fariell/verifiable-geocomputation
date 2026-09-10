// Horn finite-difference gradient estimation on a planar surface
// Theorem: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w > 0, the Horn finite-difference estimates DzDx and DzDy
// recover A and B exactly.

method HornExactRecovery(A: real, B: real, C: real, w: real) 
  returns (DzDx: real, DzDy: real)
  requires w > 0.0
  ensures DzDx == A && DzDy == B
{
  // Define grid points around center (0,0)
  var z00 := A*(-w) + B*(-w) + C;  // (-w, -w)
  var z01 := A*(-w) + B*0.0 + C;   // (-w, 0)
  var z02 := A*(-w) + B*w + C;     // (-w, w)
  var z10 := A*0.0 + B*(-w) + C;   // (0, -w)
  var z11 := A*0.0 + B*0.0 + C;    // (0, 0)
  var z12 := A*0.0 + B*w + C;      // (0, w)
  var z20 := A*w + B*(-w) + C;     // (w, -w)
  var z21 := A*w + B*0.0 + C;      // (w, 0)
  var z22 := A*w + B*w + C;        // (w, w)

  // Horn finite-difference formulas (weighted central differences)
  // Dz/Dx ≈ [ (z20 - z00) + 2*(z21 - z01) + (z22 - z02) ] / (8*w)
  // Dz/Dy ≈ [ (z02 - z00) + 2*(z12 - z10) + (z22 - z20) ] / (8*w)
  
  var numDx := (z20 - z00) + 2.0*(z21 - z01) + (z22 - z02);
  var numDy := (z02 - z00) + 2.0*(z12 - z10) + (z22 - z20);
  
  DzDx := numDx / (8.0 * w);
  DzDy := numDy / (8.0 * w);
  
  // Verification that these equal A and B exactly
  // Expand all terms symbolically:
  // z20 - z00 = [A*w + B*(-w) + C] - [A*(-w) + B*(-w) + C] = A*w - A*(-w) = 2*A*w
  // z21 - z01 = [A*w + B*0 + C] - [A*(-w) + B*0 + C] = A*w - A*(-w) = 2*A*w
  // z22 - z02 = [A*w + B*w + C] - [A*(-w) + B*w + C] = A*w - A*(-w) = 2*A*w
  // Sum: 2*A*w + 2*(2*A*w) + 2*A*w = (2 + 4 + 2)*A*w = 8*A*w
  // Divide by 8*w: A
  
  // Similarly for Dy:
  // z02 - z00 = [A*(-w) + B*w + C] - [A*(-w) + B*(-w) + C] = B*w - B*(-w) = 2*B*w
  // z12 - z10 = [A*0 + B*w + C] - [A*0 + B*(-w) + C] = B*w - B*(-w) = 2*B*w
  // z22 - z20 = [A*w + B*w + C] - [A*w + B*(-w) + C] = B*w - B*(-w) = 2*B*w
  // Sum: 2*B*w + 2*(2*B*w) + 2*B*w = 8*B*w
  // Divide by 8*w: B
  
  // Dafny can verify these equalities automatically:
  assert numDx == 8.0 * A * w;
  assert numDy == 8.0 * B * w;
}
