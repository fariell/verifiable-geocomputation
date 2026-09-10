method HornSlopeIsZeroOnFlat3x3(w: real) returns (slope: real)
  requires w > 0
  ensures slope == 0
{
  // Define a 3x3 grid with all cells having the same elevation
  var elevation: array2<int, real> := new array2<int, real>(3, 3);
  var z: real := 10.0;  // Example elevation value, can be any real number
  for i := 0 to 2
    for j := 0 to 2
      elevation[i, j] := z;

  // Compute the Horn (1981) slope magnitude
  slope := HornSlope(elevation, w);
}

method HornSlope(elevation: array2<int, real>, w: real) returns (slope: real)
  requires elevation != null
  requires elevation.Length0 == 3 && elevation.Length1 == 3
  requires w > 0
{
  // Compute the partial derivatives using finite differences
  var dzdx: real := (elevation[1, 2] - elevation[1, 0]) / (2 * w);
  var dzdy: real := (elevation[2, 1] - elevation[0, 1]) / (2 * w);

  // Compute the second-order partial derivatives
  var hxx: real := (elevation[1, 2] - 2 * elevation[1, 1] + elevation[1, 0]) / (w * w);
  var hyy: real := (elevation[2, 1] - 2 * elevation[1, 1] + elevation[0, 1]) / (w * w);
  var hxy: real := (elevation[2, 2] - elevation[2, 0] - elevation[0, 2] + elevation[0, 0]) / (4 * w * w);

  // Compute the slope magnitude (square of the slope)
  slope := dzdx * dzdx + dzdy * dzdy;
}

lemma HornSlopeIsZeroOnFlat3x3Proof(w: real)
  requires w > 0
{
  var elevation: array2<int, real> := new array2<int, real>(3, 3);
  var z: real := 10.0;  // Example elevation value, can be any real number
  for i := 0 to 2
    for j := 0 to 2
      elevation[i, j] := z;

  // Compute the partial derivatives using finite differences
  var dzdx: real := (elevation[1, 2] - elevation[1, 0]) / (2 * w);
  var dzdy: real := (elevation[2, 1] - elevation[0, 1]) / (2 * w);

  // Compute the second-order partial derivatives
  var hxx: real := (elevation[1, 2] - 2 * elevation[1, 1] + elevation[1, 0]) / (w * w);
  var hyy: real := (elevation[2, 1] - 2 * elevation[1, 1] + elevation[0, 1]) / (w * w);
  var hxy: real := (elevation[2, 2] - elevation[2, 0] - elevation[0, 2] + elevation[0, 0]) / (4 * w * w);

  // Since all cells have the same elevation, the partial derivatives are zero
  assert dzdx == 0;
  assert dzdy == 0;

  // The slope magnitude (square of the slope) is the sum of the squares of the partial derivatives
  var slope: real := dzdx * dzdx + dzdy * dzdy;

  // Since dzdx and dzdy are zero, the slope magnitude is zero
  assert slope == 0;
}
