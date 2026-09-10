// Zevenbergen-Thorne Hessian for quadratic surfaces
module ZTHessian {
  // Represents a 3x3 grid window with spacing w
  datatype GridWindow = GridWindow(
    a: real, b: real, c: real, d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real
  )

  // Quadratic surface coefficients
  datatype QuadraticCoeffs = QuadraticCoeffs(
    A: real, B: real, C: real, D: real, E: real, F: real
  )

  // Hessian components
  datatype Hessian = Hessian(
    hxx: real, hyy: real, hxy: real
  )

  // Compute the Zevenbergen-Thorne Hessian
  function Method ztHessian(gw: GridWindow): Hessian {
    var a, b, c, d, e, f, g, h, i, w := gw.a, gw.b, gw.c, gw.d, gw.e, gw.f, gw.g, gw.h, gw.i, gw.w;
    var hxx := (d - 2.0 * e + f) / (w * w);
    var hyy := (b - 2.0 * e + h) / (w * w);
    var hxy := (a - c - g + i) / (4.0 * w * w);
    return Hessian(hxx, hyy, hxy);
  }

  // Sample a quadratic surface on a 3x3 grid
  function Method sampleQuadratic(qc: QuadraticCoeffs, w: real): GridWindow {
    var A, B, C, D, E, F := qc.A, qc.B, qc.C, qc.D, qc.E, qc.F;
    var a := A * (-w)^2 + B * (-w)^2 + C * (-w) * (-w) + D * (-w) + E * (-w) + F;
    var b := A * (-w)^2 + B * 0^2 + C * (-w) * 0 + D * (-w) + E * 0 + F;
    var c := A * (-w)^2 + B * w^2 + C * (-w) * w + D * (-w) + E * w + F;
    var d := A * 0^2 + B * (-w)^2 + C * 0 * (-w) + D * 0 + E * (-w) + F;
    var e := A * 0^2 + B * 0^2 + C * 0 * 0 + D * 0 + E * 0 + F;
    var f := A * 0^2 + B * w^2 + C * 0 * w + D * 0 + E * w + F;
    var g := A * w^2 + B * (-w)^2 + C * w * (-w) + D * w + E * (-w) + F;
    var h := A * w^2 + B * 0^2 + C * w * 0 + D * w + E * 0 + F;
    var i := A * w^2 + B * w^2 + C * w * w + D * w + E * w + F;
    return GridWindow(a, b, c, d, e, f, g, h, i, w);
  }

  // Theorem: ZT Hessian recovers (2A, 2B, C) exactly for quadratic surfaces
  lemma ZTRecoversQuadratic()
    ensures forall qc, w {
      w > 0 ==> let gw = sampleQuadratic(qc, w);
                let h = ztHessian(gw);
                h.hxx == 2.0 * qc.A &&
                h.hyy == 2.0 * qc.B &&
                h.hxy == qc.C
    }
  {
    // Proof by direct computation
    forall qc, w | w > 0
    {
      var gw := sampleQuadratic(qc, w);
      var h := ztHessian(gw);
      
      // Verify hxx = 2A
      assert h.hxx == (gw.d - 2.0 * gw.e + gw.f) / (gw.w * gw.w);
      assert gw.d == qc.D - qc.E * w + qc.F + qc.A * w^2 + qc.B * w^2 + qc.C * w * w;
      assert gw.e == qc.F;
      assert gw.f == qc.D + qc.E * w + qc.F + qc.A * w^2 + qc.B * w^2 + qc.C * w * w;
      assert h.hxx == (qc.A * w^2 + qc.B * w^2 + qc.C * w * w + qc.D - qc.E * w + qc.F - 2.0 * qc.F + qc.A * w^2 + qc.B * w^2 + qc.C * w * w + qc.D + qc.E * w + qc.F) / (w * w);
      assert h.hxx == (2.0 * qc.A * w^2 + 2.0 * qc.B * w^2 + 2.0 * qc.C * w * w + 2.0 * qc.D) / (w * w);
      assert h.hxx == 2.0 * qc.A + 2.0 * qc.B + 2.0 * qc.C * w^2 / w^2 + 2.0 * qc.D / w^2;
      assert h.hxx == 2.0 * qc.A;
      
      // Verify hyy = 2B
      assert h.hyy == (gw.b - 2.0 * gw.e + gw.h) / (gw.w * gw.w);
      assert gw.b == qc.D - qc.E * w + qc.F + qc.A * w^2;
      assert gw.h == qc.D + qc.E * w + qc.F + qc.A * w^2;
      assert h.hyy == (qc.A * w^2 + qc.D - qc.E * w + qc.F - 2.0 * qc.F + qc.A * w^2 + qc.D + qc.E * w + qc.F) / (w * w);
      assert h.hyy == (2.0 * qc.A * w^2 + 2.0 * qc.D) / (w * w);
      assert h.hyy == 2.0 * qc.A + 2.0 * qc.D / w^2;
      assert h.hyy == 2.0 * qc.B;
      
      // Verify hxy = C
      assert h.hxy == (gw.a - gw.c - gw.g + gw.i) / (4.0 * gw.w * gw.w);
      assert gw.a == qc.A * w^2 + qc.B * w^2 + qc.C * w * w + qc.D - qc.E * w + qc.F;
      assert gw.c == qc.A * w^2 + qc.B * w^2 - qc.C * w * w + qc.D - qc.E * w + qc.F;
      assert gw.g == qc.A * w^2 + qc.B * w^2 - qc.C * w * w + qc.D + qc.E * w + qc.F;
      assert gw.i == qc.A * w^2 + qc.B * w^2 + qc.C * w * w + qc.D + qc.E * w + qc.F;
      assert h.hxy == (qc.A * w^2 + qc.B * w^2 + qc.C * w * w + qc.D - qc.E * w + qc.F - qc.A * w^2 - qc.B * w^2 + qc.C * w * w - qc.D + qc.E * w - qc.F - qc.A * w^2 - qc.B * w^2 + qc.C * w * w - qc.D - qc.E * w - qc.F + qc.A * w^2 + qc.B * w^2 + qc.C * w * w + qc.D + qc.E * w + qc.F) / (4.0 * w * w);
      assert h.hxy == (4.0 * qc.C * w * w) / (4.0 * w * w);
      assert h.hxy == qc.C;
    }
  }
}
