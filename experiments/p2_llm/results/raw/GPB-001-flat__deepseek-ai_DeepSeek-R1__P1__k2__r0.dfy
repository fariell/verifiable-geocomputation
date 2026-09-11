// ===========================================================================
//  GeoProofBench · Horn Slope on Flat Window
//  算子 : Horn (1981) slope magnitude
//  命题 : 在任意 3x3 窗口内，若所有高程值相等，则 Horn 坡度幅值为零。
//  环境 : Dafny 4.11
// ===========================================================================

module HornSlope {

  // Horn (1981) 有限差分坡度算子
  function HornDx(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (c + 2.0*f + i) - (a + 2.0*d + g) ) / (8.0 * w)
  }

  function HornDy(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (g + 2.0*h + i) - (a + 2.0*b + c) ) / (8.0 * w)
  }

  function SlopeSq(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    var dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    var dy := HornDy(a, b, c, d, e, f, g, h, i, w);
    dx*dx + dy*dy
  }

  // 核心定理: 当所有高程相等时，坡度平方恒为零
  lemma ZeroSlopeOnFlatTerrain(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 计算梯度分量
    var dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    var dy := HornDy(a, b, c, d, e, f, g, h, i, w);
    
    // 展开分子项证明为零
    assert (c + 2.0*f + i) == a + 2.0*a + a;  // 4a
    assert (a + 2.0*d + g) == a + 2.0*a + a;  // 4a
    assert dx == 0.0 / (8.0 * w);
    
    assert (g + 2.0*h + i) == a + 2.0*a + a;  // 4a
    assert (a + 2.0*b + c) == a + 2.0*a + a;  // 4a
    assert dy == 0.0 / (8.0 * w);
    
    // 零的平方和为零
    assert dx*dx == 0.0;
    assert dy*dy == 0.0;
  }

  method Main() {
    print "GeoProofBench: Horn slope is zero on flat terrain (verified)\n";
  }
}
