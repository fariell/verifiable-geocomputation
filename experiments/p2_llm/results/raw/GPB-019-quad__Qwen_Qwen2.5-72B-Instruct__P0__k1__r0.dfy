method HornDzDx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real) returns (slope: real)
  requires w > 0
{
  slope := ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);
}

method HornDzDy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real) returns (slope: real)
  requires w > 0
{
  slope := ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w);
}

method SampleQuad(w: real, p: real, q: real) returns (z: real)
  requires w > 0
{
  var A: real := 0.3;
  var B: real := -0.2;
  var C: real := 5.0;
  var D: real := 0.05;
  var E: real := -0.04;
  var F: real := 0.02;
  var x: real := p * w;
  var y: real := q * w;
  z := A * x + B * y + C + D * x * x + E * x * y + F * y * y;
}

method WindowQuad(w: real) returns (pts: map<string, real>)
  requires w > 0
{
  pts := {
    "a" := SampleQuad(w, -1.0, -1.0),
    "b" := SampleQuad(w, 0.0, -1.0),
    "c" := SampleQuad(w, 1.0, -1.0),
    "d" := SampleQuad(w, -1.0, 0.0),
    "f" := SampleQuad(w, 1.0, 0.0),
    "g" := SampleQuad(w, -1.0, 1.0),
    "h" := SampleQuad(w, 0.0, 1.0),
    "i" := SampleQuad(w, 1.0, 1.0)
  };
}

method CubicXWindow(G: real, w: real) returns (pts: map<string, real>)
  requires w > 0
{
  pts := {
    "a" := G * (-1.0 * w) ** 3,
    "b" := G * (0.0 * w) ** 3,
    "c" := G * (1.0 * w) ** 3,
    "d" := G * (-1.0 * w) ** 3,
    "f" := G * (1.0 * w) ** 3,
    "g" := G * (-1.0 * w) ** 3,
    "h" := G * (0.0 * w) ** 3,
    "i" := G * (1.0 * w) ** 3
  };
}

lemma HornExactOnQuadratics(w: real, A: real, B: real, D: real, E: real, F: real)
  requires w > 0
  ensures HornDzDx(WindowQuad(w)["a"], WindowQuad(w)["b"], WindowQuad(w)["c"], WindowQuad(w)["d"], WindowQuad(w)["f"], WindowQuad(w)["g"], WindowQuad(w)["h"], WindowQuad(w)["i"], w) == A
  ensures HornDzDy(WindowQuad(w)["a"], WindowQuad(w)["b"], WindowQuad(w)["c"], WindowQuad(w)["d"], WindowQuad(w)["f"], WindowQuad(w)["g"], WindowQuad(w)["h"], WindowQuad(w)["i"], w) == B
{
  var pts := WindowQuad(w);
  var a := pts["a"];
  var b := pts["b"];
  var c := pts["c"];
  var d := pts["d"];
  var f := pts["f"];
  var g := pts["g"];
  var h := pts["h"];
  var i := pts["i"];

  // Prove HornDzDx == A
  assert a == A * (-w) + B * (-w) + C + D * (-w) * (-w) + E * (-w) * (-w) + F * (-w) * (-w);
  assert b == A * 0.0 + B * (-w) + C + D * 0.0 * 0.0 + E * 0.0 * (-w) + F * (-w) * (-w);
  assert c == A * w + B * (-w) + C + D * w * w + E * w * (-w) + F * (-w) * (-w);
  assert d == A * (-w) + B * 0.0 + C + D * (-w) * (-w) + E * (-w) * 0.0 + F * 0.0 * 0.0;
  assert f == A * w + B * 0.0 + C + D * w * w + E * w * 0.0 + F * 0.0 * 0.0;
  assert g == A * (-w) + B * w + C + D * (-w) * (-w) + E * (-w) * w + F * w * w;
  assert h == A * 0.0 + B * w + C + D * 0.0 * 0.0 + E * 0.0 * w + F * w * w;
  assert i == A * w + B * w + C + D * w * w + E * w * w + F * w * w;

  var dzdx := ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);
  assert dzdx == A;

  // Prove HornDzDy == B
  var dzdy := ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w);
  assert dzdy == B;
}

lemma CubicRemainderAtOrigin(G: real, w: real)
  requires w > 0
  ensures HornDzDx(CubicXWindow(G, w)["a"], CubicXWindow(G, w)["b"], CubicXWindow(G, w)["c"], CubicXWindow(G, w)["d"], CubicXWindow(G, w)["f"], CubicXWindow(G, w)["g"], CubicXWindow(G, w)["h"], CubicXWindow(G, w)["i"], w) - (3.0 * G * w * w) == 0.0
{
  var pts := CubicXWindow(G, w);
  var a := pts["a"];
  var b := pts["b"];
  var c := pts["c"];
  var d := pts["d"];
  var f := pts["f"];
  var g := pts["g"];
  var h := pts["h"];
  var i := pts["i"];

  // Calculate the Horn DzDx for the cubic surface
  var dzdx := ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w);

  // The true derivative at the origin for z = G * x^3 is 0.0
  // The remainder term is the difference between the Horn DzDx and the true derivative
  assert dzdx - 0.0 == 3.0 * G * w * w;
}
