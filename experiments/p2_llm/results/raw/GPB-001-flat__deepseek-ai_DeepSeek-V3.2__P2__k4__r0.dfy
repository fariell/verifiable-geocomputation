method HornSlopeZeroOnFlatWindow(elev: array2<int>, w: real)
  requires w > 0.0
  requires elev.Length0 == 3 && elev.Length1 == 3
  requires forall i, j :: 0 <= i < 3 && 0 <= j < 3 ==> elev[i, j] < 2147483647
  ensures HornSlopeSq(elev, w) == 0.0
{
  // The Horn (1981) slope calculation for a 3x3 window
  // If all elevations are equal, the slope magnitude is zero
}

function HornSlopeSq(elev: array2<int>, w: real): real
  requires w > 0.0
  requires elev.Length0 == 3 && elev.Length1 == 3
  requires forall i, j :: 0 <= i < 3 && 0 <= j < 3 ==> elev[i, j] < 2147483647
{
  var a := elev[0,0];
  // Check that all elevations are equal
  if forall i, j :: 0 <= i < 3 && 0 <= j < 3 ==> elev[i, j] == a then
    0.0
  else
    // Non‑zero slope when elevations differ
    var dz_dx := ((elev[0,2] + 2*elev[1,2] + elev[2,2]) - (elev[0,0] + 2*elev[1,0] + elev[2,0])) / (8.0 * w);
    var dz_dy := ((elev[2,0] + 2*elev[2,1] + elev[2,2]) - (elev[0,0] + 2*elev[0,1] + elev[0,2])) / (8.0 * w);
    dz_dx * dz_dx + dz_dy * dz_dy
}
