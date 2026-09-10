method HornSlopeZeroOnFlatWindow(elev: array2<int>, w: real) returns (slopeSq: real)
  requires elev.Length0 == 3 && elev.Length1 == 3
  requires w > 0.0
  requires forall i, j :: 0 <= i < 3 && 0 <= j < 3 ==> elev[i, j] == elev[0, 0]
  ensures slopeSq == 0.0
{
  // Horn (1981) slope calculation for a 3x3 window
  // dx = (elev[2,0] + 2*elev[2,1] + elev[2,2] - elev[0,0] - 2*elev[0,1] - elev[0,2]) / (8*w)
  // dy = (elev[0,2] + 2*elev[1,2] + elev[2,2] - elev[0,0] - 2*elev[1,0] - elev[2,0]) / (8*w)
  // slopeSq = dx*dx + dy*dy

  // Since all elevations are equal, let c = elev[0,0]
  var c := elev[0, 0];
  // Compute numerator for dx
  var dx_num := (c + 2*c + c) - (c + 2*c + c);
  // Compute numerator for dy
  var dy_num := (c + 2*c + c) - (c + 2*c + c);
  // Both numerators are zero
  var dx := dx_num / (8.0 * w);
  var dy := dy_num / (8.0 * w);
  slopeSq := dx*dx + dy*dy;
  // Since dx = 0 and dy = 0, slopeSq = 0
}
