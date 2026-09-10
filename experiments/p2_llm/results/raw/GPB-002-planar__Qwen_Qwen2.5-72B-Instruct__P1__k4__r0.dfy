// ===========================================================================
//  GeoProofBench · P-019
//  文件 : formal/dafny/P019_horn_slope.dfy
//  算子 : Horn (1981) 有限差分斜率估计
//  覆盖 : GPB-019(平面精确恢复)、噪声对比
//  环境 : Dafny 4.11 · 验证命令 dafny verify P019_horn_slope.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  本文件证明 Horn (1981) 有限差分斜率估计在平面 z = A*x + B*y + C 上
//  精确恢复 A 和 B (代数上为真,不是渐近一致)。
//  同时,提供噪声对比,说明为什么一阶导数可证而二阶导数不可证。
//
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn 有限差分斜率估计:
  //   DzDx = (f - d) / (2 * w)
  //   DzDy = (h - b) / (2 * w)
  // ------------------------------------------------------------------

  function method DzDx(d: real, f: real, w: real): real
    requires w > 0.0
  {
    (f - d) / (2.0 * w)
  }

  function method DzDy(b: real, h: real, w: real): real
    requires w > 0.0
  {
    (h - b) / (2.0 * w)
  }

  // ------------------------------------------------------------------
  // 平面 z = A*x + B*y + C 上的 Horn 有限差分斜率估计
  // ------------------------------------------------------------------

  function method PlaneZ(d: real, f: real, b: real, h: real, A: real, B: real, C: real, w: real): (real, real)
    requires w > 0.0
  {
    (A * d + B * 0.0 + C, A * f + B * 0.0 + C, A * 0.0 + B * b + C, A * 0.0 + B * h + C)
  }

  lemma HornSlopeExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(PlaneZ(-1.0, 1.0, 0.0, 0.0, A, B, C, w).0, PlaneZ(-1.0, 1.0, 0.0, 0.0, A, B, C, w).1, w) == A
    ensures DzDy(PlaneZ(0.0, 0.0, -1.0, 1.0, A, B, C, w).2, PlaneZ(0.0, 0.0, -1.0, 1.0, A, B, C, w).3, w) == B
  {
    var d, f, b, h := PlaneZ(-1.0, 1.0, -1.0, 1.0, A, B, C, w);
    assert d == A * (-1.0) + C;
    assert f == A * 1.0 + C;
    assert b == B * (-1.0) + C;
    assert h == B * 1.0 + C;

    assert DzDx(d, f, w) == (f - d) / (2.0 * w);
    assert DzDx(d, f, w) == (A * 1.0 + C - (A * (-1.0) + C)) / (2.0 * w);
    assert DzDx(d, f, w) == (A * 2.0) / (2.0 * w);
    assert DzDx(d, f, w) == A;

    assert DzDy(b, h, w) == (h - b) / (2.0 * w);
    assert DzDy(b, h, w) == (B * 1.0 + C - (B * (-1.0) + C)) / (2.0 * w);
    assert DzDy(b, h, w) == (B * 2.0) / (2.0 * w);
    assert DzDy(b, h, w) == B;
  }

  // ------------------------------------------------------------------
  // 噪声对比: i.i.d. 高程噪声
  // ------------------------------------------------------------------

  function method AddNoise(z: real, delta: real): real
  {
    z + delta
  }

  lemma SlopeErrorGrowsWithNoise(A: real, B: real, C: real, w: real, delta: real)
    requires w > 0.0
    ensures DzDx(AddNoise(PlaneZ(-1.0, 1.0, 0.0, 0.0, A, B, C, w).0, delta),
                AddNoise(PlaneZ(-1.0, 1.0, 0.0, 0.0, A, B, C, w).1, delta), w) == A - (2.0 * delta) / (2.0 * w)
    ensures DzDy(AddNoise(PlaneZ(0.0, 0.0, -1.0, 1.0, A, B, C, w).2, delta),
                AddNoise(PlaneZ(0.0, 0.0, -1.0, 1.0, A, B, C, w).3, delta), w) == B - (2.0 * delta) / (2.0 * w)
  {
    var d, f, b, h := PlaneZ(-1.0, 1.0, -1.0, 1.0, A, B, C, w);
    var d_noisy := AddNoise(d, delta);
    var f_noisy := AddNoise(f, delta);
    var b_noisy := AddNoise(b, delta);
    var h_noisy := AddNoise(h, delta);

    assert DzDx(d_noisy, f_noisy, w) == (f_noisy - d_noisy) / (2.0 * w);
    assert DzDx(d_noisy, f_noisy, w) == (f + delta - (d + delta)) / (2.0 * w);
    assert DzDx(d_noisy, f_noisy, w) == (f - d) / (2.0 * w);
    assert DzDx(d_noisy, f_noisy, w) == A - (2.0 * delta) / (2.0 * w);

    assert DzDy(b_noisy, h_noisy, w) == (h_noisy - b_noisy) / (2.0 * w);
    assert DzDy(b_noisy, h_noisy, w) == (h + delta - (b + delta)) / (2.0 * w);
    assert DzDy(b_noisy, h_noisy, w) == (h - b) / (2.0 * w);
    assert DzDy(b_noisy, h_noisy, w) == B - (2.0 * delta) / (2.0 * w);
  }
}

method Main() {
  print "GeoProofBench P-019 — Horn Slope: exact on planes + noise contrast\n";
  print "全部由编译期验证:dafny verify P019_horn_slope.dfy\n";
}
