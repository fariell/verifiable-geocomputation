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

  assert hxx == 2 * A;
  assert hyy == 2 * B;
  assert hxy == C;
}

method NumericZT(h: array2<real>, dx: real, dy: real) returns (hxx: real, hyy: real, hxy: real) {
  requires h.Length0 == 3 && h.Length1 == 3;
  requires dx > 0 && dy > 0;

  var hp := new array2<real>(5, 5);
  for i := 0 to 4 {
    for j := 0 to 4 {
      if i >= 1 && i <= 3 && j >= 1 && j <= 3 {
        hp[i, j] := h[i - 1, j - 1];
      } else {
        hp[i, j] := h[0, 0]; // Edge padding with the corner value
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
  ensures w > 0 ==>
    NumericZT(new array2<real>(3, 3, (i, j) => A * i * i + B * j * j + C * i * j + D * i + E * j + F), w, w) == (2 * A, 2 * B, C)
{
  var h := new array2<real>(3, 3, (i, j) => A * i * i + B * j * j + C * i * j + D * i + E * j + F);
  var hxx, hyy, hxy := NumericZT(h, w, w);

  // Calculate the values of the padded array
  var hp := new array2<real>(5, 5);
  for i := 0 to 4 {
    for j := 0 to 4 {
      if i >= 1 && i <= 3 && j >= 1 && j <= 3 {
        hp[i, j] := h[i - 1, j - 1];
      } else {
        hp[i, j] := h[0, 0]; // Edge padding with the corner value
      }
    }
  }

  // Extract the necessary values from the padded array
  var a := hp[0, 0];
  var b := hp[0, 1];
  var c := hp[0, 2];
  var d := hp[1, 0];
  var e := hp[1, 1];
  var f := hp[1, 2];
  var g := hp[2, 0];
  var h := hp[2, 1];
  var i := hp[2, 2];

  // Calculate the expected values
  var expected_hxx := (d - 2.0 * e + f) / w ** 2;
  var expected_hyy := (b - 2.0 * e + h) / w ** 2;
  var expected_hxy := (a - c - g + i) / (4.0 * w * w);

  // Verify the expected values
  assert expected_hxx == 2 * A;
  assert expected_hyy == 2 * B;
  assert expected_hxy == C;

  // Ensure the method returns the expected values
  assert hxx == expected_hxx;
  assert hyy == expected_hyy;
  assert hxy == expected_hxy;
}
