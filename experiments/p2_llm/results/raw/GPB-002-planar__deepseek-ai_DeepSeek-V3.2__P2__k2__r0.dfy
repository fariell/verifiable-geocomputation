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

  // Horn finite-difference kernel weights for gradient in x-direction
  // Kernel applied to 3x3 neighborhood centered at (x0, y0):
  //   [ -1  0  1 ]
  //   [ -2  0  2 ] * (1/(8*w))
  //   [ -1  0  1 ]
  // Similarly for y-direction (transposed).

  // Compute contributions from the 3x3 grid around (0,0) for simplicity.
  // Grid coordinates: x = i*w, y = j*w for i,j in {-1,0,1}
  var sum_x := 0.0;
  var sum_y := 0.0;

  // Iterate over the 3x3 neighborhood
  var i := -1;
  while i <= 1
    invariant -2 <= i <= 2
    decreases if i <= 1 then 1 - i else 0
  {
    var j := -1;
    while j <= 1
      invariant -2 <= j <= 2
      decreases if j <= 1 then 1 - j else 0
    {
      var weight_x: real;
      var weight_y: real;
      // Assign Horn kernel weights
      if i == -1 && j == -1 { weight_x := -1.0; weight_y := -1.0; }
      else if i == -1 && j == 0 { weight_x := -2.0; weight_y := 0.0; }
      else if i == -1 && j == 1 { weight_x := -1.0; weight_y := 1.0; }
      else if i == 0 && j == -1 { weight_x := 0.0; weight_y := -2.0; }
      else if i == 0 && j == 0 { weight_x := 0.0; weight_y := 0.0; }
      else if i == 0 && j == 1 { weight_x := 0.0; weight_y := 2.0; }
      else if i == 1 && j == -1 { weight_x := 1.0; weight_y := -1.0; }
      else if i == 1 && j == 0 { weight_x := 2.0; weight_y := 0.0; }
      else { weight_x := 1.0; weight_y := 1.0; } // i == 1 && j == 1

      var x_val := i as real * w;
      var y_val := j as real * w;
      var z_val := z(x_val, y_val);
      sum_x := sum_x + weight_x * z_val;
      sum_y := sum_y + weight_y * z_val;
      j := j + 1;
    }
    i := i + 1;
  }

  // Normalize by (8 * w) for both directions
  DzDx := sum_x / (8.0 * w);
  DzDy := sum_y / (8.0 * w);

  // The proof that DzDx == A and DzDy == B follows from linearity:
  // sum_x = Σ_{i,j} weight_x(i,j) * (A*(i*w) + B*(j*w) + C)
  // = A*w * Σ_{i,j} weight_x(i,j)*i  + B*w * Σ_{i,j} weight_x(i,j)*j + C * Σ_{i,j} weight_x(i,j)
  // The Horn kernel satisfies:
  //   Σ weight_x(i,j) = 0
  //   Σ weight_x(i,j)*j = 0
  //   Σ weight_x(i,j)*i = 8
  // Therefore sum_x = A*w * 8, so DzDx = (A*w*8)/(8*w) = A.
  // Similarly for y-direction.
  // We can assert these sums as lemmas or compute them explicitly.
  // Here we compute them to satisfy the verifier.

  var sum_weight_x := 0.0;
  var sum_weight_x_i := 0.0;
  var sum_weight_x_j := 0.0;
  var sum_weight_y := 0.0;
  var sum_weight_y_i := 0.0;
  var sum_weight_y_j := 0.0;

  i := -1;
  while i <= 1
    invariant -2 <= i <= 2
    decreases if i <= 1 then 1 - i else 0
  {
    j := -1;
    while j <= 1
      invariant -2 <= j <= 2
      decreases if j <= 1 then 1 - j else 0
    {
      var weight_x: real;
      var weight_y: real;
      if i == -1 && j == -1 { weight_x := -1.0; weight_y := -1.0; }
      else if i == -1 && j == 0 { weight_x := -2.0; weight_y := 0.0; }
      else if i == -1 && j == 1 { weight_x := -1.0; weight_y := 1.0; }
      else if i == 0 && j == -1 { weight_x := 0.0; weight_y := -2.0; }
      else if i == 0 && j == 0 { weight_x := 0.0; weight_y := 0.0; }
      else if i == 0 && j == 1 { weight_x := 0.0; weight_y := 2.0; }
      else if i == 1 && j == -1 { weight_x := 1.0; weight_y := -1.0; }
      else if i == 1 && j == 0 { weight_x := 2.0; weight_y := 0.0; }
      else { weight_x := 1.0; weight_y := 1.0; }

      sum_weight_x := sum_weight_x + weight_x;
      sum_weight_x_i := sum_weight_x_i + weight_x * (i as real);
      sum_weight_x_j := sum_weight_x_j + weight_x * (j as real);
      sum_weight_y := sum_weight_y + weight_y;
      sum_weight_y_i := sum_weight_y_i + weight_y * (i as real);
      sum_weight_y_j := sum_weight_y_j + weight_y * (j as real);
      j := j + 1;
    }
    i := i + 1;
  }

  // Assert kernel properties
  assert sum_weight_x == 0.0;
  assert sum_weight_x_j == 0.0;
  assert sum_weight_x_i == 8.0;
  assert sum_weight_y == 0.0;
  assert sum_weight_y_i == 0.0;
  assert sum_weight_y_j == 8.0;

  // Now show that DzDx == A and DzDy == B
  assert sum_x == A * w * sum_weight_x_i + B * w * sum_weight_x_j + C * sum_weight_x;
  assert sum_y == A * w * sum_weight_y_i + B * w * sum_weight_y_j + C * sum_weight_y;
  // Therefore:
  assert DzDx == (A * w * 8.0) / (8.0 * w);
  assert DzDy == (B * w * 8.0) / (8.0 * w);
  // Simplify:
  assert DzDx == A && DzDy == B;
}
