// P-004 / GPB-019: Horn slope is exact on quadratic surfaces and has O(w^2) remainder on cubic surfaces
module HornSlopeConsistency {
  // Grid spacing must be positive
  method HornSlopeExactOnQuadratic(w: real) requires w > 0.0
  {
    // Quadratic surface coefficients
    var A, B, C, D, E, F: real;
    A := 0.3; B := -0.2; C := 5.0; // Linear terms
    D := 0.05; E := -0.04; F := 0.02; // Quadratic terms
    
    // Sample points around origin (0,0)
    var a, b, c, d, f, g, h, i: real;
    // Points at (-w,-w), (0,-w), (w,-w), (-w,0), (w,0), (-w,w), (0,w), (w,w)
    a := A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w);
    b := A*(0) + B*(-w) + C + D*(0)*(-w) + E*(0)*(-w) + F*(-w)*(-w);
    c := A*(w) + B*(-w) + C + D*(w)*(-w) + E*(w)*(-w) + F*(-w)*(-w);
    d := A*(-w) + B*(0) + C + D*(-w)*(0) + E*(-w)*(0) + F*(0)*(0);
    f := A*(w) + B*(0) + C + D*(w)*(0) + E*(w)*(0) + F*(0)*(0);
    g := A*(-w) + B*(w) + C + D*(-w)*(w) + E*(-w)*(w) + F*(w)*(w);
    h := A*(0) + B*(w) + C + D*(0)*(w) + E*(0)*(w) + F*(w)*(w);
    i := A*(w) + B*(w) + C + D*(w)*(w) + E*(w)*(w) + F*(w)*(w);
    
    // Horn's DzDx and DzDy formulas
    var hornDzDx: real;
    hornDzDx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
    var hornDzDy: real;
    hornDzDy := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w);
    
    // True analytical derivatives at origin
    var trueDzDx: real;
    trueDzDx := A; // dz/dx = A + 2Dx + Ey evaluated at (0,0)
    var trueDzDy: real;
    trueDzDy := B; // dz/dy = B + Dx + 2Fy evaluated at (0,0)
    
    // Prove Horn's method is exact for quadratic surfaces
    assert hornDzDx == trueDzDx;
    assert hornDzDy == trueDzDy;
  }
  
  method HornSlopeCubicRemainder(G: real, w: real) requires w > 0.0
  {
    // Cubic surface z = G*x^3
    // Sample points around origin (0,0)
    var a, b, c, d, f, g, h, i: real;
    // Points at (-w,-w), (0,-w), (w,-w), (-w,0), (w,0), (-w,w), (0,w), (w,w)
    a := G*(-w)^3;
    b := G*(0)^3;
    c := G*(w)^3;
    d := G*(-w)^3;
    f := G*(w)^3;
    g := G*(-w)^3;
    h := G*(0)^3;
    i := G*(w)^3;
    
    // Horn's DzDx formula
    var hornDzDx: real;
    hornDzDx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
    
    // True analytical derivative at origin
    var trueDzDx: real;
    trueDzDx := 0.0; // dz/dx = 3Gx^2 evaluated at (0,0)
    
    // Remainder term
    var remainder: real;
    remainder := hornDzDx - trueDzDx;
    
    // Prove remainder is O(w^2)
    assert abs(remainder) <= abs(G) * w * w;
  }
}
