module P003_curvature {
  function quad(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  lemma ZTHessianExact(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures 
      let a00 := quad(A,B,C,D,E,F, -w, -w) in
      let a01 := quad(A,B,C,D,E,F,  0.0, -w) in
      let a02 := quad(A,B,C,D,E,F,  w, -w) in
      let a10 := quad(A,B,C,D,E,F, -w,  0.0) in
      let a11 := quad(A,B,C,D,E,F,  0.0,  0.0) in
      let a12 := quad(A,B,C,D,E,F,  w,  0.0) in
      let a20 := quad(A,B,C,D,E,F, -w,  w) in
      let a21 := quad(A,B,C,D,E,F,  0.0,  w) in
      let a22 := quad(A,B,C,D,E,F,  w,  w) in
      let hxx := (a10 - 2.0*a11 + a12) / (w*w) in
      let hyy := (a01 - 2.0*a11 + a21) / (w*w) in
      let hxy := (a00 - a02 - a20 + a22) / (4.0 * w * w) in
      hxx == 2.0 * A && hyy == 2.0 * B && hxy == C
  {
    // Expansion of hxx
    calc {
      (a10 - 2.0*a11 + a12) / (w*w);
      ==
      (quad(A,B,C,D,E,F, -w, 0.0) - 2.0*quad(A,B,C,D,E,F, 0.0, 0.0) + quad(A,B,C,D,E,F, w, 0.0)) / (w*w);
      ==
      ((A*w*w - D*w + F) - 2.0*F + (A*w*w + D*w + F)) / (w*w);
      ==
      (2.0*A*w*w) / (w*w);
      ==
      2.0*A;
    }

    // Expansion of hyy
    calc {
      (a01 - 2.0*a11 + a21) / (w*w);
      ==
      (quad(A,B,C,D,E,F, 0.0, -w) - 2.0*quad(A,B,C,D,E,F, 0.0, 0.0) + quad(A,B,C,D,E,F, 0.0, w)) / (w*w);
      ==
      ((B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F)) / (w*w);
      ==
      (2.0*B*w*w) / (w*w);
      ==
      2.0*B;
    }

    // Expansion of hxy numerator
    calc {
      a00 - a02 - a20 + a22;
      ==
      quad(A,B,C,D,E,F, -w, -w) - quad(A,B,C,D,E,F, w, -w) - quad(A,B,C,D,E,F, -w, w) + quad(A,B,C,D,E,F, w, w);
      ==
      (A*w*w + B*w*w + C*w*w - D*w - E*w + F) 
      - (A*w*w + B*w*w - C*w*w + D*w - E*w + F) 
      - (A*w*w + B*w*w - C*w*w - D*w + E*w + F) 
      + (A*w*w + B*w*w + C*w*w + D*w + E*w + F);
      ==
      4.0*C*w*w;
    }
    // Final hxy result
    assert (a00 - a02 - a20 + a22) / (4.0 * w * w) == 4.0*C*w*w / (4.0 * w * w) by {
      calc {
        4.0*C*w*w / (4.0 * w * w);
        ==
        C * (4.0 * w * w) / (4.0 * w * w);
        ==
        C;
      }
    }
  }
}
