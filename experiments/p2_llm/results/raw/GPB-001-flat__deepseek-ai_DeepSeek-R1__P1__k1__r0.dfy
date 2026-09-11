// ===========================================================================
//  GeoProofBench · Horn Slope Consistency
//  算子 : Horn (1981) 3x3 坡度算子
//  定理 : 平坦地形上坡度平方恒为零
//  环境 : Dafny 4.11
// ===========================================================================

module HornSlope {
  // ------------------------------------------------------------------
  // 3x3 窗口约定
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 坡度分量定义:
  //   ∂z/∂x = [ (c + 2f + i) - (a + 2d + g) ] / (8w)
  //   ∂z/∂y = [ (g + 2h + i) - (a + 2b + c) ] / (8w)
  // ------------------------------------------------------------------

  // 坡度平方算子 (Horn, 1981)
  function SlopeSq(a: real, b: real, c: real, d: real, e: real,
                   f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    var dzdx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
    var dzdy := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w);
    dzdx*dzdx + dzdy*dzdy
  }

  // ==================================================================
  // 主定理: 平坦地形上坡度平方为零
  // ==================================================================
  lemma FlatTerrainZeroSlope(a: real, b: real, c: real, d: real, e: real,
                             f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && 
             e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 展开坡度分量计算
    var num_x := (c + 2.0*f + i) - (a + 2.0*d + g);
    var num_y := (g + 2.0*h + i) - (a + 2.0*b + c);

    // 平坦地形时分子为零 (所有高程相等)
    assert num_x == 0.0 by {
      calc {
        (c + 2.0*f + i) - (a + 2.0*d + g);
        == { }  // 代入相等条件
        (a + 2.0*a + a) - (a + 2.0*a + a);
        == { }
        4.0*a - 4.0*a;
        == { }
        0.0;
      }
    }
    assert num_y == 0.0 by {
      calc {
        (g + 2.0*h + i) - (a + 2.0*b + c);
        == { }  // 代入相等条件
        (a + 2.0*a + a) - (a + 2.0*a + a);
        == { }
        4.0*a - 4.0*a;
        == { }
        0.0;
      }
    }

    // 坡度分量为零 ⇒ 坡度平方为零
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0 by {
      var dzdx := num_x / (8.0 * w);
      var dzdy := num_y / (8.0 * w);
      assert dzdx == 0.0 && dzdy == 0.0;
    }
  }
}

method Main() {
  print "GeoProofBench · Horn Slope: Flat terrain has zero slope\n";
  print "定理已通过形式化验证\n";
}
