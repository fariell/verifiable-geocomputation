// ===========================================================================
//  GeoProofBench · P-003
//  算子 : Zevenbergen-Thorne 离散 Hessian
//  覆盖 : GPB-003(二次曲面上的精确性)
//  环境 : Dafny 4.11
// ===========================================================================
//
//  科学动机
//  ---------
//  曲率算子对噪声敏感(Phase 1 实测 corr ≈ 0.157),但代数结构上,
//  Zevenbergen-Thorne Hessian 在二次曲面上应精确恢复系数 (2A, 2B, C)。
//  本证明验证该代数性质,为后续误差分析建立基准。
//
// ===========================================================================

module ZTHessian {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //
  //     a(-w,-w)   b( 0,-w)   c( w,-w)
  //     d(-w, 0)     e(0,0)   f( w, 0)
  //     g(-w, w)   h( 0, w)   i( w, w)
  // ------------------------------------------------------------------

  // ---- 二次曲面函数 ----
  function Quadratic(x: real, y: real, 
                     A: real, B: real, C: real, 
                     D: real, E: real, F: real): real
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  // ---- ZT Hessian 分量 ----
  function ZT_Hxx(a: real, b: real, c: real, 
                  d: real, e: real, f: real,
                  g: real, h: real, i: real, 
                  w: real): real
    requires w > 0.0
  {
    (d - 2.0*e + f) / (w*w)
  }

  function ZT_Hyy(a: real, b: real, c: real, 
                  d: real, e: real, f: real,
                  g: real, h: real, i: real, 
                  w: real): real
    requires w > 0.0
  {
    (b - 2.0*e + h) / (w*w)
  }

  function ZT_Hxy(a: real, b: real, c: real, 
                  d: real, e: real, f: real,
                  g: real, h: real, i: real, 
                  w: real): real
    requires w > 0.0
  {
    (a - c - g + i) / (4.0 * w * w)
  }

  // ==================================================================
  // 核心定理:在二次曲面上 ZT Hessian 精确恢复 (2A, 2B, C)
  // ==================================================================
  lemma ExactOnQuadratic(A: real, B: real, C: real,
                         D: real, E: real, F: real,
                         w: real)
    requires w > 0.0
    ensures 
      // 采样点定义
      let a := Quadratic(-w, -w, A, B, C, D, E, F) in
      let b := Quadratic( 0, -w, A, B, C, D, E, F) in
      let c := Quadratic( w, -w, A, B, C, D, E, F) in
      let d := Quadratic(-w,  0, A, B, C, D, E, F) in
      let e := Quadratic( 0,  0, A, B, C, D, E, F) in
      let f := Quadratic( w,  0, A, B, C, D, E, F) in
      let g := Quadratic(-w,  w, A, B, C, D, E, F) in
      let h := Quadratic( 0,  w, A, B, C, D, E, F) in
      let i := Quadratic( w,  w, A, B, C, D, E, F) in
      // 验证 Hessian 分量
      ZT_Hxx(a, b, c, d, e, f, g, h, i, w) == 2.0 * A &&
      ZT_Hyy(a, b, c, d, e, f, g, h, i, w) == 2.0 * B &&
      ZT_Hxy(a, b, c, d, e, f, g, h, i, w) == C
  {
    // 展开二次曲面采样点
    calc {
      Quadratic(-w, -w, A, B, C, D, E, F);
      == { 
        Quadratic(-w, -w, A, B, C, D, E, F) 
          = A*(-w)*(-w) + B*(-w)*(-w) + C*(-w)*(-w) + D*(-w) + E*(-w) + F;
      }
      A*w*w + B*w*w + C*w*w - D*w - E*w + F;
    }
    calc {
      Quadratic(0, -w, A, B, C, D, E, F);
      == 
      A*0 + B*(-w)*(-w) + C*0*(-w) + D*0 + E*(-w) + F;
      == 
      B*w*w - E*w + F;
    }
    calc {
      Quadratic(w, -w, A, B, C, D, E, F);
      == 
      A*w*w + B*w*w + C*w*(-w) + D*w + E*(-w) + F;
      == 
      A*w*w + B*w*w - C*w*w + D*w - E*w + F;
    }
    calc {
      Quadratic(-w, 0, A, B, C, D, E, F);
      == 
      A*(-w)*(-w) + B*0 + C*(-w)*0 + D*(-w) + E*0 + F;
      == 
      A*w*w - D*w + F;
    }
    calc {
      Quadratic(0, 0, A, B, C, D, E, F);
      == 
      F;
    }
    calc {
      Quadratic(w, 0, A, B, C, D, E, F);
      == 
      A*w*w + D*w + F;
    }
    calc {
      Quadratic(-w, w, A, B, C, D, E, F);
      == 
      A*(-w)*(-w) + B*w*w + C*(-w)*w + D*(-w) + E*w + F;
      == 
      A*w*w + B*w*w - C*w*w - D*w + E*w + F;
    }
    calc {
      Quadratic(0, w, A, B, C, D, E, F);
      == 
      B*w*w + E*w + F;
    }
    calc {
      Quadratic(w, w, A, B, C, D, E, F);
      == 
      A*w*w + B*w*w + C*w*w + D*w + E*w + F;
    }

    // 验证 Hxx = (d - 2e + f)/w² = 2A
    calc {
      ZT_Hxx(a, b, c, d, e, f, g, h, i, w);
      == 
      (d - 2.0*e + f) / (w*w);
      == 
      ((A*w*w - D*w + F) - 2.0*F + (A*w*w + D*w + F)) / (w*w);
      == 
      (2.0*A*w*w) / (w*w);
      == 
      2.0 * A;
    }

    // 验证 Hyy = (b - 2e + h)/w² = 2B
    calc {
      ZT_Hyy(a, b, c, d, e, f, g, h, i, w);
      == 
      (b - 2.0*e + h) / (w*w);
      == 
      ((B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F)) / (w*w);
      == 
      (2.0*B*w*w) / (w*w);
      == 
      2.0 * B;
    }

    // 验证 Hxy = (a - c - g + i)/(4w²) = C
    calc {
      ZT_Hxy(a, b, c, d, e, f, g, h, i, w);
      == 
      (a - c - g + i) / (4.0 * w * w);
      == 
      ( (A*w*w + B*w*w + C*w*w - D*w - E*w + F) 
        - (A*w*w + B*w*w - C*w*w + D*w - E*w + F)
        - (A*w*w + B*w*w - C*w*w - D*w + E*w + F)
        + (A*w*w + B*w*w + C*w*w + D*w + E*w + F)
      ) / (4.0 * w * w);
      == 
      (4.0 * C * w * w) / (4.0 * w * w);
      == 
      C;
    }
  }
}

method Main() {
  print "GeoProofBench P-003 — Zevenbergen-Thorne Hessian 在二次曲面上的精确性\n";
  print "由编译期验证: dafny verify P003_curvature.dfy\n";
}
