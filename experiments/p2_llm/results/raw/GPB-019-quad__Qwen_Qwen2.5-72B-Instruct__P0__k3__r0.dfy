method HornDzDx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real) returns (slope: real)
  requires w > 0
{
  slope := (c + 2.0 * f + i - (a + 2.0 * d + g)) / (8.0 * w);
}

method HornDzDy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real) returns (slope: real)
  requires w > 0
{
  slope := (g + 2.0 * h + i - (a + 2.0 * b + c)) / (8.0 * w);
}

method SampleQuad(w: real, p: real, q: real, A: real, B: real, C: real, D: real, E: real, F: real) returns (z: real)
  requires w > 0
{
  z := A * p * w + B * q * w + C + D * p * p * w * w + E * p * q * w * w + F * q * q * w * w;
}

method WindowQuad(w: real, A: real, B: real, C: real, D: real, E: real, F: real) returns (pts: map<string, real>)
  requires w > 0
{
  pts := {
    "a" := SampleQuad(w, -1.0, -1.0, A, B, C, D, E, F),
    "b" := SampleQuad(w, 0.0, -1.0, A, B, C, D, E, F),
    "c" := SampleQuad(w, 1.0, -1.0, A, B, C, D, E, F),
    "d" := SampleQuad(w, -1.0, 0.0, A, B, C, D, E, F),
    "f" := SampleQuad(w, 1.0, 0.0, A, B, C, D, E, F),
    "g" := SampleQuad(w, -1.0, 1.0, A, B, C, D, E, F),
    "h" := SampleQuad(w, 0.0, 1.0, A, B, C, D, E, F),
    "i" := SampleQuad(w, 1.0, 1.0, A, B, C, D, E, F)
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

lemma HornSlopeExactOnQuadratics(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0
  ensures HornDzDx(WindowQuad(w, A, B, C, D, E, F)["a"], WindowQuad(w, A, B, C, D, E, F)["b"], WindowQuad(w, A, B, C, D, E, F)["c"], 
                 WindowQuad(w, A, B, C, D, E, F)["d"], WindowQuad(w, A, B, C, D, E, F)["f"], WindowQuad(w, A, B, C, D, E, F)["g"], 
                 WindowQuad(w, A, B, C, D, E, F)["h"], WindowQuad(w, A, B, C, D, E, F)["i"], w) == A
  ensures HornDzDy(WindowQuad(w, A, B, C, D, E, F)["a"], WindowQuad(w, A, B, C, D, E, F)["b"], WindowQuad(w, A, B, C, D, E, F)["c"], 
                 WindowQuad(w, A, B, C, D, E, F)["d"], WindowQuad(w, A, B, C, D, E, F)["f"], WindowQuad(w, A, B, C, D, E, F)["g"], 
                 WindowQuad(w, A, B, C, D, E, F)["h"], WindowQuad(w, A, B, C, D, E, F)["i"], w) == B
{
  var pts := WindowQuad(w, A, B, C, D, E, F);
  var a := pts["a"];
  var b := pts["b"];
  var c := pts["c"];
  var d := pts["d"];
  var f := pts["f"];
  var g := pts["g"];
  var h := pts["h"];
  var i := pts["i"];

  // Prove HornDzDx is A
  var dzdx := HornDzDx(a, b, c, d, f, g, h, i, w);
  assert dzdx == (c + 2.0 * f + i - (a + 2.0 * d + g)) / (8.0 * w);
  assert c + 2.0 * f + i - (a + 2.0 * d + g) == (A * 1.0 * w + B * -1.0 * w + C + D * 1.0 * 1.0 * w * w + E * 1.0 * -1.0 * w * w + F * -1.0 * -1.0 * w * w) 
                    + 2.0 * (A * 1.0 * w + B * 0.0 * w + C + D * 1.0 * 1.0 * w * w + E * 1.0 * 0.0 * w * w + F * 0.0 * 0.0 * w * w) 
                    + (A * 1.0 * w + B * 1.0 * w + C + D * 1.0 * 1.0 * w * w + E * 1.0 * 1.0 * w * w + F * 1.0 * 1.0 * w * w) 
                    - (A * -1.0 * w + B * -1.0 * w + C + D * -1.0 * -1.0 * w * w + E * -1.0 * -1.0 * w * w + F * -1.0 * -1.0 * w * w) 
                    - 2.0 * (A * -1.0 * w + B * 0.0 * w + C + D * -1.0 * -1.0 * w * w + E * -1.0 * 0.0 * w * w + F * 0.0 * 0.0 * w * w) 
                    - (A * -1.0 * w + B * 1.0 * w + C + D * -1.0 * 1.0 * w * w + E * -1.0 * 1.0 * w * w + F * 1.0 * 1.0 * w * w);
  assert dzdx == A;

  // Prove HornDzDy is B
  var dzdy := HornDzDy(a, b, c, d, f, g, h, i, w);
  assert dzdy == (g + 2.0 * h + i - (a + 2.0 * b + c)) / (8.0 * w);
  assert g + 2.0 * h + i - (a + 2.0 * b + c) == (A * -1.0 * w + B * 1.0 * w + C + D * -1.0 * 1.0 * w * w + E * -1.0 * 1.0 * w * w + F * 1.0 * 1.0 * w * w) 
                    + 2.0 * (A * 0.0 * w + B * 1.0 * w + C + D * 0.0 * 1.0 * w * w + E * 0.0 * 1.0 * w * w + F * 1.0 * 1.0 * w * w) 
                    + (A * 1.0 * w + B * 1.0 * w + C + D * 1.0 * 1.0 * w * w + E * 1.0 * 1.0 * w * w + F * 1.0 * 1.0 * w * w) 
                    - (A * -1.0 * w + B * -1.0 * w + C + D * -1.0 * -1.0 * w * w + E * -1.0 * -1.0 * w * w + F * -1.0 * -1.0 * w * w) 
                    - 2.0 * (A * 0.0 * w + B * -1.0 * w + C + D * 0.0 * -1.0 * w * w + E * 0.0 * -1.0 * w * w + F * -1.0 * -1.0 * w * w) 
                    - (A * 1.0 * w + B * -1.0 * w + C + D * 1.0 * -1.0 * w * w + E * 1.0 * -1.0 * w * w + F * -1.0 * -1.0 * w * w);
  assert dzdy == B;
}

lemma CubicRemainderAtOrigin(G: real, w: real)
  requires w > 0
  ensures HornDzDx(CubicXWindow(G, w)["a"], CubicXWindow(G, w)["b"], CubicXWindow(G, w)["c"], 
                   CubicXWindow(G, w)["d"], CubicXWindow(G, w)["f"], CubicXWindow(G, w)["g"], 
                   CubicXWindow(G, w)["h"], CubicXWindow(G, w)["i"], w) - 3.0 * G * w * w == 0
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

  var dzdx := HornDzDx(a, b, c, d, f, g, h, i, w);
  assert dzdx == (c + 2.0 * f + i - (a + 2.0 * d + g)) / (8.0 * w);
  assert c + 2.0 * f + i - (a + 2.0 * d + g) == (G * (1.0 * w) ** 3) 
                    + 2.0 * (G * (1.0 * w) ** 3) 
                    + (G * (1.0 * w) ** 3) 
                    - (G * (-1.0 * w) ** 3) 
                    - 2.0 * (G * (-1.0 * w) ** 3) 
                    - (G * (-1.0 * w) ** 3);
  assert dzdx == (G * w * w * w + 2.0 * G * w * w * w + G * w * w * w - (G * -w * w * w + 2.0 * G * -w * w * w + G * -w * w * w)) / (8.0 * w);
  assert dzdx == (4.0 * G * w * w * w) / (8.0 * w);
  assert dzdx == 0.5 * G * w * w;
  assert dzdx - 3.0 * G * w * w == -2.5 * G * w * w;
  assert -2.5 * G * w * w == 0;  // This is a contradiction, so the lemma is false.
}
