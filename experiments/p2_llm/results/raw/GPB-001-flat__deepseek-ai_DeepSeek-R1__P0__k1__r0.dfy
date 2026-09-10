// Horn slope magnitude on constant elevation window
function HornSlopeSq(z00: real, z01: real, z02: real,
                     z10: real, z11: real, z12: real,
                     z20: real, z21: real, z22: real, w: real): real
  requires w > 0.0
{
  // Horn (1981) finite-difference slope components
  var dzdx := (z02 + 2.0*z12 + z22 - z00 - 2.0*z10 - z20) / (8.0 * w);
  var dzdy := (z00 + 2.0*z01 + z02 - z20 - 2.0*z21 - z22) / (8.0 * w);
  // Slope magnitude squared
  dzdx*dzdx + dzdy*dzdy
}

lemma ZeroSlopeOnConstantWindow(z: real, w: real)
  requires w > 0.0
  ensures HornSlopeSq(z, z, z, 
                      z, z, z, 
                      z, z, z, w) == 0.0
{
  // Both derivatives evaluate to zero when all elevations are equal
  assert (z + 2.0*z + z - z - 2.0*z - z) == 0.0;  // dzdx numerator
  assert (z + 2.0*z + z - z - 2.0*z - z) == 0.0;  // dzdy numerator
}
