// ===========================================================================
//  GeoProofBench · P-001
//  算子 : Horn (1981) 有限差分坡度算子
//  定理 : 在平面 z = A*x + B*y + C 上，Horn 差分精确恢复 A 和 B
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope.dfy
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定 (与 P-003 相同)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 坡度算子:
  //   DzDx = (f - d) / (2 * w)
  //   DzDy = (h - b) / (2 * w)
  // ------------------------------------------------------------------

  // 平面函数在网格点上的取值
  function Qb(A: real, B: real, C: real, w: real): real  // 上中 (0, -w)
    { A*0.0 + B*(-w) + C }
  function Qd(A: real, B: real, C: real, w: real): real  // 左中 (-w, 0)
    { A*(-w) + B*0.0 + C }
  function Qf(A: real, B: real, C: real, w: real): real  // 右中 (w, 0)
    { A*(w) + B*0.0 + C }
  function Qh(A: real, B: real, C: real, w: real): real  // 下中 (0, w)
    { A*0.0 + B*(w) + C }

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

  // ==================================================================
  // 主定理: 在平面上 Horn 差分精确恢复梯度分量
  // ==================================================================
  theorem Theorem_HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDzDx(Qd(A,B,C,w), Qf(A,B,C,w), w) == A
    ensures HornDzDy(Qb(A,B,C,w), Qh(A,B,C,w), w) == B
  {
    // DzDx 计算展开:
    //   ( [A*w + C] - [ -A*w + C ] ) / (2*w)
    // = (2*A*w) / (2*w) = A
    assert Qf(A,B,C,w) - Qd(A,B,C,w) == 2.0 * A * w;

    // DzDy 计算展开:
    //   ( [B*w + C] - [ -B*w + C ] ) / (2*w)
    // = (2*B*w) / (2*w) = B
    assert Qh(A,B,C,w) - Qb(A,B,C,w) == 2.0 * B * w;
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn Slope: exact on planes\n";
  print "验证通过: dafny verify P001_horn_slope.dfy\n";
}
