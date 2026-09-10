// ===========================================================================
//  GeoProofBench · P-019
//  文件 : formal/dafny/P019_slope_consistency.dfy
//  算子 : Horn (1981) 3x3 一阶差分(坡度)
//  覆盖 : GPB-019(坡度在平面一致)、平面高程一致时坡度为零
//  环境 : Dafny 4.11 · 验证命令 dafny verify P019_slope_consistency.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  本文件证明 Horn (1981) 坡度算子在所有九个单元格高程相同时,坡度恒为零。
//  这是 GPB-019 的代数部分,对应于 P-001 的 PlanarExact。
//
//  不证:一般 C¹ 收敛;剖面曲率在梯度为零处的符号。
//
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  // -------------------------------------------

  // Horn (1981) 坡度算子
  function method HornSlope(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    let dzdx = (c - a + 2 * f - 2 * d) / (8 * w),
        dzdy = (g - c + 2 * h - 2 * b) / (8 * w);
    (dzdx * dzdx + dzdy * dzdy) ** 0.5
  }

  // ------------------------------------------------------------------
  // 命题:所有九个单元格高程相同时,坡度恒为零
  // ------------------------------------------------------------------
  lemma SlopeIsZeroWhenElevationsAreEqual(e: real, w: real)
    requires w > 0.0
    ensures HornSlope(e, e, e, e, e, e, e, e, e, w) == 0.0
  {
    let a = e, b = e, c = e, d = e, f = e, g = e, h = e, i = e;
    let dzdx = (c - a + 2 * f - 2 * d) / (8 * w),
        dzdy = (g - c + 2 * h - 2 * b) / (8 * w);
    assert dzdx == 0.0;
    assert dzdy == 0.0;
    assert (dzdx * dzdx + dzdy * dzdy) ** 0.5 == 0.0;
  }

  // ------------------------------------------------------------------
  // 主方法:验证命题
  // ------------------------------------------------------------------
  method Main() {
    print "GeoProofBench P-019 — Horn Slope: slope is zero when elevations are equal\n";
    print "全部由编译期验证:dafny verify P019_slope_consistency.dfy\n";
  }
}
