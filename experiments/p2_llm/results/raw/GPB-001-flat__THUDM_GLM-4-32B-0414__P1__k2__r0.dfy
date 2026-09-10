// ===========================================================================
//  GeoProofBench · GPB-019
//  文件 : formal/dafny/GPB019_Horn_slope_zero.dfy
//  算子 : Horn (1981) 斜率计算
//  覆盖 : 3x3 窗口平坦性 ⇒ 斜率零
//  环境 : Dafny 4.11 · 验证命令 dafny verify GPB019_Horn_slope_zero.dfy
//  日期 : 2026-09-06
// ===========================================================================

module GPB019HornZero {
  
  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //

  // Horn (1981) 斜率计算
  // 斜率平方 SlopeSq = (dz/dx)² + (dz/dy)²
  // 其中 dz/dx ≈ (f - d)/(2w), dz/dy ≈ (h - b)/(2w)
  // 因此 SlopeSq = [(f-d)/(2w)]² + [(h-b)/(2w)]²
  method HornSlopeSq(a: real, b: real, c: real, d: real, e: real, f: real,
                     g: real, h: real, i: real, w: real) : real
    requires w > 0.0
    ensures result == ((f - d)/(2.0 * w)) * ((f - d)/(2.0 * w)) + 
                     ((h - b)/(2.0 * w)) * ((h - b)/(2.0 * w))
  {
    return ((f - d)/(2.0 * w)) * ((f - d)/(2.0 * w)) + 
           ((h - b)/(2.0 * w)) * ((h - b)/(2.0 * w));
  }

  // 命题:如果所有九个单元格高度相同,则 Horn 斜率平方为零
  lemma FlatWindowImpliesZeroSlope(a: real, b: real, c: real, d: real, e: real,
                                  f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b == c == d == e == f == g == h == i
    ensures HornSlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 由于所有高度相同,有 f == d 且 h == b
    assert f == d;
    assert h == b;
    
    // 因此 dz/dx = (f - d)/(2w) = 0
    // dz/dy = (h - b)/(2w) = 0
    // 所以 SlopeSq = 0² + 0² = 0
    assert (f - d) == 0.0;
    assert (h - b) == 0.0;
    
    // 直接计算验证
    var slope_sq := HornSlopeSq(a, b, c, d, e, f, g, h, i, w);
    assert slope_sq == 0.0;
  }

  method Main() {
    print "GeoProofBench GPB-019 — Horn slope zero on flat windows\n";
    print "全部由编译期验证:dafny verify GPB019_Horn_slope_zero.dfy\n";
  }
}
