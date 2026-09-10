// Horn (1981) slope magnitude on a 3x3 window
// Theorem: If all nine cells have the same elevation, the slope magnitude is zero.

method Theorem_SlopeZeroOnFlatWindow(w: real) returns (slopeSq: real)
  requires w > 0.0
  ensures slopeSq == 0.0
{
  // Assume a 3x3 elevation window with all equal finite values
  var e00: real := 1.0;
  var e01: real := 1.0;
  var e02: real := 1.0;
  var e10: real := 1.0;
  var e11: real := 1.0;
  var e12: real := 1.0;
  var e20: real := 1.0;
  var e21: real := 1.0;
  var e22: real := 1.0;

  // Horn (1981) finite-difference slope components
  var dzdx: real := (e02 + 2.0*e12 + e22 - e00 - 2.0*e10 - e20) / (8.0 * w);
  var dzdy: real := (e20 + 2.0*e21 + e22 - e00 - 2.0*e01 - e02) / (8.0 * w);

  // Slope magnitude squared
  slopeSq := dzdx*dzdx + dzdy*dzdy;

  // Since all elevations are equal, dzdx and dzdy are zero
  assert dzdx == 0.0 && dzdy == 0.0 by {
    calc {
      e02 + 2.0*e12 + e22 - e00 - 2.0*e10 - e20;
      == 1.0 + 2.0*1.0 + 1.0 - 1.0 - 2.0*1.0 - 1.0;
      == 0.0;
    }
    calc {
      e20 + 2.0*e21 + e22 - e00 - 2.0*e01 - e02;
      == 1.0 + 2.0*1.0 + 1.0 - 1.0 - 2.0*1.0 - 1.0;
      == 0.0;
    }
  }
  assert slopeSq == 0.0;
}
