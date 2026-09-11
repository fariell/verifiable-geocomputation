function dzdx(elev: (int, int) -> real, w: real): real
  requires w > 0.0
{
  ( (elev(0,2) + 2.0*elev(1,2) + elev(2,2)) - (elev(0,0) + 2.0*elev(1,0) + elev(2,0)) ) / (8.0 * w)
}

function dzdy(elev: (int, int) -> real, w: real): real
  requires w > 0.0
{
  ( (elev(2,0) + 2.0*elev(2,1) + elev(2,2)) - (elev(0,0) + 2.0*elev(0,1) + elev(0,2)) ) / (8.0 * w)
}

function SlopeSq(elev: (int, int) -> real, w: real): real
  requires w > 0.0
{
  var dx := dzdx(elev, w);
  var dy := dzdy(elev, w);
  dx*dx + dy*dy
}

lemma Theorem(elev: (int, int) -> real, w: real)
  requires w > 0.0
  requires forall i,j :: 0 <= i < 3 && 0 <= j < 3 ==> elev(i,j) == elev(0,0)
  ensures SlopeSq(elev, w) == 0.0
{
  // All elements equal to elev(0,0)
  var z := elev(0,0);
  // Numerator of dzdx simplifies to (4z - 4z) = 0
  assert dzdx(elev, w) == 0.0;
  // Numerator of dzdy simplifies to (4z - 4z) = 0
  assert dzdy(elev, w) == 0.0;
  // Thus SlopeSq = 0² + 0² = 0
}
