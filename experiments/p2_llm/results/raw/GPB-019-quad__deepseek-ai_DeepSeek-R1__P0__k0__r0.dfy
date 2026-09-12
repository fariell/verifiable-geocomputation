// Horn slope exactness on quadratic surfaces and cubic remainder
module P004_Consistency {
  // Quadratic surface function: z = A*x + B*y + C + D*x² + E*x*y + F*y²
  function quadratic(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
    := A*x + B*y + C + D*x*x + E*x*y + F*y*y

  // Cubic surface function: z = G*x³
  function cubic(G: real, x: real, y: real): real
    := G * x * x * x

  // Horn derivative DzDx computation
  function horn_dzdx(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
    requires w != 0.0
    := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0*w)

  // Horn derivative DzDy computation
  function horn_dzdy(a: real, b: real, c: real, d: real, f: real, g: real, h: real, i: real, w: real): real
    requires w != 0.0
    := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0*w)

  // Lemma: Horn derivatives are exact on quadratic surfaces
  lemma QuadraticExact(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w != 0.0
    ensures horn_dzdx(
      quadratic(A,B,C,D,E,F, -w,-w), quadratic(A,B,C,D,E,F, 0,-w), quadratic(A,B,C,D,E,F, w,-w),
      quadratic(A,B,C,D,E,F, -w, 0), quadratic(A,B,C,D,E,F, w, 0),
      quadratic(A,B,C,D,E,F, -w, w), quadratic(A,B,C,D,E,F, 0, w), quadratic(A,B,C,D,E,F, w, w),
      w) == A
    ensures horn_dzdy(
      quadratic(A,B,C,D,E,F, -w,-w), quadratic(A,B,C,D,E,F, 0,-w), quadratic(A,B,C,D,E,F, w,-w),
      quadratic(A,B,C,D,E,F, -w, 0), quadratic(A,B,C,D,E,F, w, 0),
      quadratic(A,B,C,D,E,F, -w, w), quadratic(A,B,C,D,E,F, 0, w), quadratic(A,B,C,D,E,F, w, w),
      w) == B
  {
    // Stencil point abbreviations
    var a := quadratic(A,B,C,D,E,F, -w,-w);
    var b := quadratic(A,B,C,D,E,F,  0,-w);
    var c := quadratic(A,B,C,D,E,F,  w,-w);
    var d := quadratic(A,B,C,D,E,F, -w, 0);
    var f := quadratic(A,B,C,D,E,F,  w, 0);
    var g := quadratic(A,B,C,D,E,F, -w, w);
    var h := quadratic(A,B,C,D,E,F,  0, w);
    var i := quadratic(A,B,C,D,E,F,  w, w);

    // DzDx numerator calculation
    calc {
      (c + 2.0*f + i) - (a + 2.0*d + g);
      == { 
        // Expand all quadratic terms
        assert a == A*(-w) + B*(-w) + C + D*(w*w) + E*(w*w) + F*(w*w);
        assert c == A*(w)  + B*(-w) + C + D*(w*w) + E*(-w*w) + F*(w*w);
        assert f == A*(w)  + B*(0)  + C + D*(w*w) + E*(0)    + F*(0);
        assert i == A*(w)  + B*(w)  + C + D*(w*w) + E*(w*w)  + F*(w*w);
        assert d == A*(-w) + B*(0)  + C + D*(w*w) + E*(0)    + F*(0);
        assert g == A*(-w) + B*(w)  + C + D*(w*w) + E*(-w*w) + F*(w*w);
      }
      // Simplify expression
      (A*w - B*w + C + D*w*w - E*w*w + F*w*w + 
        2.0*(A*w + C + D*w*w) + 
        A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
      - 
      (A*(-w) - B*w + C + D*w*w + E*w*w + F*w*w + 
        2.0*(A*(-w) + C + D*w*w) + 
        A*(-w) + B*w + C + D*w*w - E*w*w + F*w*w);
      == // Combine like terms
      8.0*A*w;
    }
    // Final division step for DzDx
    assert horn_dzdx(a,b,c,d,f,g,h,i,w) == (8.0*A*w) / (8.0*w) by {
      assert (8.0*A*w) / (8.0*w) == A by {
        assert 8.0*w != 0.0;  // Because w != 0
      }
    }

    // DzDy numerator calculation
    calc {
      (g + 2.0*h + i) - (a + 2.0*b + c);
      == {
        // Expand all quadratic terms
        assert g == A*(-w) + B*(w)  + C + D*(w*w) + E*(-w*w) + F*(w*w);
        assert h == A*(0)  + B*(w)  + C + D*(0)   + E*(0)    + F*(w*w);
        assert i == A*(w)  + B*(w)  + C + D*(w*w) + E*(w*w)  + F*(w*w);
        assert a == A*(-w) + B*(-w) + C + D*(w*w) + E*(w*w)  + F*(w*w);
        assert b == A*(0)  + B*(-w) + C + D*(0)   + E*(0)    + F*(w*w);
        assert c == A*(w)  + B*(-w) + C + D*(w*w) + E*(-w*w) + F*(w*w);
      }
      // Simplify expression
      (A*(-w) + B*w + C + D*w*w - E*w*w + F*w*w + 
        2.0*(B*w + C + F*w*w) + 
        A*w + B*w + C + D*w*w + E*w*w + F*w*w) 
      - 
      (A*(-w) - B*w + C + D*w*w + E*w*w + F*w*w + 
        2.0*(B*(-w) + C + F*w*w) + 
        A*w - B*w + C + D*w*w - E*w*w + F*w*w);
      == // Combine like terms
      8.0*B*w;
    }
    // Final division step for DzDy
    assert horn_dzdy(a,b,c,d,f,g,h,i,w) == (8.0*B*w) / (8.0*w) by {
      assert (8.0*B*w) / (8.0*w) == B by {
        assert 8.0*w != 0.0;  // Because w != 0
      }
    }
  }

  // Lemma: Horn derivative remainder on cubic surface z = G*x³
  lemma CubicRemainder(G: real, w: real)
    requires w != 0.0
    ensures horn_dzdx(
      cubic(G, -w,-w), cubic(G, 0,-w), cubic(G, w,-w),
      cubic(G, -w, 0), cubic(G, w, 0),
      cubic(G, -w, w), cubic(G, 0, w), cubic(G, w, w),
      w) == G * w * w
  {
    // Stencil point abbreviations
    var a := cubic(G, -w, -w);
    var b := cubic(G,  0, -w);
    var c := cubic(G,  w, -w);
    var d := cubic(G, -w,  0);
    var f := cubic(G,  w,  0);
    var g := cubic(G, -w,  w);
    var h := cubic(G,  0,  w);
    var i := cubic(G,  w,  w);

    // Compute DzDx numerator
    calc {
      (c + 2.0*f + i) - (a + 2.0*d + g);
      == {
        // Expand cubic terms
        assert a == G * (-w)*(-w)*(-w) == -G*w*w*w;
        assert c == G * (w)*(w)*(w) == G*w*w*w;
        assert f == G * (w)*(w)*(w) == G*w*w*w;
        assert i == G * (w)*(w)*(w) == G*w*w*w;
        assert d == G * (-w)*(-w)*(-w) == -G*w*w*w;
        assert g == G * (-w)*(-w)*(-w) == -G*w*w*w;
      }
      (G*w*w*w + 2.0*G*w*w*w + G*w*w*w) - ((-G*w*w*w) + 2.0*(-G*w*w*w) + (-G*w*w*w));
      ==
      (4.0*G*w*w*w) - (-4.0*G*w*w*w);
      ==
      8.0*G*w*w*w;
    }
    // Final division step
    assert horn_dzdx(a,b,c,d,f,g,h,i,w) == (8.0*G*w*w*w) / (8.0*w) by {
      assert (8.0*G*w*w*w) / (8.0*w) == G*w*w by {
        assert 8.0*w != 0.0;  // Because w != 0
        assert (8.0*G*w*w*w) / (8.0*w) == G*w*w*w / w == G*w*w;
      }
    }
  }
}
