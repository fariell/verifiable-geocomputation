method HornSlopeConsistencyOnPlane(A: real, B: real, C: real, w: real) returns (DzDx: real, DzDy: real)
  requires w > 0
  ensures DzDx == A
  ensures DzDy == B
{
  // Define the planar surface function
  function z(x: real, y: real): real {
    A * x + B * y + C
  }

  // Define the Horn finite-difference estimates
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

  // Prove that the Horn estimates recover A and B exactly
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

  // Define the Horn finite-difference estimates
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

  // Prove that the Horn estimates recover A and B exactly
  assert DzDx == A;
  assert DzDy == B;

  // Proof for DzDx
  assert HornDzDx(x0, y0, w) == (z(x0 + w, y0) - z(x0 - w, y0)) / (2 * w);
  assert (z(x0 + w, y0) - z(x0 - w, y0)) / (2 * w) == (A * (x0 + w) + B * y0 + C - (A * (x0 - w) + B * y0 + C)) / (2 * w);
  assert (A * (x0 + w) + B * y0 + C - (A * (x0 - w) + B * y0 + C)) / (2 * w) == (A * x0 + A * w + B * y0 + C - A * x0 + A * w - B * y0 - C) / (2 * w);
  assert (A * x0 + A * w + B * y0 + C - A * x0 + A * w - B * y0 - C) / (2 * w) == (2 * A * w) / (2 * w);
  assert (2 * A * w) / (2 * w) == A;

  // Proof for DzDy
  assert HornDzDy(x0, y0, w) == (z(x0, y0 + w) - z(x0, y0 - w)) / (2 * w);
  assert (z(x0, y0 + w) - z(x0, y0 - w)) / (2 * w) == (A * x0 + B * (y0 + w) + C - (A * x0 + B * (y0 - w) + C)) / (2 * w);
  assert (A * x0 + B * (y0 + w) + C - A * x0 - B * (y0 - w) - C) / (2 * w) == (B * y0 + B * w + C - B * y0 + B * w - C) / (2 * w);
  assert (B * y0 + B * w + C - B * y0 + B * w - C) / (2 * w) == (2 * B * w) / (2 * w);
  assert (2 * B * w) / (2 * w) == B;
}
