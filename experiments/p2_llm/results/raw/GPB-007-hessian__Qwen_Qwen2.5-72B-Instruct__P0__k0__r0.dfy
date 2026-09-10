method Main() {
  var A: real := 1.0;
  var B: real := 1.0;
  var C: real := 1.0;
  var D: real := 0.0;
  var E: real := 0.0;
  var F: real := 0.0;
  var w: real := 1.0;

  assert w > 0;

  var h := new array2<real>(3, 3);
  for i := 0 to 2 {
    for j := 0 to 2 {
      h[i, j] := A * i * i + B * j * j + C * i * j + D * i + E * j + F;
    }
  }

  var hxx, hyy, hxy := NumericZT(h, w, w);

  assert hxx == 2.0 * A;
  assert hyy == 2.0 * B;
  assert hxy == C;
}

method NumericZT(h: array2<real>, dx: real, dy: real) returns (hxx: real, hyy: real, hxy: real) {
  assert dx > 0 && dy > 0;

  var hp := new array2<real>(5, 5);
  for i := 0 to 4 {
    for j := 0 to 4 {
      if i >= 1 && i <= 3 && j >= 1 && j <= 3 {
        hp[i, j] := h[i - 1, j - 1];
      } else {
        hp[i, j] := h[0, 0]; // Edge padding with the first element
      }
    }
  }

  var a := hp[0, 0];
  var b := hp[0, 1];
  var c := hp[0, 2];
  var d := hp[1, 0];
  var e := hp[1, 1];
  var f := hp[1, 2];
  var g := hp[2, 0];
  var hh := hp[2, 1];
  var i := hp[2, 2];

  hxx := (d - 2.0 * e + f) / dx ** 2;
  hyy := (b - 2.0 * e + hh) / dy ** 2;
  hxy := (a - c - g + i) / (4.0 * dx * dy);

  return hxx, hyy, hxy;
}

method ProfileCurv(hxx: real, hyy: real, hxy: real, dzdx: real, dzdy: real) returns (curv: real) {
  var denom := (dzdx ** 2 + dzdy ** 2) ** 1.5;
  if denom > 1e-9 {
    curv := (hxx * dzdx ** 2 + 2.0 * hxy * dzdx * dzdy + hyy * dzdy ** 2) / denom;
  } else {
    curv := 0.0;
  }
  return curv;
}
