// ===========================================================================
//  GeoProofBench · P-001 (Horn slope)
//  文件 : formal/dafny/P001_horn_slope_flat.dfy
//  算子 : Horn (1981) 3x3 有限差分坡度
//  覆盖 : GPB-019 的代数核（平坦窗口 ⇒ 坡度为零）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope_flat.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在任意 3x3 高程窗口中，若所有九个单元格的高程相同，
//        则 Horn (1981) 坡度大小（或其平方 SlopeSq）恒为零。
//        网格间距 w 必须为正。
//
//  这是 GPB-019 一致性命题的代数特例（平坦地形）。
//  Phase 1 实验已验证 Horn 坡度在 w→0 时收敛到解析值（非平坦地形），
//  而剖面曲率在相同条件下不收敛（GPB-020 的 gap）。
//  本文件仅证明平坦情形下的代数恒等式。
//
// ===========================================================================

module HornSlopeFlat {
  import opened HornSlopeOperators  // 导入 Horn 坡度算子定义

  // ------------------------------------------------------------------
  // 3x3 窗口约定（与 P-001 主文件一致）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 坡度分量：
  //   dz/dx ≈ ( (c + 2f + i) - (a + 2d + g) ) / (8w)
  //   dz/dy ≈ ( (g + 2h + i) - (a + 2b + c) ) / (8w)
  //   slope² = (dz/dx)² + (dz/dy)²
  // ------------------------------------------------------------------

  // 平坦窗口引理：所有高程相等 ⇒ 坡度平方为零
  lemma FlatWindowImpliesZeroSlopeSq(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real
  )
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 由平坦条件，所有高程值相等，记公共值为 v
    var v :| a == v && b == v && c == v && d == v && e == v && f == v && g == v && h == v && i == v;

    // 计算 dz/dx 的分子
    var num_dzdx := (c + 2.0 * f + i) - (a + 2.0 * d + g);
    // 代入 v
    calc {
      num_dzdx;
      ==
      (v + 2.0 * v + v) - (v + 2.0 * v + v);
      ==
      (4.0 * v) - (4.0 * v);
      ==
      0.0;
    }

    // 计算 dz/dy 的分子
    var num_dzdy := (g + 2.0 * h + i) - (a + 2.0 * b + c);
    calc {
      num_dzdy;
      ==
      (v + 2.0 * v + v) - (v + 2.0 * v + v);
      ==
      (4.0 * v) - (4.0 * v);
      ==
      0.0;
    }

    // 因此 dz/dx = 0 / (8w) = 0, dz/dy = 0 / (8w) = 0
    // 坡度平方 = 0² + 0² = 0
    assert DzDx(a, b, c, d, e, f, g, h, i, w) == 0.0;
    assert DzDy(a, b, c, d, e, f, g, h, i, w) == 0.0;
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0;
  }

  // 推论：坡度大小（平方根）也为零
  lemma FlatWindowImpliesZeroSlopeMagnitude(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real
  )
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    FlatWindowImpliesZeroSlopeSq(a, b, c, d, e, f, g, h, i, w);
    // SlopeMagnitude 定义为 SlopeSq 的非负平方根
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0;
    assert SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0;
  }
}

method Main() {
  print "GeoProofBench P-001 (平坦窗口特例) — Horn 坡度在平坦地形上为零\n";
  print "验证命令: dafny verify P001_horn_slope_flat.dfy\n";
}
