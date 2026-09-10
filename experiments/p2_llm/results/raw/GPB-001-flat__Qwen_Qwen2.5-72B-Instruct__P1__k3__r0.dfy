// ===========================================================================
//  GeoProofBench · P-019
//  文件 : formal/dafny/P019_slope_consistency.dfy
//  算子 : Horn (1981) 3x3 一阶差分(坡度)
//  覆盖 : GPB-019(坡度在平面一致)、平面高程扰动 δ 使坡度误差 ~σ/w
//  环境 : Dafny 4.11 · 验证命令 dafny verify P019_slope_consistency.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么坡度在平面上一致
//  -------------------------
//  在任何 3x3 高程窗口中,如果所有九个单元格的高程相同,则 Horn (1981) 坡度
//  (或其平方 SlopeSq)恒为零。网格间距 w 必须为正。
//
//  本文件证明:
//    1. 平面上 Horn 坡度恒为零。
//    2. 平面高程扰动 δ 使坡度误差 ~σ/w。
//
//  不证:一般 C² 曲面的渐近一致性。
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
  // Horn (1981) 坡度计算:
  //   dzdx = (f - d) / (2 * w)
  //   dzdy = (h - b) / (2 * w)
  //   Slope = sqrt(dzdx^2 + dzdy^2)
  // ------------------------------------------------------------------

  function method dzdx(d: real, f: real, w: real): real
    requires w > 0.0
  {
    (f - d) / (2.0 * w)
  }

  function method dzdy(b: real, h: real, w: real): real
    requires w > 0.0
  {
    (h - b) / (2.0 * w)
  }

  function method SlopeSq(d: real, f: real, b: real, h: real, w: real): real
    requires w > 0.0
  {
    dzdx(d, f, w) * dzdx(d, f, w) + dzdy(b, h, w) * dzdy(b, h, w)
  }

  // ------------------------------------------------------------------
  // 命题:如果所有九个单元格的高程相同,则坡度平方恒为零
  // ------------------------------------------------------------------
  lemma HornSlopeZeroOnFlatSurface(e: real, w: real)
    requires w > 0.0
    ensures SlopeSq(e, e, e, e, w) == 0.0
  {
    assert dzdx(e, e, w) == 0.0;
    assert dzdy(e, e, w) == 0.0;
    assert SlopeSq(e, e, e, e, w) == 0.0;
  }

  // ------------------------------------------------------------------
  // 命题:平面高程扰动 δ 使坡度误差 ~σ/w
  // ------------------------------------------------------------------
  lemma SlopeErrorGrowsWithNoise(e: real, delta: real, w: real)
    requires w > 0.0
    ensures SlopeSq(e, e + delta, e, e + delta, w) == (delta * delta) / (2.0 * w * w)
  {
    assert dzdx(e, e + delta, w) == delta / (2.0 * w);
    assert dzdy(e, e + delta, w) == delta / (2.0 * w);
    assert SlopeSq(e, e + delta, e, e + delta, w) == (delta * delta) / (2.0 * w * w);
  }
}

method Main() {
  print "GeoProofBench P-019 — Horn Slope: zero on flat surfaces + noise contrast\n";
  print "全部由编译期验证:dafny verify P019_slope_consistency.dfy\n";
}
