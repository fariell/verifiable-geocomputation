method HornSlopeIsZeroOnFlat3x3(w: real) returns (slope: real)
  requires w > 0
  ensures slope == 0
{
  // Define a 3x3 grid with the same elevation value in each cell
  var elevation: array2<int, real> := new real[3, 3];
  var z: real := 10.0; // Example elevation value, can be any finite real number
  for i := 0 to 2
    for j := 0 to 2
      elevation[i, j] := z;

  // Compute the Horn (1981) slope magnitude
  var dzdx: real := (elevation[1, 2] - elevation[1, 0]) / (2 * w);
  var dzdy: real := (elevation[2, 1] - elevation[0, 1]) / (2 * w);
  var slopeSq: real := dzdx * dzdx + dzdy * dzdy;
  slope := slopeSq.sqrt();

  // Since all elevations are the same, dzdx and dzdy should be 0
  assert dzdx == 0;
  assert dzdy == 0;
  assert slopeSq == 0;
  assert slope == 0;
}
