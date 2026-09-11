// ===========================================================================
//  GeoProofBench · Horn Slope Consistency
//  算子 : Horn (1981) 3x3 坡度算子
//  定理 : 平坦窗口上的坡度为零
//  环境 : Dafny 4.11
// ===========================================================================
//
//  定理说明
//  ---------
//  在任何具有有限高程值的 3x3 窗口上，若所有九个单元格高程相同，
//  则 Horn (1981) 坡度幅值（或其平方 SlopeSq）恒为零。
//  网格间距 w 必须为正。
//
//  窗口约定
//  --------
//     a(-1,-1)   b( 0,-1)   c( 1,-1)
//     d(-1, 0)     e        f( 1, 0)
//     g(-1, 1)   h( 0, 1)   i( 1, 1)
//
//  Horn 坡度算子定义:
//    ∂z/∂x = (c + 2f + i - a - 2d - g) / (8w)
//    ∂z/∂y = (g + 2h + i - a - 2b - c) / (8w)
//    SlopeSq = (∂z/∂x)² + (∂z/∂y)²
//
// ===========================================================================

module HornSlope {

  // --------------------------------------------------------------------------
  // Horn 坡度算子核心计算
  // --------------------------------------------------------------------------
  function HornDx(a: real, b: real, c: real, d: real, e: real,
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    (c + 2.0*f + i - a - 2.0*d - g) / (8.0 * w)
  }

  function HornDy(a: real, b: real, c: real, d: real, e: real,
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    (g + 2.0*h + i - a - 2.0*b - c) / (8.0 * w)
  }

  function HornSlopeSq(a: real, b: real, c: real, d: real, e: real,
                       f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    let dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    let dy := HornDy(a, b, c, d, e, f, g, h, i, w);
    dx*dx + dy*dy
  }

  // --------------------------------------------------------------------------
  // 主定理: 平坦窗口上的 Horn 坡度为零
  // --------------------------------------------------------------------------
  lemma FlatWindowZeroSlope(a: real, b: real, c: real, d: real, e: real,
                            f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && 
             e == f && f == g && g == h && h == i  // 所有高程相等
    ensures HornSlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 展开 dx 计算 (分子归零)
    assert c + 2.0*f + i == a + 2.0*d + g;  // 因 a=b=c=d=e=f=g=h=i
    assert HornDx(a, b, c, d, e, f, g, h, i, w) == 0.0;

    // 展开 dy 计算 (分子归零)
    assert g + 2.0*h + i == a + 2.0*b + c;  // 因 a=b=c=d=e=f=g=h=i
    assert HornDy(a, b, c, d, e, f, g, h, i, w) == 0.0;

    // 零向量的模平方为零
    assert 0.0*0.0 + 0.0*0.0 == 0.0;
  }
}

method Main() {
  print "GeoProofBench · Horn Slope Consistency: Flat window has zero slope\n";
  print "验证命令: dafny verify <filename>.dfy\n";
}
