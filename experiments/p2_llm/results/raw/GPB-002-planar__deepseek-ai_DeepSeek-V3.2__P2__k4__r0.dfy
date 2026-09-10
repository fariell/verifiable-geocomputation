// Horn finite-difference gradient estimation on a planar surface
// Theorem: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w > 0, the Horn finite-difference estimates DzDx and DzDy
// recover A and B exactly.

method HornPlanarExactRecovery(A: real, B: real, C: real, w: real) 
  returns (DzDx: real, DzDy: real)
  requires w > 0.0
  ensures DzDx == A && DzDy == B
{
  // Define a planar surface function
  function z(x: real, y: real): real
  {
    A * x + B * y + C
  }

  // Horn finite-difference kernel weights for Dz/Dx (central x-difference)
  // Kernel:
  // [ -1  0  1 ]
  // [ -2  0  2 ]
  // [ -1  0  1 ]   * (1/(8*w))
  // Sum of weights = 0, linear combination recovers A exactly for plane.
  
  // Compute DzDx using Horn kernel
  DzDx := 
    (1.0/(8.0 * w)) * (
      -1.0 * z(-w, -w) + 0.0 * z(0.0, -w) + 1.0 * z(w, -w) +
      -2.0 * z(-w, 0.0) + 0.0 * z(0.0, 0.0) + 2.0 * z(w, 0.0) +
      -1.0 * z(-w, w) + 0.0 * z(0.0, w) + 1.0 * z(w, w)
    );

  // Horn finite-difference kernel for Dz/Dy (central y-difference)
  // Kernel:
  // [ -1 -2 -1 ]
  // [  0  0  0 ]
  // [  1  2  1 ]   * (1/(8*w))
  
  // Compute DzDy using Horn kernel
  DzDy := 
    (1.0/(8.0 * w)) * (
      -1.0 * z(-w, -w) + -2.0 * z(0.0, -w) + -1.0 * z(w, -w) +
       0.0 * z(-w, 0.0) +  0.0 * z(0.0, 0.0) +  0.0 * z(w, 0.0) +
       1.0 * z(-w, w)  +  2.0 * z(0.0, w)  +  1.0 * z(w, w)
    );

  // The verification relies on Dafny's real arithmetic to confirm
  // that after substituting z(x,y) = A*x + B*y + C and simplifying,
  // DzDx simplifies to A and DzDy simplifies to B.
  // This is an algebraic identity, not an asymptotic approximation.
}
