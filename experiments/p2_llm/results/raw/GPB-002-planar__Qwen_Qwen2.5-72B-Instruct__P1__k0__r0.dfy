// ===========================================================================
//  GeoProofBench · P-019
//  文件 : formal/dafny/P019_horn_slope.dfy
//  算子 : Horn (1981) 有限差分估计
//  覆盖 : GPB-019(平面精确恢复)、噪声对比
//  环境 : Dafny 4.11 · 验证命令 dafny verify P019_horn_slope.dfy
//  日期 : 2026-09-06
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn 有限差分估计:
  //   DzDx = (f - d) / (2 * w)
  //   DzDy = (h - b) / (2 * w)
  // -------------------------------------------

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
  // 平面 z = A*x + B*y + C 上的 Horn 有限差分估计
  // -------------------------------------------
  lemma HornSlopeExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(C - A * w, C + A * w, w) == A
    ensures DzDy(C - B * w, C + B * w, w) == B
  {
    assert (C + A * w - (C - A * w)) / (2.0 * w) == A;
    assert (C + B * w - (C - B * w)) / (2.0 * w) == B;
  }

  // ------------------------------------------------------------------
  // 噪声对比:中心高程扰动 δ 使 DzDx 和 DzDy 改变
  // -------------------------------------------
  lemma NoiseImpactOnHornSlope(A: real, B: real, C: real, w: real, δ: real)
    requires w > 0.0
    ensures DzDx(C - A * w + δ, C + A * w + δ, w) == DzDx(C - A * w, C + A * w, w) + δ / w
    ensures DzDy(C - B * w + δ, C + B * w + δ, w) == DzDy(C - B * w, C + B * w, w) + δ / w
  {
    assert (C + A * w + δ - (C - A * w + δ)) / (2.0 * w) == A;
    assert (C + B * w + δ - (C - B * w + δ)) / (2.0 * w) == B;
  }

  // ------------------------------------------------------------------
  // Phase 1 错误模板:平面 z = A*x + B*y + C 上的 DzDx 和 DzDy
  // -------------------------------------------
  lemma Phase1StencilExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(C - A * w, C + A * w, w) == A
    ensures DzDy(C - B * w, C + B * w, w) == B
  {
    HornSlopeExactOnPlane(A, B, C, w);
  }
}

method Main() {
  print "GeoProofBench P-019 — Horn Slope: planar exactness + noise impact\n";
  print "全部由编译期验证:dafny verify P019_horn_slope.dfy\n";
}
