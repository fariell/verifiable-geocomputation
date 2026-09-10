method HornSlopeConsistencyOnPlane(A: real, B: real, C: real, w: real) returns (DzDx: real, DzDy: real)
  requires w > 0
  ensures DzDx == A
  ensures DzDy == B
{
  // Define the planar surface function
  function z(x: real, y: real): real {
    A * x + B * y + C
  }

  // Define the Horn finite-difference estimates for the slopes
  function HornDzDx(x: real, y: real, w: real): real {
    (z(x + w, y) - z(x - w, y)) / (2 * w)
  }

  function HornDzDy(x: real, y: real, w: real): real {
    (z(x, y + w) - z(x, y - w)) / (2 * w)
  }

  // Choose a point (x0, y0) on the grid
  var x0: real := 0.0;
  var y0: real := 0.0;

  // Compute the Horn finite-difference estimates at (x0, y0)
  DzDx := HornDzDx(x0, y0, w);
  DzDy := HornDzDy(x0, y0, w);

  // Prove that the estimates are exactly A and B
  assert DzDx == A;
  assert DzDy == B;
}

// Proof of the Horn finite-difference estimates recovering A and B exactly
lemma HornSlopeConsistencyProof(A: real, B: real, C: real, w: real)
  requires w > 0
{
  // Define the planar surface function
  function z(x: real, y: real): real {
    A * x + B * y + C
  }

  // Define the Horn finite-difference estimates for the slopes
  function HornDzDx(x: real, y: real, w: real): real {
    (z(x + w, y) - z(x - w, y)) / (2 * w)
  }

  function HornDzDy(x: real, y: real, w: real): real {
    (z(x, y + w) - z(x, y - w)) / (2 * w)
  }

  // Choose a point (x0, y0) on the grid
  var x0: real := 0.0;
  var y0: real := 0.0;

  // Compute the Horn finite-difference estimates at (x0, y0)
  var DzDx: real := HornDzDx(x0, y0, w);
  var DzDy: real := HornDzDy(x0, y0, w);

  // Prove that the estimates are exactly A and B
  assert DzDx == A;
  assert DzDy == B;
}

// Main method to test the consistency
method TestHornSlopeConsistency()
{
  var A: real := 1.0;
  var B: real := 2.0;
  var C: real := 3.0;
  var w: real := 1.0;

  var DzDx: real;
  var DzDy: real;

  HornSlopeConsistencyOnPlane(A, B, C, w, DzDx, DzDy);

  assert DzDx == A;
  assert DzDy == B;
}
