// ===========================================================================
//  GeoProofBench · Horn Slope Consistency
//  算子 : Horn (1981) 3x3 坡度算子
//  定理 : 平坦地形上坡度平方恒为零
//  环境 : Dafny 4.11
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-003 相同)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 坡度算子定义:
  //   ∂z/∂x = ( (c + 2f + i) - (a + 2d + g) ) / (8w)
  //   ∂z/∂y = ( (g + 2h + i) - (a + 2b + c) ) / (8w)
  //   SlopeSq = (∂z/∂x)² + (∂z/∂y)²
  // ------------------------------------------------------------------

  // Horn 坡度平方算子
  function HornSlopeSq(
    a: real, b: real, c: real,
    d: real,         f: real,
    g: real, h: real, i: real,
    w: real
  ): real
    requires w > 0.0  // 网格间距必须为正
  {
    // 计算 x 方向偏导
    var dzdx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
    // 计算 y 方向偏导
    var dzdy := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w);
    // 返回坡度平方
    dzdx*dzdx + dzdy*dzdy
  }

  // ==================================================================
  // 核心定理: 平坦地形上坡度平方为零
  // ==================================================================
  theorem FlatTerrainZeroSlope(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real
  )
    requires w > 0.0                     // 网格间距为正
    requires a == b && b == c && c == d  // 所有高程相等
      && d == e && e == f
      && f == g && g == h && h == i
    ensures HornSlopeSq(a, b, c, d, f, g, h, i, w) == 0.0
  {
    // 展开坡度平方计算
    var dzdx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
    var dzdy := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w);

    // 平坦地形下分子恒为零
    assert (c + 2.0*f + i) - (a + 2.0*d + g) == 0.0 by {
      calc {
        (c + 2.0*f + i) - (a + 2.0*d + g);
        ==  // 所有高程相等
        (a + 2.0*a + a) - (a + 2.0*a + a);
        ==  // 算术简化
        4.0*a - 4.0*a;
        ==
        0.0;
      }
    }

    assert ((g + 2.0*h + i) - (a + 2.0*b + c)) == 0.0 by {
      calc {
        (g + 2.0*h + i) - (a + 2.0*b + c);
        ==  // 所有高程相等
        (a + 2.0*a + a) - (a + 2.0*a + a);
        ==  // 算术简化
        4.0*a - 4.0*a;
        ==
        0.0;
      }
    }

    // 偏导为零 ⇒ 坡度平方为零
    assert dzdx == 0.0 && dzdy == 0.0 ==> dzdx*dzdx + dzdy*dzdy == 0.0;
  }
}

method Main() {
  print "GeoProofBench: Horn slope consistency on flat terrain\n";
  print "Verified by Dafny\n";
}
