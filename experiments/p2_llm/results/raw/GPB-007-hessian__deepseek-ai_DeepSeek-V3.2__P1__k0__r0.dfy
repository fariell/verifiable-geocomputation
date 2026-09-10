// ===========================================================================
//  GeoProofBench · P-003
//  文件 : formal/dafny/P003_curvature.dfy
//  算子 : Zevenbergen–Thorne (1987) 3x3 离散 Hessian
//  覆盖 : GPB-005 (二次曲面精确性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P003_curvature.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  Phase 1 实验显示二阶曲率算子在实测 DEM 上相关性仅 0.157,与一阶算子
//  (corr > 0.9999) 形成刺眼对比。本文件回答:在**精确算术**下,
//  Zevenbergen–Thorne 离散 Hessian 对任意二次曲面是精确的。
//
//  这意味着实测的低相关性不是算子定义错误,而是二阶差分对高程噪声的
//  放大效应(O(σ/w²))。本证明划清了"定义正确性"与"数值稳定性"的边界,
//  为后续的误差模型验证(GPB-020)提供代数基础。
//
// ===========================================================================

module ZTHessian {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(行偏移向下为正)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  //  格网间距 w > 0,中心点 e 对应坐标 (0,0)。
  // ------------------------------------------------------------------

  // ---- 离散二阶偏导(未除间距平方) ----
  function NumHxx(d: real, e: real, f: real): real
  { d - 2.0*e + f }

  function NumHyy(b: real, e: real, h: real): real
  { b - 2.0*e + h }

  function NumHxy(a: real, c: real, g: real, i: real): real
  { a - c - g + i }

  // ---- 完整 Hessian 分量(带单位) ----
  function Hxx(a: real, b: real, c: real, d: real, e: real,
               f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumHxx(d, e, f) / (w*w) }

  function Hyy(a: real, b: real, c: real, d: real, e: real,
               f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumHyy(b, e, h) / (w*w) }

  function Hxy(a: real, b: real, c: real, d: real, e: real,
               f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumHxy(a, c, g, i) / (4.0 * w * w) }

  // ------------------------------------------------------------------
  // 二次曲面 z = A x² + B y² + C x y + D x + E y + F
  // 在 3x3 窗口上的采样值
  // ------------------------------------------------------------------
  function QuadraticSample(A: real, B: real, C: real,
                           D: real, E: real, F: real,
                           w: real, di: int, dj: int): real
    requires w > 0.0
    requires -1 <= di <= 1 && -1 <= dj <= 1
  {
    let x := di * w;
    let y := dj * w;
    A * x * x + B * y * y + C * x * y + D * x + E * y + F
  }

  // ------------------------------------------------------------------
  // 主定理: ZT Hessian 在二次曲面上精确恢复 (2A, 2B, C)
  // ------------------------------------------------------------------
  lemma ExactOnQuadratic(A: real, B: real, C: real,
                         D: real, E: real, F: real,
                         w: real)
    requires w > 0.0
    ensures
      // 采样整个 3x3 窗口
      let a := QuadraticSample(A, B, C, D, E, F, w, -1, -1);
      let b := QuadraticSample(A, B, C, D, E, F, w,  0, -1);
      let c := QuadraticSample(A, B, C, D, E, F, w,  1, -1);
      let d := QuadraticSample(A, B, C, D, E, F, w, -1,  0);
      let e := QuadraticSample(A, B, C, D, E, F, w,  0,  0);
      let f := QuadraticSample(A, B, C, D, E, F, w,  1,  0);
      let g := QuadraticSample(A, B, C, D, E, F, w, -1,  1);
      let h := QuadraticSample(A, B, C, D, E, F, w,  0,  1);
      let i := QuadraticSample(A, B, C, D, E, F, w,  1,  1);
      in
        Hxx(a, b, c, d, e, f, g, h, i, w) == 2.0 * A &&
        Hyy(a, b, c, d, e, f, g, h, i, w) == 2.0 * B &&
        Hxy(a, b, c, d, e, f, g, h, i, w) == C
  {
    // 展开采样值
    var a := QuadraticSample(A, B, C, D, E, F, w, -1, -1);
    var b := QuadraticSample(A, B, C, D, E, F, w,  0, -1);
    var c := QuadraticSample(A, B, C, D, E, F, w,  1, -1);
    var d := QuadraticSample(A, B, C, D, E, F, w, -1,  0);
    var e := QuadraticSample(A, B, C, D, E, F, w,  0,  0);
    var f := QuadraticSample(A, B, C, D, E, F, w,  1,  0);
    var g := QuadraticSample(A, B, C, D, E, F, w, -1,  1);
    var h := QuadraticSample(A, B, C, D, E, F, w,  0,  1);
    var i := QuadraticSample(A, B, C, D, E, F, w,  1,  1);

    // 1) Hxx = 2A
    calc {
      NumHxx(d, e, f);
      ==  // 展开 d, e, f
      (A * ( -w)*(-w) + B * 0*0 + C * ( -w)*0 + D * ( -w) + E * 0 + F) -
      2.0 * (A * 0*0 + B * 0*0 + C * 0*0 + D * 0 + E * 0 + F) +
      (A * (  w)*( w) + B * 0*0 + C * (  w)*0 + D * (  w) + E * 0 + F);
      ==  // 化简
      (A * w*w - D * w + F) - 2.0 * F + (A * w*w + D * w + F);
      ==
      2.0 * A * w*w;
    }
    assert Hxx(a, b, c, d, e, f, g, h, i, w) == 2.0 * A;

    // 2) Hyy = 2B
    calc {
      NumHyy(b, e, h);
      ==
      (A * 0*0 + B * ( -w)*( -w) + C * 0*( -w) + D * 0 + E * ( -w) + F) -
      2.0 * (A * 0*0 + B * 0*0 + C * 0*0 + D * 0 + E * 0 + F) +
      (A * 0*0 + B * (  w)*(  w) + C * 0*(  w) + D * 0 + E * (  w) + F);
      ==
      (B * w*w - E * w + F) - 2.0 * F + (B * w*w + E * w + F);
      ==
      2.0 * B * w*w;
    }
    assert Hyy(a, b, c, d, e, f, g, h, i, w) == 2.0 * B;

    // 3) Hxy = C
    calc {
      NumHxy(a, c, g, i);
      ==
      (A * ( -w)*( -w) + B * ( -w)*( -w) + C * ( -w)*( -w) + D * ( -w) + E * ( -w) + F) -
      (A * (  w)*( -w) + B * ( -w)*( -w) + C * (  w)*( -w) + D * (  w) + E * ( -w) + F) -
      (A * ( -w)*(  w) + B * (  w)*(  w) + C * ( -w)*(  w) + D * ( -w) + E * (  w) + F) +
      (A * (  w)*(  w) + B * (  w)*(  w) + C * (  w)*(  w) + D * (  w) + E * (  w) + F);
      ==  // 按项收集 C 的系数
      let term1 := C * ( (-w)*(-w) );
      let term2 := C * (   w *(-w) );
      let term3 := C * ( (-w)*  w  );
      let term4 := C * (   w *  w  );
      in
        term1 - term2 - term3 + term4;
      ==
      C * ( w*w - (-w*w) - (-w*w) + w*w );
      ==
      C * (4.0 * w*w);
    }
    assert Hxy(a, b, c, d, e, f, g, h, i, w) == C;
  }

  // ------------------------------------------------------------------
  // 推论: 常数项 F 与线性项 D, E 不影响 Hessian
  // ------------------------------------------------------------------
  lemma HessianIgnoresLinearConstant(A: real, B: real, C: real,
                                     D1: real, E1: real, F1: real,
                                     D2: real, E2: real, F2: real,
                                     w: real)
    requires w > 0.0
    ensures
      let a1 := QuadraticSample(A, B, C, D1, E1, F1, w, -1, -1);
      let b1 := QuadraticSample(A, B, C, D1, E1, F1, w,  0, -1);
      let c1 := QuadraticSample(A, B, C, D1, E1, F1, w,  1, -1);
      let d1 := QuadraticSample(A, B, C, D1, E1, F1, w, -1,  0);
      let e1 := QuadraticSample(A, B, C, D1, E1, F1, w,  0,  0);
      let f1 := QuadraticSample(A, B, C, D1, E1, F1, w,  1,  0);
      let g1 := QuadraticSample(A, B, C, D1, E1, F1, w, -1,  1);
      let h1 := QuadraticSample(A, B, C, D1, E1, F1, w,  0,  1);
      let i1 := QuadraticSample(A, B, C, D1, E1, F1, w,  1,  1);

      let a2 := QuadraticSample(A, B, C, D2, E2, F2, w, -1, -1);
      let b2 := QuadraticSample(A, B, C, D2, E2, F2, w,  0, -1);
      let c2 := QuadraticSample(A, B, C, D2, E2, F2, w,  1, -1);
      let d2 := QuadraticSample(A, B, C, D2, E2, F2, w, -1,  0);
      let e2 := QuadraticSample(A, B, C, D2, E2, F2, w,  0,  0);
      let f2 := QuadraticSample(A, B, C, D2, E2, F2, w,  1,  0);
      let g2 := QuadraticSample(A, B, C, D2, E2, F2, w, -1,  1);
      let h2 := QuadraticSample(A, B, C, D2, E2, F2, w,  0,  1);
      let i2 := QuadraticSample(A, B, C, D2, E2, F2, w,  1,  1);
      in
        Hxx(a1,b1,c1,d1,e1,f1,g1,h1,i1,w) == Hxx(a2,b2,c2,d2,e2,f2,g2,h2,i2,w) &&
        Hyy(a1,b1,c1,d1,e1,f1,g1,h1,i1,w) == Hyy(a2,b2,c2,d2,e2,f2,g2,h2,i2,w) &&
        Hxy(a1,b1,c1,d1,e1,f1,g1,h1,i1,w) == Hxy(a2,b2,c2,d2,e2,f2,g2,h2,i2,w)
  {
    // 由主定理,两者都等于 (2A, 2B, C)
    ExactOnQuadratic(A, B, C, D1, E1, F1, w);
    ExactOnQuadratic(A, B, C, D2, E2, F2, w);
  }
}

method Main() {
  print "GeoProofBench P-003 — Zevenbergen–Thorne Hessian 二次精确性\n";
  print "验证命令: dafny verify P003_curvature.dfy\n";
}
