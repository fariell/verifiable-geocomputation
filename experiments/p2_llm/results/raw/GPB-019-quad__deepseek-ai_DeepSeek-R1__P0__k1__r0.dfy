module P004 {
  function horn_dzdx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w)
  }

  function horn_dzdy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w)
  }

  function quadratic(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
  {
    A*x + B*y + C + D*x*x + E*x*y + F*y*y
  }

  lemma Lemma_ExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures 
      var a := quadratic(-w, -w, A, B, C, D, E, F);
      var b := quadratic(0, -w, A, B, C, D, E, F);
      var c := quadratic(w, -w, A, B, C, D, E, F);
      var d := quadratic(-w, 0, A, B, C, D, E, F);
      var f := quadratic(w, 0, A, B, C, D, E, F);
      var g := quadratic(-w, w, A, B, C, D, E, F);
      var h := quadratic(0, w, A, B, C, D, E, F);
      var i := quadratic(w, w, A, B, C, D, E, F);
      horn_dzdx(a, b, c, d, f, g, h, i, w) == A &&
      horn_dzdy(a, b, c, d, f, g, h, i, w) == B
  {
    var a_val := quadratic(-w, -w, A, B, C, D, E, F);
    var b_val := quadratic(0, -w, A, B, C, D, E, F);
    var c_val := quadratic(w, -w, A, B, C, D, E, F);
    var d_val := quadratic(-w, 0, A, B, C, D, E, F);
    var f_val := quadratic(w, 0, A, B, C, D, E, F);
    var g_val := quadratic(-w, w, A, B, C, D, E, F);
    var h_val := quadratic(0, w, A, B, C, D, E, F);
    var i_val := quadratic(w, w, A, B, C, D, E, F);

    calc {
      (c_val + 2.0*f_val + i_val) - (a_val + 2.0*d_val + g_val);
      ==
      (4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w) - (-4.0*A*w + 4.0*C + 4.0*D*w*w + 2.0*F*w*w);
      ==
      8.0*A*w;
    }

    calc {
      (g_val + 2.0*h_val + i_val) - (a_val + 2.0*b_val + c_val);
      ==
      (4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w) - (-4.0*B*w + 4.0*C + 2.0*D*w*w + 4.0*F*w*w);
      ==
      8.0*B*w;
    }
  }

  function cubic_x(x: real, G: real): real
  {
    G * x * x * x
  }

  lemma Lemma_CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures 
      var a := cubic_x(-w, G);
      var b := cubic_x(0, G);
      var c := cubic_x(w, G);
      var d := cubic_x(-w, G);
      var f := cubic_x(w, G);
      var g := cubic_x(-w, G);
      var h := cubic_x(0, G);
      var i := cubic_x(w, G);
      horn_dzdx(a, b, c, d, f, g, h, i, w) == G * w * w &&
      horn_dzdy(a, b, c, d, f, g, h, i, w) == 0.0
  {
    calc {
      (c + 2.0*f + i) - (a + 2.0*d + g);
      ==
      (4.0*G*w*w*w) - (-4.0*G*w*w*w);
      ==
      8.0*G*w*w*w;
    }

    calc {
      (g + 2.0*h + i) - (a + 2.0*b + c);
      ==
      0.0 - 0.0;
      ==
      0.0;
    }
  }
}
