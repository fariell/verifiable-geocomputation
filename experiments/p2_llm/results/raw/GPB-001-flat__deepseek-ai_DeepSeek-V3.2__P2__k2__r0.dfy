// Horn (1981) slope magnitude theorem for 3x3 window
// Theorem: If all nine cells in a 3x3 window have the same elevation,
//          then the Horn slope magnitude (and its square SlopeSq) is zero.
// Grid spacing w must be positive.

method HornSlopeZeroTheorem(w: real) returns (SlopeSq: real)
  requires w > 0.0
  ensures SlopeSq == 0.0
{
  // Assume a 3x3 elevation window with all cells equal to some constant e
  var e: real := 0.0; // arbitrary constant elevation
  var z: array2<int, real> := new int[3, 3] (_i, _j => e);

  // Horn (1981) finite-difference slope components
  var dzdx: real :=
    (z[2,0] + 2.0*z[2,1] + z[2,2]) - (z[0,0] + 2.0*z[0,1] + z[0,2]);
  var dzdy: real :=
    (z[0,2] + 2.0*z[1,2] + z[2,2]) - (z[0,0] + 2.0*z[1,0] + z[2,0]);

  // Scale by grid spacing (8*w for dzdx, 8*w for dzdy)
  dzdx := dzdx / (8.0 * w);
  dzdy := dzdy / (8.0 * w);

  // Slope magnitude squared
  SlopeSq := dzdx*dzdx + dzdy*dzdy;

  // Proof that SlopeSq == 0 when all z[i,j] == e
  // Since all z[i,j] are equal to e:
  //   dzdx numerator = (e + 2e + e) - (e + 2e + e) = 4e - 4e = 0
  //   dzdy numerator = (e + 2e + e) - (e + 2e + e) = 4e - 4e = 0
  // Therefore dzdx = 0, dzdy = 0, and SlopeSq = 0.
  assert dzdx == 0.0 && dzdy == 0.0 by {
    calc {
      (z[2,0] + 2.0*z[2,1] + z[2,2]) - (z[0,0] + 2.0*z[0,1] + z[0,2]);
      == (e + 2.0*e + e) - (e + 2.0*e + e);
      == 4.0*e - 4.0*e;
      == 0.0;
    }
    calc {
      (z[0,2] + 2.0*z[1,2] + z[2,2]) - (z[0,0] + 2.0*z[1,0] + z[2,0]);
      == (e + 2.0*e + e) - (e + 2.0*e + e);
      == 4.0*e - 4.0*e;
      == 0.0;
    }
  }
}
