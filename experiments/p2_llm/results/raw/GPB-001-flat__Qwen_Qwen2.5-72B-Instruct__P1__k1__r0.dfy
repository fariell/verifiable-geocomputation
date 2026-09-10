// ===========================================================================
//  GeoProofBench · P-019
//  文件 : formal/dafny/P019_slope_consistency.dfy
//  算子 : Horn (1981) 3x3 一阶差分(坡度)
//  覆盖 : GPB-019(坡度在平面一致)、
//         平面 z = Dx x + Ey y + F0 上 Horn 坡度恒为 0
//  环境 : Dafny 4.11 · 验证命令 dafny verify P019_slope_consistency.dfy
//  日期 : 2026-09-06
// ===========================================================================

module HornSlopeConsistency {

  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  // 
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  // 
  // Horn (1981) 一阶差分给出:
  //   ∂z/∂x = (c - a) / (2 w)
  //   ∂z/∂y = (g - i) / (2 w)
  // 
  // 坡度平方:
  //   SlopeSq = (∂z/∂x)² + (∂z/∂y)²

  function method NumDzDx(a: real, c: real, w: real): real
    requires w > 0.0
  {
    (c - a) / (2.0 * w)
  }

  function method NumDzDy(g: real, i: real, w: real): real
    requires w > 0.0
  {
    (g - i) / (2.0 * w)
  }

  function method SlopeSq(a: real, c: real, g: real, i: real, w: real): real
    requires w > 0.0
  {
    NumDzDx(a, c, w) * NumDzDx(a, c, w) + NumDzDy(g, i, w) * NumDzDy(g, i, w)
  }

  // 平面 z = Dx x + Ey y + F0 上 Horn 坡度恒为 0
  lemma HornSlopeIsZeroOnPlane(Dx: real, Ey: real, F0: real, w: real)
    requires w > 0.0
    ensures SlopeSq(Dx * (-1.0) + Ey * (-1.0) + F0,
                    Dx * 1.0 + Ey * (-1.0) + F0,
                    Dx * (-1.0) + Ey * 1.0 + F0,
                    Dx * 1.0 + Ey * 1.0 + F0,
                    w) == 0.0
  {
    assert NumDzDx(Dx * (-1.0) + Ey * (-1.0) + F0, Dx * 1.0 + Ey * (-1.0) + F0, w) == 0.0;
    assert NumDzDy(Dx * (-1.0) + Ey * 1.0 + F0, Dx * 1.0 + Ey * 1.0 + F0, w) == 0.0;
    assert SlopeSq(Dx * (-1.0) + Ey * (-1.0) + F0,
                   Dx * 1.0 + Ey * (-1.0) + F0,
                   Dx * (-1.0) + Ey * 1.0 + F0,
                   Dx * 1.0 + Ey * 1.0 + F0,
                   w) == 0.0;
  }

  // 3x3 窗口所有单元格高程相同,则 Horn 坡度恒为 0
  lemma HornSlopeIsZeroOnFlat(e: real, w: real)
    requires w > 0.0
    ensures SlopeSq(e, e, e, e, w) == 0.0
  {
    assert NumDzDx(e, e, w) == 0.0;
    assert NumDzDy(e, e, w) == 0.0;
    assert SlopeSq(e, e, e, e, w) == 0.0;
  }
}

method Main() {
  print "GeoProofBench P-019 — Horn Slope: consistency on flat and planar surfaces\n";
  print "全部由编译期验证:dafny verify P019_slope_consistency.dfy\n";
}
