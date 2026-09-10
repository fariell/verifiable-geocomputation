// ===========================================================================
//  GeoProofBench · P-001 (Horn slope)
//  文件 : formal/dafny/P001_horn_slope_flat.dfy
//  算子 : Horn (1981) 3x3 有限差分坡度
//  覆盖 : GPB-019 的代数核（平坦窗口 → 零坡度）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope_flat.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在任意 3x3 高程窗口中，若所有九个单元格具有相同的高程值，
//        则 Horn (1981) 坡度大小（或其平方 SlopeSq）恒为零。
//        网格间距 w 必须为正。
//
//  这是 GPB-019 一致性命题的代数特例，也是 P-001 已验证的平面精确性
//  的直接推论。平坦窗口是平面窗口的特例（A=B=Cxy=Dx=Ey=0）。
//
//  不证：一般平面上的精确性（已在 P-001 中证明）、噪声传播、
//        或随网格间距趋于零的渐近一致性。
//
// ===========================================================================

module HornSlopeFlat {
  import opened HornSlopeCore  // 导入 Horn 算子的核心定义

  // ------------------------------------------------------------------
  // 3x3 窗口约定（与 P-001 相同：p 向右，q 向下）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 有限差分坡度：
  //   dz/dx ≈ (c + 2f + i - a - 2d - g) / (8w)
  //   dz/dy ≈ (g + 2h + i - a - 2b - c) / (8w)
  //   slope² = (dz/dx)² + (dz/dy)²
  // ------------------------------------------------------------------

  // 主定理：平坦窗口的 Horn 坡度为零
  theorem FlatWindowZeroSlope(a: real, b: real, c: real,
                              d: real, e: real, f: real,
                              g: real, h: real, i: real,
                              w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 平坦窗口是平面窗口的特例，其中所有系数为零
    // 直接计算分子项：
    //   dz/dx 分子 = (c + 2f + i) - (a + 2d + g)
    //            = (e + 2e + e) - (e + 2e + e) = 0
    //   dz/dy 分子 = (g + 2h + i) - (a + 2b + c)
    //            = (e + 2e + e) - (e + 2e + e) = 0
    // 因此 slope² = 0² + 0² = 0

    calc {
      SlopeSq(a, b, c, d, e, f, g, h, i, w);
      ==  // 展开 SlopeSq 定义
      {
        var dzdx := DxHorn(a, b, c, d, e, f, g, h, i, w);
        var dzdy := DyHorn(a, b, c, d, e, f, g, h, i, w);
        dzdx * dzdx + dzdy * dzdy;
      }
      ==  // 计算 dzdx
      {
        var numDx := (c + 2.0 * f + i) - (a + 2.0 * d + g);
        // 由前提条件，所有高程相等，代入 a 作为公共值
        assert a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i;
        assert numDx == (a + 2.0 * a + a) - (a + 2.0 * a + a) by {
          calc {
            numDx;
            == (a + 2.0 * a + a) - (a + 2.0 * a + a);
            == 0.0;
          }
        }
        var dzdx := numDx / (8.0 * w);
        dzdx;
      }
      ==  // numDx = 0 ⇒ dzdx = 0
      0.0;
      ==  // 计算 dzdy
      {
        var numDy := (g + 2.0 * h + i) - (a + 2.0 * b + c);
        assert numDy == (a + 2.0 * a + a) - (a + 2.0 * a + a) by {
          calc {
            numDy;
            == (a + 2.0 * a + a) - (a + 2.0 * a + a);
            == 0.0;
          }
        }
        var dzdy := numDy / (8.0 * w);
        dzdy;
      }
      ==  // numDy = 0 ⇒ dzdy = 0
      0.0;
      ==  // slope² = 0² + 0²
      0.0;
    }
  }

  // 推论：平坦窗口的坡度大小（非平方）也为零
  corollary FlatWindowZeroSlopeMagnitude(a: real, b: real, c: real,
                                         d: real, e: real, f: real,
                                         g: real, h: real, i: real,
                                         w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    FlatWindowZeroSlope(a, b, c, d, e, f, g, h, i, w);
    // SlopeMagnitude 定义为 sqrt(SlopeSq)，且 SlopeSq == 0
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0;
    // 0 的平方根为 0
    assert SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0 by {
      calc {
        SlopeMagnitude(a, b, c, d, e, f, g, h, i, w);
        == Math.Sqrt(SlopeSq(a, b, c, d, e, f, g, h, i, w));
        == Math.Sqrt(0.0);
        == 0.0;
      }
    }
  }
}

// ===========================================================================
// 辅助模块：Horn 算子的核心定义
// ===========================================================================
module HornSlopeCore {
  // Horn (1981) 坡度算子的有限差分系数
  function DxHorn(a: real, b: real, c: real,
                  d: real, e: real, f: real,
                  g: real, h: real, i: real,
                  w: real): real
    requires w > 0.0
  {
    ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * w)
  }

  function DyHorn(a: real, b: real, c: real,
                  d: real, e: real, f: real,
                  g: real, h: real, i: real,
                  w: real): real
    requires w > 0.0
  {
    ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * w)
  }

  // 坡度平方（避免平方根，便于代数推理）
  function SlopeSq(a: real, b: real, c: real,
                   d: real, e: real, f: real,
                   g: real, h: real, i: real,
                   w: real): real
    requires w > 0.0
  {
    var dzdx := DxHorn(a, b, c, d, e, f, g, h, i, w);
    var dzdy := DyHorn(a, b, c, d, e, f, g, h, i, w);
    dzdx * dzdx + dzdy * dzdy
  }

  // 坡度大小（带平方根的实际值）
  function SlopeMagnitude(a: real, b: real, c: real,
                          d: real, e: real, f: real,
                          g: real, h: real, i: real,
                          w: real): real
    requires w > 0.0
    ensures SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) >= 0.0
  {
    Math.Sqrt(SlopeSq(a, b, c, d, e, f, g, h, i, w))
  }
}

method Main() {
  print "GeoProofBench P-001 (平坦窗口特例) — Horn 坡度在平坦窗口为零\n";
  print "验证命令: dafny verify P001_horn_slope_flat.dfy\n";
}
