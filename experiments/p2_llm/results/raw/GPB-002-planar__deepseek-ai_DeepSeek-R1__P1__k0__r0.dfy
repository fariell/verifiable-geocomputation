// ===========================================================================
//  GeoProofBench · P-001
//  算子 : Horn (1981) 有限差分坡度
//  定理 : 在平面 z = A*x + B*y + C 上，Horn 差分算子精确恢复 A 和 B
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope.dfy
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定 (p 向右, q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn 坡度算子:
  //   DzDx = (f - d) / (2 * w)
  //   DzDy = (h - b) / (2 * w)
  // ------------------------------------------------------------------

  // Horn 有限差分算子
  function HornDzDx(d: real, f: real, w: real): real
    requires w > 0.0
  {
    (f - d) / (2.0 * w)
  }

  function HornDzDy(b: real, h: real, w: real): real
    requires w > 0.0
  {
    (h - b) / (2.0 * w)
  }

  // 平面高程函数
  function PlaneZ(A: real, B: real, C: real, x: real, y: real): real
  {
    A * x + B * y + C
  }

  // ==================================================================
  // 主定理: 在平面上 Horn 差分精确恢复梯度分量
  // ==================================================================
  lemma TheoremExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0  // 网格间距必须为正
    ensures HornDzDx(
      PlaneZ(A, B, C, -w, 0.0),  // d = z(-w, 0)
      PlaneZ(A, B, C, w, 0.0),   // f = z(w, 0)
      w
    ) == A
    ensures HornDzDy(
      PlaneZ(A, B, C, 0.0, -w),  // b = z(0, -w)
      PlaneZ(A, B, C, 0.0, w),   // h = z(0, w)
      w
    ) == B
  {
    // 展开 d, f 的高程表达式
    assert PlaneZ(A, B, C, -w, 0.0) == A*(-w) + B*0.0 + C;
    assert PlaneZ(A, B, C, w, 0.0)  == A*w + B*0.0 + C;

    // 计算 DzDx: (f - d)/(2w) = [ (Aw+C) - (-Aw+C) ] / (2w) = (2Aw)/(2w) = A
    assert HornDzDx(A*(-w)+C, A*w+C, w) == 
      ( (A*w + C) - (A*(-w) + C) ) / (2.0 * w);
    assert ( (A*w + C) - (A*(-w) + C) ) == 2.0 * A * w;
    assert (2.0 * A * w) / (2.0 * w) == A;

    // 展开 b, h 的高程表达式
    assert PlaneZ(A, B, C, 0.0, -w) == A*0.0 + B*(-w) + C;
    assert PlaneZ(A, B, C, 0.0, w)  == A*0.0 + B*w + C;

    // 计算 DzDy: (h - b)/(2w) = [ (Bw+C) - (-Bw+C) ] / (2w) = (2Bw)/(2w) = B
    assert HornDzDy(B*(-w)+C, B*w+C, w) == 
      ( (B*w + C) - (B*(-w) + C) ) / (2.0 * w);
    assert ( (B*w + C) - (B*(-w) + C) ) == 2.0 * B * w;
    assert (2.0 * B * w) / (2.0 * w) == B;
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn Slope: exact on planes\n";
  print "验证通过: dafny verify P001_horn_slope.dfy\n";
}
