function HornSlopeSq(a00: real, a01: real, a02: real,
                     a10: real, a11: real, a12: real,
                     a20: real, a21: real, a22: real, w: real): real
  requires w > 0.0
{
  var dzdx_numerator := a02 + 2.0*a12 + a22 - a00 - 2.0*a10 - a20;
  var dzdy_numerator := a20 + 2.0*a21 + a22 - a00 - 2.0*a01 - a02;
  var dzdx := dzdx_numerator / (8.0 * w);
  var dzdy := dzdy_numerator / (8.0 * w);
  dzdx * dzdx + dzdy * dzdy
}

lemma LemmaAllEqualImpliesZeroSlope(a00: real, a01: real, a02: real,
                                   a10: real, a11: real, a12: real,
                                   a20: real, a21: real, a22: real, w: real)
  requires w > 0.0
  requires a00 == a01 && a01 == a02 && a02 == a10 && a10 == a11 && a11 == a12 && a12 == a20 && a20 == a21 && a21 == a22
  ensures HornSlopeSq(a00, a01, a02, a10, a11, a12, a20, a21, a22, w) == 0.0
{
  // When all values are equal (let k = a00), both numerators become:
  // dzdx_numerator = k + 2k + k - k - 2k - k = (1+2+1-1-2-1)k = 0
  // dzdy_numerator = k + 2k + k - k - 2k - k = 0
  // Thus dzdx = 0, dzdy = 0, and SlopeSq = 0
}
