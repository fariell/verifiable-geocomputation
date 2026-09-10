// P004_consistency.dfy
// Horn slope is exact on quadratic surfaces: DzDx and DzDy recover the true planar
// gradient coefficients (A,B) identically. Separately, on z = G x^3 the DzDx remainder at
// the origin equals G w^2 (order O(w^2)).

module Consistency {

  // Constants for the quadratic surface
  const A_QUAD: real := 0.3
  const B_QUAD: real := -0.2
  const C_QUAD: real := 5.0
  const D_QUAD: real := 0.05
  const E_QUAD: real := -0.04
  const F_QUAD: real := 0.02

  // Constant for the cubic surface
  const G_CUBIC: real := 0.07

  // Function to sample a point on the quadratic surface
  function sampleQuad(w: real, p: real, q: real): real {
    var x := p * w;
    var y := q * w;
    A_QUAD * x + B_QUAD * y + C_QUAD + D_QUAD * x * x + E_QUAD * x * y + F_QUAD * y * y
  }

  // Function to sample a point on the cubic surface
  function sampleCubic(G: real, w: real, p: real): real {
    G * (p * w) ** 3
  }

  // Horn's DzDx and DzDy functions
  function hornDzDx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real {
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w)
  }

  function hornDzDy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real {
    ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w)
  }

  // Function to create a window of points for the quadratic surface
  function windowQuad(w: real): map<string, real> {
    map(
      "a" => sampleQuad(w, -1.0, -1.0),
      "b" => sampleQuad(w, 0.0, -1.0),
      "c" => sampleQuad(w, 1.0, -1.0),
      "d" => sampleQuad(w, -1.0, 0.0),
      "f" => sampleQuad(w, 1.0, 0.0),
      "g" => sampleQuad(w, -1.0, 1.0),
      "h" => sampleQuad(w, 0.0, 1.0),
      "i" => sampleQuad(w, 1.0, 1.0)
    )
  }

  // Function to create a window of points for the cubic surface
  function cubicXWindow(G: real, w: real): map<string, real> {
    map(
      "a" => sampleCubic(G, w, -1.0),
      "b" => sampleCubic(G, w, 0.0),
      "c" => sampleCubic(G, w, 1.0),
      "d" => sampleCubic(G, w, -1.0),
      "f" => sampleCubic(G, w, 1.0),
      "g" => sampleCubic(G, w, -1.0),
      "h" => sampleCubic(G, w, 0.0),
      "i" => sampleCubic(G, w, 1.0)
    )
  }

  // Theorem: Horn slope is exact on quadratic surfaces
  theorem HornExactOnQuadratics(w: real) {
    requires w > 0.0;
    var window := windowQuad(w);
    var dzdx := hornDzDx(window["a"], window["b"], window["c"], window["d"], window["f"], window["g"], window["h"], window["i"], w);
    var dzdy := hornDzDy(window["a"], window["b"], window["c"], window["d"], window["f"], window["g"], window["h"], window["i"], w);
    assert dzdx == A_QUAD;
    assert dzdy == B_QUAD;
  }

  // Theorem: On z = G x^3, the DzDx remainder at the origin equals G w^2 (order O(w^2))
  theorem CubicDzDxRemainder(w: real) {
    requires w > 0.0;
    var window := cubicXWindow(G_CUBIC, w);
    var dzdx := hornDzDx(window["a"], window["b"], window["c"], window["d"], window["f"], window["g"], window["h"], window["i"], w);
    assert dzdx == 3.0 * G_CUBIC * w * w;
  }

}
