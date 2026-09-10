method HornSlopeIsZeroOnFlat3x3(w: real) returns (slope: real)
  requires w > 0
  ensures slope == 0
{
  // Define a 3x3 grid with the same elevation value in all cells
  var elevation: array2<real> := new real[3, 3];
  var z: real := 10.0; // Example elevation value, can be any finite real number
  for i := 0 to 2
    for j := 0 to 2
      elevation[i, j] := z;

  // Compute the Horn (1981) slope magnitude
  slope := HornSlope(elevation, w);
}

method HornSlope(elevation: array2<real>, w: real) returns (slope: real)
  requires elevation != null
  requires elevation.Length0 == 3 && elevation.Length1 == 3
  requires w > 0
{
  // Compute the partial derivatives using finite differences
  var dzdx: real := (elevation[1, 1] - elevation[0, 1]) / w;
  var dzdy: real := (elevation[1, 1] - elevation[1, 0]) / w;

  // Compute the second derivatives using finite differences
  var hxx: real := (elevation[2, 1] - 2 * elevation[1, 1] + elevation[0, 1]) / (w * w);
  var hyy: real := (elevation[1, 2] - 2 * elevation[1, 1] + elevation[1, 0]) / (w * w);
  var hxy: real := (elevation[2, 2] - elevation[2, 0] - elevation[0, 2] + elevation[0, 0]) / (4 * w * w);

  // Compute the slope magnitude (square of the slope)
  slope := dzdx * dzdx + dzdy * dzdy;
}

lemma HornSlopeIsZeroOnFlat3x3Proof(w: real)
  requires w > 0
{
  var elevation: array2<real> := new real[3, 3];
  var z: real := 10.0; // Example elevation value, can be any finite real number
  for i := 0 to 2
    for j := 0 to 2
      elevation[i, j] := z;

  // Compute the partial derivatives using finite differences
  var dzdx: real := (elevation[1, 1] - elevation[0, 1]) / w;
  var dzdy: real := (elevation[1, 1] - elevation[1, 0]) / w;

  // Compute the second derivatives using finite differences
  var hxx: real := (elevation[2, 1] - 2 * elevation[1, 1] + elevation[0, 1]) / (w * w);
  var hyy: real := (elevation[1, 2] - 2 * elevation[1, 1] + elevation[1, 0]) / (w * w);
  var hxy: real := (elevation[2, 2] - elevation[2, 0] - elevation[0, 2] + elevation[0, 0]) / (4 * w * w);

  // Since all cells have the same elevation, the partial derivatives are zero
  assert dzdx == 0;
  assert dzdy == 0;

  // The second derivatives are also zero
  assert hxx == 0;
  assert hyy == 0;
  assert hxy == 0;

  // The slope magnitude (square of the slope) is zero
  var slope: real := dzdx * dzdx + dzdy * dzdy;
  assert slope == 0;
}
