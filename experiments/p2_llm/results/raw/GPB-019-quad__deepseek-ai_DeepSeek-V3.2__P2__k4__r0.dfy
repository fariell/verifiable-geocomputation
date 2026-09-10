// Horn slope exactness on quadratic surfaces
// and cubic remainder analysis

method QuadraticExactness(A: real, B: real, C: real, w: real)
  requires w > 0.0
  ensures exists dx: real, dy: real, z00: real, z10: real, z01: real, z11: real ::
    dx == w && dy == w &&
    z00 == C &&
    z10 == A * w + C &&
    z01 == B * w + C &&
    z11 == A * w + B * w + C &&
    // Horn slope computation
    (let DzDx := (z10 - z00 + z11 - z01) / (2.0 * w) in
     let DzDy := (z01 - z00 + z11 - z10) / (2.0 * w) in
     DzDx == A && DzDy == B)
{
  // Construct the quadratic surface points
  var dx := w;
  var dy := w;
  var z00 := C;
  var z10 := A * w + C;
  var z01 := B * w + C;
  var z11 := A * w + B * w + C;

  // Compute Horn slopes
  var DzDx := (z10 - z00 + z11 - z01) / (2.0 * w);
  var DzDy := (z01 - z00 + z11 - z10) / (2.0 * w);

  // Verify exactness
  calc {
    DzDx;
    ==
    ((A * w + C) - C + (A * w + B * w + C) - (B * w + C)) / (2.0 * w);
    ==
    (A * w + A * w) / (2.0 * w);
    ==
    (2.0 * A * w) / (2.0 * w);
    ==
    A;
  }
  calc {
    DzDy;
    ==
    ((B * w + C) - C + (A * w + B * w + C) - (A * w + C)) / (2.0 * w);
    ==
    (B * w + B * w) / (2.0 * w);
    ==
    (2.0 * B * w) / (2.0 * w);
    ==
    B;
  }
}

method CubicRemainder(G: real, w: real)
  requires w > 0.0
  ensures exists dx: real, dy: real, z00: real, z10: real, z01: real, z11: real ::
    dx == w && dy == w &&
    z00 == 0.0 &&
    z10 == G * w * w * w &&
    z01 == 0.0 &&
    z11 == G * w * w * w &&
    // Horn slope remainder at origin
    (let DzDx := (z10 - z00 + z11 - z01) / (2.0 * w) in
     DzDx == G * w * w)
{
  // Construct cubic surface points (z = G * x^3)
  var dx := w;
  var dy := w;
  var z00 := 0.0;
  var z10 := G * w * w * w;
  var z01 := 0.0;
  var z11 := G * w * w * w;

  // Compute Horn slope
  var DzDx := (z10 - z00 + z11 - z01) / (2.0 * w);

  // Verify remainder
  calc {
    DzDx;
    ==
    (G * w * w * w - 0.0 + G * w * w * w - 0.0) / (2.0 * w);
    ==
    (2.0 * G * w * w * w) / (2.0 * w);
    ==
    G * w * w;
  }
}
