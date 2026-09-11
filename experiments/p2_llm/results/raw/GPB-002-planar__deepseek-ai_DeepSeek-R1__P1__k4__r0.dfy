// ===========================================================================
//  GeoProofBench · P-001
//  算子 : Horn (1981) 3x3 有限差分坡度
//  定理 : 在平面 z = A*x + B*y + C 上精确恢复 A,B
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_plane.dfy
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn 坡度算子:
  //   DzDx = (f - d) / (2 * w)
  //   DzDy = (h - b) / (2 * w)
  // ------------------------------------------------------------------

  // 平面高程函数
  function PlaneZ(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // Horn 水平梯度算子
  function HornDx(d: real, f: real, w: real): real
    requires w > 0.0
  {
    (f - d) / (2.0 * w)
  }

  function HornDy(b: real, h: real, w: real): real
    requires w > 0.0
  {
    (h - b) / (2.0 * w)
  }

  // ==================================================================
  // 主定理: 在平面上 Horn 算子精确恢复系数
  // ==================================================================
  lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDx(
      PlaneZ(-w, 0.0, A, B, C),  // d = z(-w, 0)
      PlaneZ( w, 0.0, A, B, C),   // f = z( w, 0)
      w
    ) == A
    ensures HornDy(
      PlaneZ(0.0, -w, A, B, C),  // b = z(0, -w)
      PlaneZ(0.0,  w, A, B, C),   // h = z(0,  w)
      w
    ) == B
  {
    // 展开平面函数定义
    // 自动验证代数恒等式
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes\n";
  print "验证命令: dafny verify P001_horn_plane.dfy\n";
}
