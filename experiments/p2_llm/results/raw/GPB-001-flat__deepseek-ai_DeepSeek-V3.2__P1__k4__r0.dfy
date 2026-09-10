// ===========================================================================
//  GeoProofBench · P-001 (Horn slope)
//  文件 : formal/dafny/P001_horn_flat_zero.dfy
//  算子 : Horn (1981) 3x3 有限差分坡度
//  覆盖 : GPB-019 的代数核（平坦窗口 → 坡度为零）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_flat_zero.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在任意 3x3 高程窗口中，若所有九个单元格的高程相同，
//        则 Horn (1981) 坡度大小（或其平方 SlopeSq）恒为零。
//        网格间距 w 必须为正。
//
//  这是 GPB-019 一致性命题的代数特例，也是 Horn 算子的基本性质：
//      平坦地形 → 零坡度。
//  与 P-003 不同，这里不涉及曲率，仅使用一阶差分。
//
//  窗口约定（与 P-001 主文件相同）：
//      a(-1,-1)   b( 0,-1)   c( 1,-1)
//      d(-1, 0)     e        f( 1, 0)
//      g(-1, 1)   h( 0, 1)   i( 1, 1)
//
//  Horn (1981) 坡度分量：
//      dz/dx ≈ ( (c + 2f + i) - (a + 2d + g) ) / (8 * w)
//      dz/dy ≈ ( (g + 2h + i) - (a + 2b + c) ) / (8 * w)
//  坡度平方 SlopeSq = (dz/dx)² + (dz/dy)²
//
//  平坦窗口：a = b = c = d = e = f = g = h = i = Z
//  代入即得 dz/dx = 0, dz/dy = 0, SlopeSq = 0。
// ===========================================================================

module HornFlatZero {
  import opened HornSlope  // 假设已有 Horn 坡度算子的定义模块

  // ------------------------------------------------------------------
  // 平坦窗口的 Horn 坡度为零（直接计算）
  // ------------------------------------------------------------------
  lemma FlatWindowZeroSlopeSq(
    Z: real, w: real
  )
    requires w > 0.0
    ensures HornSlope.SlopeSq(Z, Z, Z, Z, Z, Z, Z, Z, Z, w) == 0.0
  {
    // 计算 dz/dx
    var num_dx: real := (Z + 2.0*Z + Z) - (Z + 2.0*Z + Z);
    var dzdx: real := num_dx / (8.0 * w);
    assert dzdx == 0.0;

    // 计算 dz/dy
    var num_dy: real := (Z + 2.0*Z + Z) - (Z + 2.0*Z + Z);
    var dzdy: real := num_dy / (8.0 * w);
    assert dzdy == 0.0;

    // 坡度平方
    assert HornSlope.SlopeSq(Z, Z, Z, Z, Z, Z, Z, Z, Z, w) == dzdx*dzdx + dzdy*dzdy;
    assert dzdx*dzdx + dzdy*dzdy == 0.0;
  }

  // ------------------------------------------------------------------
  // 平坦窗口的 Horn 坡度大小为零（调用平方根）
  // ------------------------------------------------------------------
  lemma FlatWindowZeroSlopeMagnitude(
    Z: real, w: real
  )
    requires w > 0.0
    ensures HornSlope.SlopeMagnitude(Z, Z, Z, Z, Z, Z, Z, Z, Z, w) == 0.0
  {
    FlatWindowZeroSlopeSq(Z, w);
    // SlopeMagnitude 定义为 sqrt(SlopeSq)，且 SlopeSq ≥ 0
    assert HornSlope.SlopeSq(Z, Z, Z, Z, Z, Z, Z, Z, Z, w) == 0.0;
    assert HornSlope.SlopeMagnitude(Z, Z, Z, Z, Z, Z, Z, Z, Z, w) == 0.0;
  }

  // ------------------------------------------------------------------
  // 辅助引理：若所有九个值相等，则 Horn 坡度分量为零
  // ------------------------------------------------------------------
  lemma FlatWindowZeroComponents(
    a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real,
    w: real
  )
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures HornSlope.dzdx(a, b, c, d, e, f, g, h, i, w) == 0.0
    ensures HornSlope.dzdy(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    var Z: real := a;
    // 展开 dzdx 的分子
    var num_dx: real := (c + 2.0*f + i) - (a + 2.0*d + g);
    assert num_dx == (Z + 2.0*Z + Z) - (Z + 2.0*Z + Z);
    assert num_dx == 0.0;
    assert HornSlope.dzdx(a, b, c, d, e, f, g, h, i, w) == 0.0;

    // 展开 dzdy 的分子
    var num_dy: real := (g + 2.0*h + i) - (a + 2.0*b + c);
    assert num_dy == (Z + 2.0*Z + Z) - (Z + 2.0*Z + Z);
    assert num_dy == 0.0;
    assert HornSlope.dzdy(a, b, c, d, e, f, g, h, i, w) == 0.0;
  }
}

method Main() {
  print "GeoProofBench P-001 (flat window) — Horn slope is zero on constant elevation\n";
  print "全部由编译期验证: dafny verify P001_horn_flat_zero.dfy\n";
}
