// ===========================================================================
//  GeoProofBench · P-004
//  文件 : formal/dafny/P004_consistency.dfy
//  算子 : Horn (1981) 3x3 有限差分坡度
//  覆盖 : GPB-019 的代数部分（二次曲面精确性、三次曲面 O(w²) 余项）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P004_consistency.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  GPB-019 要求验证 Horn 坡度算子的“代数一致性”：
//      1. 在任意二次曲面 z = A x + B y + C + D x² + E x y + F y² 上，
//         Horn 差分精确恢复系数 A, B（与格网间距 w 无关）。
//      2. 在纯三次曲面 z = G x³ 上，原点处的 DzDx 余项等于 G w²，
//         即误差为 O(w²)，表明算子具有二阶数值一致性。
//
//  这两个性质是“有限差分格式在多项式曲面上的精确性”的标准验证，
//  也是 Horn 算子被广泛采用的理论依据之一。
//
//  本文件复用 P-001 中定义的 Horn 差分函数，仅添加关于多项式曲面的引理。
// ===========================================================================

include "P001_horn_slope.dfy"

module Consistency {
  import opened HornSlope

  // ------------------------------------------------------------------
  // 二次曲面采样函数
  // 曲面：z = A x + B y + C + D x² + E x y + F y²
  // 采样点坐标 (p*w, q*w)，其中 p, q ∈ {-1, 0, 1}
  // ------------------------------------------------------------------
  function QuadraticSample(A: real, B: real, C: real,
                           D: real, E: real, F: real,
                           w: real, p: int, q: int): real
    requires w > 0.0
  {
    var x := p as real * w;
    var y := q as real * w;
    A * x + B * y + C + D * x * x + E * x * y + F * y * y
  }

  // ------------------------------------------------------------------
  // 二次曲面上的 Horn 差分精确性
  // 定理：对任意二次曲面系数和任意 w > 0，
  //      DzDx 返回 A，DzDy 返回 B。
  // ------------------------------------------------------------------
  lemma HornExactOnQuadratic(A: real, B: real, C: real,
                             D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures
      var a := QuadraticSample(A, B, C, D, E, F, w, -1, -1);
      var b := QuadraticSample(A, B, C, D, E, F, w,  0, -1);
      var c := QuadraticSample(A, B, C, D, E, F, w,  1, -1);
      var d := QuadraticSample(A, B, C, D, E, F, w, -1,  0);
      var f := QuadraticSample(A, B, C, D, E, F, w,  1,  0);
      var g := QuadraticSample(A, B, C, D, E, F, w, -1,  1);
      var h := QuadraticSample(A, B, C, D, E, F, w,  0,  1);
      var i := QuadraticSample(A, B, C, D, E, F, w,  1,  1);
      DzDx(a, b, c, d, f, g, h, i, w) == A &&
      DzDy(a, b, c, d, f, g, h, i, w) == B
  {
    // 展开 DzDx 和 DzDy 的定义
    // DzDx = ((c + 2f + i) - (a + 2d + g)) / (8w)
    // DzDy = ((g + 2h + i) - (a + 2b + c)) / (8w)

    // 计算各采样点的代数表达式
    // 由于对称性，分子中许多项会抵消，最终只留下线性项系数。
    // 以下通过断言展开代数验证：
    assert QuadraticSample(A, B, C, D, E, F, w, -1, -1) ==
           -A*w - B*w + C + D*w*w + E*w*w + F*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w,  0, -1) ==
           -B*w + C + F*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w,  1, -1) ==
           A*w - B*w + C + D*w*w - E*w*w + F*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w, -1,  0) ==
           -A*w + C + D*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w,  1,  0) ==
           A*w + C + D*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w, -1,  1) ==
           -A*w + B*w + C + D*w*w - E*w*w + F*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w,  0,  1) ==
           B*w + C + F*w*w;
    assert QuadraticSample(A, B, C, D, E, F, w,  1,  1) ==
           A*w + B*w + C + D*w*w + E*w*w + F*w*w;

    // 计算 DzDx 的分子
    var numDx := (c + 2.0*f + i) - (a + 2.0*d + g);
    // 代入上述表达式，所有常数项 C、二次项 D w²、E w²、F w² 均抵消，
    // 仅剩下 A 的线性项：8 A w
    assert numDx == 8.0 * A * w;

    // 计算 DzDy 的分子
    var numDy := (g + 2.0*h + i) - (a + 2.0*b + c);
    // 同样，常数项和二次项抵消，剩下 8 B w
    assert numDy == 8.0 * B * w;

    // 除以 8w 即得 A 和 B
    assert DzDx(a, b, c, d, f, g, h, i, w) == numDx / (8.0 * w) == A;
    assert DzDy(a, b, c, d, f, g, h, i, w) == numDy / (8.0 * w) == B;
  }

  // ------------------------------------------------------------------
  // 三次曲面 z = G x³ 采样函数
  // 采样点坐标 (p*w, q*w)
  // ------------------------------------------------------------------
  function CubicSample(G: real, w: real, p: int, q: int): real
    requires w > 0.0
  {
    var x := p as real * w;
    G * x * x * x
  }

  // ------------------------------------------------------------------
  // 三次曲面上的 Horn 差分余项
  // 定理：对 z = G x³，原点处 DzDx 的误差恰好为 G w²。
  // 注意：原点处真实梯度为 0，因此误差即 DzDx 的计算值。
  // ------------------------------------------------------------------
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures
      var a := CubicSample(G, w, -1, -1);
      var b := CubicSample(G, w,  0, -1);
      var c := CubicSample(G, w,  1, -1);
      var d := CubicSample(G, w, -1,  0);
      var f := CubicSample(G, w,  1,  0);
      var g := CubicSample(G, w, -1,  1);
      var h := CubicSample(G, w,  0,  1);
      var i := CubicSample(G, w,  1,  1);
      DzDx(a, b, c, d, f, g, h, i, w) == G * w * w
  {
    // 计算各采样点值
    assert a == G * (-w) * (-w) * (-w) == -G * w * w * w;
    assert b == G * ( 0) * ( 0) * ( 0) == 0.0;
    assert c == G * ( w) * ( w) * ( w) == G * w * w * w;
    assert d == G * (-w) * (-w) * (-w) == -G * w * w * w;
    assert f == G * ( w) * ( w) * ( w) == G * w * w * w;
    assert g == G * (-w) * (-w) * (-w) == -G * w * w * w;
    assert h == G * ( 0) * ( 0) * ( 0) == 0.0;
    assert i == G * ( w) * ( w) * ( w) == G * w * w * w;

    // 计算 DzDx 分子
    var numDx := (c + 2.0*f + i) - (a + 2.0*d + g);
    // 代入：
    // (c + 2f + i) = G w³ + 2 G w³ + G w³ = 4 G w³
    // (a + 2d + g) = -G w³ + 2(-G w³) + (-G w³) = -4 G w³
    // 分子 = 4 G w³ - (-4 G w³) = 8 G w³
    assert numDx == 8.0 * G * w * w * w;

    // DzDx = (8 G w³) / (8 w) = G w²
    assert DzDx(a, b, c, d, f, g, h, i, w) == numDx / (8.0 * w) == G * w * w;
  }

  // ------------------------------------------------------------------
  // 推论：误差为 O(w²)
  // 当 w → 0 时，误差以 w² 的速度趋于零，表明 Horn 差分具有二阶一致性。
  // 此引理不添加新证明，仅重申 CubicRemainder 的结论。
  // ------------------------------------------------------------------
  lemma CubicErrorOrder(G: real, w: real)
    requires w > 0.0
    ensures
      var a := CubicSample(G, w, -1, -1);
      var b := CubicSample(G, w,  0, -1);
      var c := CubicSample(G, w,  1, -1);
      var d := CubicSample(G, w, -1,  0);
      var f := CubicSample(G, w,  1,  0);
      var g := CubicSample(G, w, -1,  1);
      var h := CubicSample(G, w,  0,  1);
      var i := CubicSample(G, w,  1,  1);
      // 误差绝对值等于 |G| w²
      abs(DzDx(a, b, c, d, f, g, h, i, w) - 0.0) == abs(G) * w * w
  {
    CubicRemainder(G, w);
  }
}

method Main() {
  print "GeoProofBench P-004 — Horn 坡度算子在二次曲面上的精确性与三次曲面 O(w²) 余项\n";
  print "全部由编译期验证: dafny verify P004_consistency.dfy\n";
}
