// Horn slope exactness on quadratic surfaces
// DzDx and DzDy recover true planar gradient coefficients (A,B) identically
// On z = G x^3, DzDx remainder at origin equals G w^2 (order O(w^2))

method QuadraticExactness(A: real, B: real, C: real, w: real) 
  returns (DzDx: real, DzDy: real)
  requires w != 0.0
  ensures DzDx == A && DzDy == B
{
  // Quadratic surface: z = A*x + B*y + C
  // Horn's finite difference approximations:
  // DzDx = (z(x+w,y) - z(x-w,y)) / (2w)
  // DzDy = (z(x,y+w) - z(x,y-w)) / (2w)
  
  // Evaluate at origin (x=0, y=0)
  var z00 := A*0.0 + B*0.0 + C;
  var zpw0 := A*w + B*0.0 + C;
  var zmw0 := A*(-w) + B*0.0 + C;
  var z0pw := A*0.0 + B*w + C;
  var z0mw := A*0.0 + B*(-w) + C;
  
  DzDx := (zpw0 - zmw0) / (2.0 * w);
  DzDy := (z0pw - z0mw) / (2.0 * w);
  
  // Simplify algebraically
  // DzDx = (A*w + C - (-A*w + C)) / (2w) = (2A*w) / (2w) = A
  // DzDy = (B*w + C - (-B*w + C)) / (2w) = (2B*w) / (2w) = B
}

method CubicRemainder(G: real, w: real) 
  returns (remainder: real)
  requires w != 0.0
  ensures remainder == G * w * w
{
  // Cubic surface: z = G * x^3
  // Horn's DzDx at origin:
  // DzDx = (z(w,0) - z(-w,0)) / (2w)
  
  var zpw := G * w * w * w;
  var zmw := G * (-w) * (-w) * (-w);
  // zmw = G * (-w)^3 = G * (-w^3) = -G * w^3
  
  var DzDx := (zpw - zmw) / (2.0 * w);
  // DzDx = (G*w^3 - (-G*w^3)) / (2w) = (2G*w^3) / (2w) = G*w^2
  
  // True derivative at origin: dz/dx = 3G*x^2 = 0 at x=0
  // Remainder = DzDx - true_derivative = G*w^2 - 0 = G*w^2
  remainder := DzDx;
}
