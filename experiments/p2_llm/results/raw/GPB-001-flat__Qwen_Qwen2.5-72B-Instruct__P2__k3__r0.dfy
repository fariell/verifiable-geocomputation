method HornSlopeIsZero(elevations: array2<int>, w: real) returns (slopeSq: real)
  requires elevations != null
  requires elevations.Rows == 3 && elevations.Cols == 3
  requires w > 0.0
  requires forall i, j :: 0 <= i < 3 && 0 <= j < 3 ==> elevations[i, j] == elevations[0, 0]
  ensures slopeSq == 0.0
{
  var z00 := elevations[0, 0];
  var z01 := elevations[0, 1];
  var z02 := elevations[0, 2];
  var z10 := elevations[1, 0];
  var z11 := elevations[1, 1];
  var z12 := elevations[1, 2];
  var z20 := elevations[2, 0];
  var z21 := elevations[2, 1];
  var z22 := elevations[2, 2];

  var dzdx := (z02 + 2 * z12 + z22 - (z00 + 2 * z10 + z20)) / (8 * w);
  var dzdy := (z20 + 2 * z21 + z22 - (z00 + 2 * z01 + z02)) / (8 * w);

  slopeSq := dzdx * dzdx + dzdy * dzdy;
}
