// ===========================================================================
//  GeoProofBench · P-001 (Horn slope consistency)
//  文件 : formal/dafny/P001_horn_flat_zero.dfy
//  算子 : Horn (1981) 3x3 坡度幅值
//  覆盖 : GPB-019 的代数核（平坦窗口 ⇒ 坡度为零）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_flat_zero.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在任意 3x3 高程窗口中，若所有九个单元格的高程相同，
//        则 Horn (1981) 坡度幅值（或其平方 SlopeSq）恒为零。
//        网格间距 w 必须为正。
//
//  这是 GPB-019 一致性命题的代数部分（平面上的精确性已在 P-001 主文件中证明）。
//  本文件专门证明平坦窗口这一特例，作为 Horn 算子一致性的一个基本引理。
//
//  注意：本证明不依赖于网格间距 w 的具体值（只要 w > 0），
//        也不依赖于窗口在 DEM 中的位置。
//
// ===========================================================================

module HornFlatZero {
  import opened HornSlope  // 导入 Horn 坡度算子的定义

  // ------------------------------------------------------------------
  // 3x3 窗口约定（与 Horn 算子原始定义一致）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  //  Horn (1981) 坡度分量：
  //    dz/dx ≈ (c + 2f + i - a - 2d - g) / (8 * w)
  //    dz/dy ≈ (g + 2h + i - a - 2b - c) / (8 * w)
  //  坡度幅值平方 SlopeSq = (dz/dx)² + (dz/dy)²
  // ------------------------------------------------------------------

  // 主定理：平坦窗口 ⇒ 坡度为零
  theorem FlatWindowImpliesZeroSlope(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real
  )
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 由平坦条件，所有高程值相等，记共同值为 v
    var v :| a == v && b == v && c == v && d == v && e == v && f == v && g == v && h == v && i == v;

    // 计算 dz/dx 的分子部分
    calc {
      (c + 2*f + i) - (a + 2*d + g);
      ==
      (v + 2*v + v) - (v + 2*v + v);
      ==
      4*v - 4*v;
      ==
      0.0;
    }

    // 因此 dz/dx = 0
    assert dzdx(a, b, c, d, e, f, g, h, i, w) == 0.0;

    // 计算 dz/dy 的分子部分
    calc {
      (g + 2*h + i) - (a + 2*b + c);
      ==
      (v + 2*v + v) - (v + 2*v + v);
      ==
      4*v - 4*v;
      ==
      0.0;
    }

    // 因此 dz/dy = 0
    assert dzdy(a, b, c, d, e, f, g, h, i, w) == 0.0;

    // 坡度幅值平方为两个零分量的平方和
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0 * 0.0 + 0.0 * 0.0;
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0;
  }

  // 推论：坡度幅值本身也为零（因为平方为零且幅值非负）
  corollary FlatWindowImpliesZeroSlopeMagnitude(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real,
    w: real
  )
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    FlatWindowImpliesZeroSlope(a, b, c, d, e, f, g, h, i, w);
    // SlopeMagnitude 定义为 sqrt(SlopeSq)，且 SlopeSq ≥ 0
    assert SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0;
    assert SlopeMagnitude(a, b, c, d, e, f, g, h, i, w) == 0.0;
  }
}

method Main() {
  print "GeoProofBench P-001 (引理) — 平坦窗口上 Horn 坡度为零\n";
  print "验证命令: dafny verify P001_horn_flat_zero.dfy\n";
}
