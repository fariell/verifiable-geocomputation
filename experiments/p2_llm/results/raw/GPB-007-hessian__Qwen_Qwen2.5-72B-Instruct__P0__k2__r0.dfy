method Main() {
  var A: real := 1.0;
  var B: real := 1.0;
  var C: real := 1.0;
  var D: real := 1.0;
  var E: real := 1.0;
  var F: real := 1.0;
  var w: real := 1.0;
  var x: real := 0.0;
  var y: real := 0.0;

  var hxx, hyy, hxy := ZT_Hessian(A, B, C, D, E, F, w, x, y);
  assert hxx == 2 * A;
  assert hyy == 2 * B;
  assert hxy == C;
}

method ZT_Hessian(A: real, B: real, C: real, D: real, E: real, F: real, w: real, x: real, y: real) returns (hxx: real, hyy: real, hxy: real)
  requires w > 0
  ensures hxx == 2 * A
  ensures hyy == 2 * B
  ensures hxy == C
{
  var h: array2<real> := new array2<real>(3, 3);
  for i: int | 0 <= i < 3
    for j: int | 0 <= j < 3
      h[i, j] := A * (x + i * w) * (x + i * w) + B * (y + j * w) * (y + j * w) + C * (x + i * w) * (y + j * w) + D * (x + i * w) + E * (y + j * w) + F;

  var hp: array2<real> := new array2<real>(5, 5);
  for i: int | 0 <= i < 5
    for j: int | 0 <= j < 5
      hp[i, j] := h[i - 1, j - 1];

  var a: real := hp[1, 1];
  var b: real := hp[1, 2];
  var c: real := hp[1, 3];
  var d: real := hp[2, 1];
  var e: real := hp[2, 2];
  var f: real := hp[2, 3];
  var g: real := hp[3, 1];
  var hh: real := hp[3, 2];
  var i: real := hp[3, 3];

  hxx := (d - 2.0 * e + f) / (w * w);
  hyy := (b - 2.0 * e + hh) / (w * w);
  hxy := (a - c - g + i) / (4.0 * w * w);
}

lemma QuadraticSurfaceHessian(A: real, B: real, C: real, D: real, E: real, F: real, w: real, x: real, y: real)
  requires w > 0
  ensures ZT_Hessian(A, B, C, D, E, F, w, x, y) == (2 * A, 2 * B, C)
{
  var h: array2<real> := new array2<real>(3, 3);
  for i: int | 0 <= i < 3
    for j: int | 0 <= j < 3
      h[i, j] := A * (x + i * w) * (x + i * w) + B * (y + j * w) * (y + j * w) + C * (x + i * w) * (y + j * w) + D * (x + i * w) + E * (y + j * w) + F;

  var hp: array2<real> := new array2<real>(5, 5);
  for i: int | 0 <= i < 5
    for j: int | 0 <= j < 5
      hp[i, j] := h[i - 1, j - 1];

  var a: real := hp[1, 1];
  var b: real := hp[1, 2];
  var c: real := hp[1, 3];
  var d: real := hp[2, 1];
  var e: real := hp[2, 2];
  var f: real := hp[2, 3];
  var g: real := hp[3, 1];
  var hh: real := hp[3, 2];
  var i: real := hp[3, 3];

  var hxx: real := (d - 2.0 * e + f) / (w * w);
  var hyy: real := (b - 2.0 * e + hh) / (w * w);
  var hxy: real := (a - c - g + i) / (4.0 * w * w);

  // Prove hxx == 2 * A
  assert d == A * (x + 1 * w) * (x + 1 * w) + B * (y + 1 * w) * (y + 1 * w) + C * (x + 1 * w) * (y + 1 * w) + D * (x + 1 * w) + E * (y + 1 * w) + F;
  assert e == A * (x + 1 * w) * (x + 1 * w) + B * (y + 1 * w) * (y + 1 * w) + C * (x + 1 * w) * (y + 1 * w) + D * (x + 1 * w) + E * (y + 1 * w) + F;
  assert f == A * (x + 1 * w) * (x + 1 * w) + B * (y + 2 * w) * (y + 2 * w) + C * (x + 1 * w) * (y + 2 * w) + D * (x + 1 * w) + E * (y + 2 * w) + F;
  assert d - 2.0 * e + f == A * (2 * w * w) + B * (0) + C * (0) + D * (0) + E * (0) + F * (0);
  assert hxx == 2 * A;

  // Prove hyy == 2 * B
  assert b == A * (x + 1 * w) * (x + 1 * w) + B * (y + 1 * w) * (y + 1 * w) + C * (x + 1 * w) * (y + 1 * w) + D * (x + 1 * w) + E * (y + 1 * w) + F;
  assert e == A * (x + 1 * w) * (x + 1 * w) + B * (y + 1 * w) * (y + 1 * w) + C * (x + 1 * w) * (y + 1 * w) + D * (x + 1 * w) + E * (y + 1 * w) + F;
  assert hh == A * (x + 1 * w) * (x + 1 * w) + B * (y + 2 * w) * (y + 2 * w) + C * (x + 1 * w) * (y + 2 * w) + D * (x + 1 * w) + E * (y + 2 * w) + F;
  assert b - 2.0 * e + hh == A * (0) + B * (2 * w * w) + C * (0) + D * (0) + E * (0) + F * (0);
  assert hyy == 2 * B;

  // Prove hxy == C
  assert a == A * (x + 0 * w) * (x + 0 * w) + B * (y + 1 * w) * (y + 1 * w) + C * (x + 0 * w) * (y + 1 * w) + D * (x + 0 * w) + E * (y + 1 * w) + F;
  assert c == A * (x + 2 * w) * (x + 2 * w) + B * (y + 1 * w) * (y + 1 * w) + C * (x + 2 * w) * (y + 1 * w) + D * (x + 2 * w) + E * (y + 1 * w) + F;
  assert g == A * (x + 1 * w) * (x + 1 * w) + B * (y + 0 * w) * (y + 0 * w) + C * (x + 1 * w) * (y + 0 * w) + D * (x + 1 * w) + E * (y + 0 * w) + F;
  assert i == A * (x + 2 * w) * (x + 2 * w) + B * (y + 2 * w) * (y + 2 * w) + C * (x + 2 * w) * (y + 2 * w) + D * (x + 2 * w) + E * (y + 2 * w) + F;
  assert a - c - g + i == A * (0) + B * (0) + C * (4 * w * w) + D * (0) + E * (0) + F * (0);
  assert hxy == C;
}
