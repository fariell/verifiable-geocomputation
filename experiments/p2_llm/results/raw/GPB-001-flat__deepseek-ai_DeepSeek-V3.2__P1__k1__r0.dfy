// ===========================================================================
//  GeoProofBench · P-001 (Horn slope consistency)
//  文件 : formal/dafny/P001_horn_flat_zero.dfy
//  算子 : Horn (1981) 3x3 坡度
//  覆盖 : GPB-019 的代数核（平坦窗口上坡度为零）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_flat_zero.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在任意 3x3 高程窗口中，若所有九个单元格的高程相同，
//        则 Horn (1981) 坡度大小（或其平方 SlopeSq）恒为零。
//        网格间距 w 必须为正。
//
//  这是 GPB-019 一致性命题的代数特例（平坦地形）。
//  平面上的精确性已在 P-001 主文件中证明，此处仅聚焦于平坦情况。
//
// ===========================================================================

module HornFlatZero {
  import opened HornSlope  // 导入 Horn 坡度算子的定义

  // ------------------------------------------------------------------
  // 3x3 窗口约定（与 HornSlope 模块一致）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  //  Horn (1981) 坡度分量：
  //    dz/dx ≈ (c + 2f + i - a - 2d - g) / (8w)
  //    dz/dy ≈ (g + 2h + i - a - 2b - c) / (8w)
  //  坡度平方 SlopeSq = (dz/dx)² + (dz/dy)²
  // ------------------------------------------------------------------

  // 平坦窗口上 Horn 坡度为零
  lemma FlatWindowZeroSlope(a: real, b: real, c: real,
                            d: real, e: real, f: real,
                            g: real, h: real, i: real,
                            w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 所有高程相等
    assert a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i;

    // 计算 dz/dx 的分子
    var num_dzdx: real := c + 2.0 * f + i - a - 2.0 * d - g;
    // 由于所有值相等，分子为零
    calc {
      num_dzdx;
      ==
      a + 2.0 * a + a - a - 2.0 * a - a;
      ==
      0.0;
    }

    // 计算 dz/dy 的分子
    var num_dzdy: real := g + 2.0 * h + i - a - 2.0 * b - c;
    calc {
      num_dzdy;
      ==
      a + 2.0 * a + a - a - 2.0 * a - a;
      ==
      0.0;
    }

    // 坡度分量为零
    var dzdx: real := num_dzdx / (8.0 * w);
    var dzdy: real := num_dzdy / (8.0 * w);
    assert dzdx == 0.0 && dzdy == 0.0;

    // 坡度平方为零
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == dzdx * dzdx + dzdy * dzdy;
    assert dzdx * dzdx + dzdy * dzdy == 0.0;
  }

  // 推论：坡度大小（平方根）也为零
  lemma FlatWindowZeroSlopeMagnitude(a: real, b: real, c: real,
                                     d: real, e: real, f: real,
                                     g: real, h: real, i: real,
                                     w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    FlatWindowZeroSlope(a, b, c, d, e, f, g, h, i, w);
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0;
    // SlopeMagnitude 定义为 SlopeSq 的平方根（非负）
    assert SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0;
  }
}

method Main() {
  print "GeoProofBench P-001 (平坦窗口) — Horn 坡度在平坦窗口上为零\n";
  print "验证: dafny verify P001_horn_flat_zero.dfy\n";
}
