lemma ZevenbergenThorneHessian(w: real, A: real, B: real, C: real, D: real, E: real, F: real)
  requires w > 0.0
  ensures 
    // Define quadratic surface function
    var z := (x: real, y: real) => A*x*x + B*y*y + C*x*y + D*x + E*y + F;
    
    // Sample 3x3 grid points
    var a := z(-w, -w);
    var b := z(0.0, -w);
    var c := z(w, -w);
    var d := z(-w, 0.0);
    var e := z(0.0, 0.0);
    var f := z(w, 0.0);
    var g := z(-w, w);
    var h := z(0.0, w);
    var i := z(w, w);
    
    // Compute ZT Hessian components
    var hxx := (d - 2.0*e + f) / (w*w);
    var hyy := (b - 2.0*e + h) / (w*w);
    var hxy := (a - c - g + i) / (4.0*w*w);
    
    // Verify exact recovery of coefficients
    hxx == 2.0*A && hyy == 2.0*B && hxy == C
{
  // Expand all grid point evaluations
  calc {
    a;
    == A*(-w)*(-w) + B*(-w)*(-w) + C*(-w)*(-w) + D*(-w) + E*(-w) + F;
    == A*w*w + B*w*w + C*w*w - D*w - E*w + F;
  }
  calc {
    b;
    == A*0.0*0.0 + B*(-w)*(-w) + C*0.0*(-w) + D*0.0 + E*(-w) + F;
    == B*w*w - E*w + F;
  }
  calc {
    c;
    == A*w*w + B*(-w)*(-w) + C*w*(-w) + D*w + E*(-w) + F;
    == A*w*w + B*w*w - C*w*w + D*w - E*w + F;
  }
  calc {
    d;
    == A*(-w)*(-w) + B*0.0*0.0 + C*(-w)*0.0 + D*(-w) + E*0.0 + F;
    == A*w*w - D*w + F;
  }
  calc {
    e;
    == A*0.0*0.0 + B*0.0*0.0 + C*0.0*0.0 + D*0.0 + E*0.0 + F;
    == F;
  }
  calc {
    f;
    == A*w*w + B*0.0*0.0 + C*w*0.0 + D*w + E*0.0 + F;
    == A*w*w + D*w + F;
  }
  calc {
    g;
    == A*(-w)*(-w) + B*w*w + C*(-w)*w + D*(-w) + E*w + F;
    == A*w*w + B*w*w - C*w*w - D*w + E*w + F;
  }
  calc {
    h;
    == A*0.0*0.0 + B*w*w + C*0.0*w + D*0.0 + E*w + F;
    == B*w*w + E*w + F;
  }
  calc {
    i;
    == A*w*w + B*w*w + C*w*w + D*w + E*w + F;
    == A*w*w + B*w*w + C*w*w + D*w + E*w + F;
  }

  // Verify hxx = 2A
  calc {
    hxx;
    == (d - 2.0*e + f) / (w*w);
    == ( (A*w*w - D*w + F) - 2.0*F + (A*w*w + D*w + F) ) / (w*w);
    == (A*w*w - D*w + F - 2F + A*w*w + D*w + F) / (w*w);
    == (2.0*A*w*w) / (w*w);
    == 2.0*A;
  }

  // Verify hyy = 2B
  calc {
    hyy;
    == (b - 2.0*e + h) / (w*w);
    == ( (B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F) ) / (w*w);
    == (B*w*w - E*w + F - 2F + B*w*w + E*w + F) / (w*w);
    == (2.0*B*w*w) / (w*w);
    == 2.0*B;
  }

  // Verify hxy = C
  calc {
    hxy;
    == (a - c - g + i) / (4.0*w*w);
    == ( (A*w*w + B*w*w + C*w*w - D*w - E*w + F) 
        - (A*w*w + B*w*w - C*w*w + D*w - E*w + F)
        - (A*w*w + B*w*w - C*w*w - D*w + E*w + F)
        + (A*w*w + B*w*w + C*w*w + D*w + E*w + F) ) / (4.0*w*w);
    == (A*w*w + B*w*w + C*w*w - D*w - E*w + F
        - A*w*w - B*w*w + C*w*w - D*w + E*w - F
        - A*w*w - B*w*w + C*w*w + D*w - E*w - F
        + A*w*w + B*w*w + C*w*w + D*w + E*w + F) / (4.0*w*w);
    == ( (C*w*w + C*w*w + C*w*w + C*w*w) 
        + (-D*w - D*w + D*w + D*w) 
        + (-E*w + E*w - E*w + E*w) 
        + (F - F - F + F) ) / (4.0*w*w);
    == (4.0*C*w*w) / (4.0*w*w);
    == C;
  }
}
