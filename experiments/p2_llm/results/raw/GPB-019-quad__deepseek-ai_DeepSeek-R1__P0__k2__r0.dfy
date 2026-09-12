// P0 · Zero-shot auto-formalization: Horn slope properties
// Horn slope is exact on quadratic surfaces and has O(w²) remainder on cubics

function method HornDzDx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
  requires w != 0.0
{
  ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w)
}

function method HornDzDy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
  requires w != 0.0
{
  ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w)
}

function method Quadratic(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A*x + B*y + C + D*x*x + E*x*y + F*y*y
}

function method Cubic(x: real, y: real, G: real): real
{
  G * x * x * x
}

lemma ExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w != 0.0
  ensures 
    HornDzDx(
      Quadratic(-w, -w, A, B, C, D, E, F),
      Quadratic(0.0, -w, A, B, C, D, E, F),
      Quadratic(w, -w, A, B, C, D, E, F),
      Quadratic(-w, 0.0, A, B, C, D, E, F),
      Quadratic(w, 0.0, A, B, C, D, E, F),
      Quadratic(-w, w, A, B, C, D, E, F),
      Quadratic(0.0, w, A, B, C, D, E, F),
      Quadratic(w, w, A, B, C, D, E, F),
      w
    ) == A
  ensures 
    HornDzDy(
      Quadratic(-w, -w, A, B, C, D, E, F),
      Quadratic(0.0, -w, A, B, C, D, E, F),
      Quadratic(w, -w, A, B, C, D, E, F),
      Quadratic(-w, 0.0, A, B, C, D, E, F),
      Quadratic(w, 0.0, A, B, C, D, E, F),
      Quadratic(-w, w, A, B, C, D, E, F),
      Quadratic(0.0, w, A, B, C, D, E, F),
      Quadratic(w, w, A, B, C, D, E, F),
      w
    ) == B
{
  // Expand all quadratic terms
  var a := Quadratic(-w, -w, A, B, C, D, E, F);
  var b := Quadratic(0.0, -w, A, B, C, D, E, F);
  var c := Quadratic(w, -w, A, B, C, D, E, F);
  var d := Quadratic(-w, 0.0, A, B, C, D, E, F);
  var f := Quadratic(w, 0.0, A, B, C, D, E, F);
  var g := Quadratic(-w, w, A, B, C, D, E, F);
  var h := Quadratic(0.0, w, A, B, C, D, E, F);
  var i := Quadratic(w, w, A, B, C, D, E, F);

  // Algebraic proof for DzDx
  calc {
    (c + 2.0*f + i) - (a + 2.0*d + g);
    ==
    (A*w + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w) +
     2.0*(A*w + B*0.0 + C + D*w*w + E*w*0.0 + F*0.0) +
     A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
    -
    (A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w) +
     2.0*(A*(-w) + B*0.0 + C + D*(-w)*(-w) + E*(-w)*0.0 + F*0.0) +
     A*(-w) + B*w + C + D*(-w)*(-w) + E*(-w)*w + F*w*w);
    ==
    (A*w - B*w + C + D*w*w - E*w*w + F*w*w +
     2.0*(A*w + C + D*w*w) +
     A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
    -
    (-A*w - B*w + C + D*w*w + E*w*w + F*w*w +
     2.0*(-A*w + C + D*w*w) +
     -A*w + B*w + C + D*w*w - E*w*w + F*w*w);
    ==
    (A*w - B*w + C + D*w*w - E*w*w + F*w*w +
     2.0*A*w + 2.0*C + 2.0*D*w*w +
     A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
    -
    (-A*w - B*w + C + D*w*w + E*w*w + F*w*w +
     -2.0*A*w + 2.0*C + 2.0*D*w*w +
     -A*w + B*w + C + D*w*w - E*w*w + F*w*w);
    ==
    ( (A*w + 2.0*A*w + A*w) + (-B*w + B*w) + (C + 2.0*C + C) + 
      (D*w*w + 2.0*D*w*w + D*w*w) + (-E*w*w + E*w*w) + (F*w*w + F*w*w) ) 
    -
    ( (-A*w -2.0*A*w -A*w) + (-B*w + B*w) + (C + 2.0*C + C) + 
      (D*w*w + 2.0*D*w*w + D*w*w) + (E*w*w - E*w*w) + (F*w*w + F*w*w) );
    ==
    (4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w) 
    -
    (-4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w);
    ==
    4.0*A*w - (-4.0*A*w);
    ==
    8.0*A*w;
  }
  // Final division step for DzDx
  assert HornDzDx(a, b, c, d, f, g, h, i, w) == (8.0 * A * w) / (8.0 * w) by {
    assert (8.0 * A * w) / (8.0 * w) == A;
  }

  // Algebraic proof for DzDy
  calc {
    (g + 2.0*h + i) - (a + 2.0*b + c);
    ==
    (A*(-w) + B*w + C + D*(-w)*(-w) + E*(-w)*w + F*w*w +
     2.0*(A*0.0 + B*w + C + D*0.0 + E*0.0*w + F*w*w) +
     A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
    -
    (A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w) +
     2.0*(A*0.0 + B*(-w) + C + D*0.0 + E*0.0*(-w) + F*(-w)*(-w)) +
     A*w + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w));
    ==
    (-A*w + B*w + C + D*w*w - E*w*w + F*w*w +
     2.0*(B*w + C + F*w*w) +
     A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
    -
    (-A*w - B*w + C + D*w*w + E*w*w + F*w*w +
     2.0*(-B*w + C + F*w*w) +
     A*w - B*w + C + D*w*w - E*w*w + F*w*w);
    ==
    ( (-A*w + A*w) + (B*w + 2.0*B*w + B*w) + (C + 2.0*C + C) + 
      (D*w*w + D*w*w) + (-E*w*w + E*w*w) + (F*w*w + 2.0*F*w*w + F*w*w) ) 
    -
    ( (-A*w + A*w) + (-B*w -2.0*B*w - B*w) + (C + 2.0*C + C) + 
      (D*w*w + D*w*w) + (E*w*w - E*w*w) + (F*w*w + 2.0*F*w*w + F*w*w) );
    ==
    (0.0 + 4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w) 
    -
    (0.0 - 4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w);
    ==
    4.0*B*w - (-4.0*B*w);
    ==
    8.0*B*w;
  }
  // Final division step for DzDy
  assert HornDzDy(a, b, c, d, f, g, h, i, w) == (8.0 * B * w) / (8.0 * w) by {
    assert (8.0 * B * w) / (8.0 * w) == B;
  }
}

lemma CubicRemainder(G: real, w: real)
  requires w != 0.0
  ensures 
    HornDzDx(
      Cubic(-w, -w, G),
      Cubic(0.0, -w, G),
      Cubic(w, -w, G),
      Cubic(-w, 0.0, G),
      Cubic(w, 0.0, G),
      Cubic(-w, w, G),
      Cubic(0.0, w, G),
      Cubic(w, w, G),
      w
    ) == G * w * w
{
  // Expand all cubic terms
  var a := Cubic(-w, -w, G);
  var b := Cubic(0.0, -w, G);
  var c := Cubic(w, -w, G);
  var d := Cubic(-w, 0.0, G);
  var f := Cubic(w, 0.0, G);
  var g := Cubic(-w, w, G);
  var h := Cubic(0.0, w, G);
  var i := Cubic(w, w, G);

  // Algebraic proof
  calc {
    (c + 2.0*f + i) - (a + 2.0*d + g);
    ==
    (G*(w*w*w) + 2.0*(G*(w*w*w)) + G*(w*w*w)) 
    - 
    (G*((-w)*(-w)*(-w)) + 2.0*(G*((-w)*(-w)*(-w))) + G*((-w)*(-w)*(-w)));
    ==
    (G*w*w*w + 2.0*G*w*w*w + G*w*w*w) 
    - 
    (G*(-w*w*w) + 2.0*G*(-w*w*w) + G*(-w*w*w));
    ==
    (4.0*G*w*w*w) 
    - 
    (-4.0*G*w*w*w);
    ==
    8.0*G*w*w*w;
  }
  // Final division step
  assert HornDzDx(a, b, c, d, f, g, h, i, w) == (8.0 * G * w * w * w) / (8.0 * w) by {
    assert (8.0 * G * w * w * w) / (8.0 * w) == G * w * w;
  }
}
