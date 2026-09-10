// Horn slope magnitude on constant elevation window
// Formalization of GPB-019 proposition: Horn slope is zero on flat terrain

function HornSlopeSq(z00: real, z01: real, z02: real,
                     z10: real, z11: real, z12: real,
                     z20: real, z21: real, z22: real, w: real): real
  requires w > 0.0
{
  // Compute finite differences using Horn (1981) kernel
  var dzdx := ((z00 + 2*z01 + z02) - (z20 + 2*z21 + z22)) / (8.0 * w);
  var dzdy := ((z02 + 2*z12 + z22) - (z00 + 2*z10 + z20)) / (8.0 * w);
  dzdx*dzdx + dzdy*dzdy
}

lemma FlatTerrainZeroSlope(z: real, w: real)
  requires w > 0.0
  ensures HornSlopeSq(z, z, z, 
                      z, z, z, 
                      z, z, z, w) == 0.0
{
  // All input values are identical (z), so differences cancel
  // Direct computation shows both partial derivatives are zero
  calc {
    HornSlopeSq(z, z, z, z, z, z, z, z, z, w);
    ==  // Expand definition
    {
      var dzdx := ((z + 2*z + z) - (z + 2*z + z)) / (8.0 * w);
      var dzdy := ((z + 2*z + z) - (z + 2*z + z)) / (8.0 * w);
      dzdx*dzdx + dzdy*dzdy;
    }
    ==  // Simplify numerator: (4z - 4z) = 0
    {
      var dzdx := 0.0 / (8.0 * w);
      var dzdy := 0.0 / (8.0 * w);
      0.0*0.0 + 0.0*0.0;
    }
    ==  // Arithmetic
    0.0;
  }
}
