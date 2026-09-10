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
        hp[i, j] := h[0, 0]; // Edge padding
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
  var h := hp[2, 1];
  var i := hp[2, 2];

  hxx := (d - 2.0 * e + f) / dx ** 2;
  hyy := (b - 2.0 * e + h) / dy ** 2;
  hxy := (a - c - g + i) / (4.0 * dx * dy);
}

lemma NumericZTExact(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0
  ensures NumericZT(new array2<real>(3, 3, (i, j) => A * i * i + B * j * j + C * i * j + D * i + E * j + F), w, w) == (2.0 * A, 2.0 * B, C)
{
  var h := new array2<real>(3, 3, (i, j) => A * i * i + B * j * j + C * i * j + D * i + E * j + F);

  var hp := new array2<real>(5, 5);
  for i := 0 to 4 {
    for j := 0 to 4 {
      if i >= 1 && i <= 3 && j >= 1 && j <= 3 {
        hp[i, j] := h[i - 1, j - 1];
      } else {
        hp[i, j] := h[0, 0]; // Edge padding
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
  var h := hp[2, 1];
  var i := hp[2, 2];

  var hxx := (d - 2.0 * e + f) / w ** 2;
  var hyy := (b - 2.0 * e + h) / w ** 2;
  var hxy := (a - c - g + i) / (4.0 * w * w);

  // Calculate the values of the quadratic function at the grid points
  var d_val := A * 1 * 1 + B * 0 * 0 + C * 1 * 0 + D * 1 + E * 0 + F;
  var e_val := A * 0 * 0 + B * 0 * 0 + C * 0 * 0 + D * 0 + E * 0 + F;
  var f_val := A * 1 * 1 + B * 0 * 0 + C * 1 * 0 + D * 1 + E * 0 + F;
  var b_val := A * 0 * 0 + B * 1 * 1 + C * 0 * 1 + D * 0 + E * 1 + F;
  var h_val := A * 0 * 0 + B * 1 * 1 + C * 0 * 1 + D * 0 + E * 1 + F;
  var a_val := A * 0 * 0 + B * 0 * 0 + C * 0 * 0 + D * 0 + E * 0 + F;
  var c_val := A * 0 * 0 + B * 0 * 0 + C * 0 * 0 + D * 0 + E * 0 + F;
  var g_val := A * 0 * 0 + B * 0 * 0 + C * 0 * 0 + D * 0 + E * 0 + F;
  var i_val := A * 2 * 2 + B * 2 * 2 + C * 2 * 2 + D * 2 + E * 2 + F;

  // Verify the values
  assert d == d_val;
  assert e == e_val;
  assert f == f_val;
  assert b == b_val;
  assert h == h_val;
  assert a == a_val;
  assert c == c_val;
  assert g == g_val;
  assert i == i_val;

  // Calculate the exact values of the Hessian
  var hxx_exact := 2.0 * A;
  var hyy_exact := 2.0 * B;
  var hxy_exact := C;

  // Verify the Hessian values
  assert hxx == hxx_exact;
  assert hyy == hyy_exact;
  assert hxy == hxy_exact;
}
