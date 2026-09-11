// ===========================================================================
//  GeoProofBench · Horn Slope Consistency
//  算子 : Horn (1981) 3x3 坡度算子
//  定理 : 平坦地形上坡度平方恒为零
//  环境 : Dafny 4.11
// ===========================================================================
//
//  定理说明
//  --------
//  在任意 3x3 高程窗口中，若所有单元格高程值相同且网格间距 w > 0，
//  则 Horn (1981) 坡度平方 (SlopeSq) 恒等于零。
//
//  算子定义
//  -------
//  Horn (1981) 一阶有限差分:
//    ∂z/∂x = [ (c + 2f + i) - (a + 2d + g) ] / (8w)
//    ∂z/∂y = [ (g + 2h + i) - (a + 2b + c) ] / (8w)
//    SlopeSq = (∂z/∂x)² + (∂z/∂y)²
//
//  窗口索引约定
//  -----------
//    a(-1,-1)   b( 0,-1)   c( 1,-1)
//    d(-1, 0)     e        f( 1, 0)
//    g(-1, 1)   h( 0, 1)   i( 1, 1)
//
// ===========================================================================

module HornSlope {

  // -------------------------------------------------------------------------
  // Horn (1981) 偏导数计算核
  // -------------------------------------------------------------------------
  function HornDx(a: real, b: real, c: real, d: real, e: real,
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (c + 2.0*f + i) - (a + 2.0*d + g) ) / (8.0 * w)
  }

  function HornDy(a: real, b: real, c: real, d: real, e: real,
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (g + 2.0*h + i) - (a + 2.0*b + c) ) / (8.0 * w)
  }

  // -------------------------------------------------------------------------
  // 坡度平方定义 (避免开方以简化证明)
  // -------------------------------------------------------------------------
  function SlopeSq(a: real, b: real, c: real, d: real, e: real,
                   f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    var dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    var dy := HornDy(a, b, c, d, e, f, g, h, i, w);
    dx*dx + dy*dy
  }

  // =========================================================================
  // 主定理: 平坦地形坡度为零
  // =========================================================================
  lemma FlatTerrainZeroSlope(
    a: real, b: real, c: real, d: real, e: real,
    f: real, g: real, h: real, i: real, w: real
  )
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && 
             e == f && f == g && g == h && h == i  // 九点高程相同
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 展开偏导数计算
    var dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    var dy := HornDy(a, b, c, d, e, f, g, h, i, w);

    // 分子恒等性证明
    assert (c + 2*f + i) == (a + 2*d + g) by {
      calc {
        c + 2*f + i;
        == { assert a == c && d == f && g == i; }  // 由高程相同
        a + 2*d + g;
      }
    }
    assert dx == 0.0;

    // 同理证 dy
    assert (g + 2*h + i) == (a + 2*b + c) by {
      calc {
        g + 2*h + i;
        == { assert a == g && b == h && c == i; }
        a + 2*b + c;
      }
    }
    assert dy == 0.0;

    // 零向量的模为零
    assert dx*dx == 0.0 && dy*dy == 0.0;
  }
}

method Main() {
  print "GeoProofBench · Horn Slope Consistency: Flat terrain has zero slope\n";
  print "验证命令: dafny verify <this_file>.dfy\n";
}
