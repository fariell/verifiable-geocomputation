// ===========================================================================
//  GeoProofBench · P-004
//  文件 : formal/dafny/P004_consistency.dfy
//  算子 : Horn (1981) 3x3 有限差分坡度
//  覆盖 : GPB-019 代数部分（二次曲面精确性、三次曲面 O(w²) 余项）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P004_consistency.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  --------
//  GPB-019 要求验证 Horn 坡度算子的一致性（consistency）：
//      1. 在二次曲面上，算子应精确恢复平面梯度系数 (A, B)。
//      2. 在三次曲面 z = G x³ 上，原点处的 DzDx 余项应为 G w²（阶 O(w²)）。
//
//  这是数值分析中的“一致性”条件：当网格间距 w → 0 时，有限差分逼近
//  应收敛于真实导数。本文件证明 Horn 算子在二次项上精确（余项为零），
//  在三次项上余项为 O(w²)，从而确认其为一阶一致逼近。
//
//  注意：本证明不依赖经验数据，完全在精确算术（real）下进行。
// ===========================================================================

include "P001_horn_slope.dfy"  // 复用 Horn 算子定义

module Consistency {
  import opened HornSlope

  // ------------------------------------------------------------------
  // 二次曲面：z = A x + B y + C + D x² + E x y + F y²
  // 在任意点 (x0, y0) 处，真实偏导数为：
  //    ∂z/∂x = A + 2D x0 + E y0
  //    ∂z/∂y = B + E x0 + 2F y0
  // 我们证明 Horn 算子在任意 3x3 窗口上精确恢复这些值。
  // ------------------------------------------------------------------

  // 二次曲面采样函数
  function QuadraticSample(A: real, B: real, C: real,
                           D: real, E: real, F: real,
                           w: real, p: int, q: int): real
    requires w > 0.0
  {
    var x := p as real * w;
    var y := q as real * w;
    A * x + B * y + C + D * x * x + E * x * y + F * y * y
  }

  // 构建 3x3 窗口（中心在原点）
  function QuadraticWindow(A: real, B: real, C: real,
                           D: real, E: real, F: real,
                           w: real): (a: real, b: real, c: real,
                                      d: real, f: real,
                                      g: real, h: real, i: real)
    requires w > 0.0
  {
    (
      QuadraticSample(A, B, C, D, E, F, w, -1, -1),  // a
      QuadraticSample(A, B, C, D, E, F, w,  0, -1),  // b
      QuadraticSample(A, B, C, D, E, F, w,  1, -1),  // c
      QuadraticSample(A, B, C, D, E, F, w, -1,  0),  // d
      QuadraticSample(A, B, C, D, E, F, w,  1,  0),  // f
      QuadraticSample(A, B, C, D, E, F, w, -1,  1),  // g
      QuadraticSample(A, B, C, D, E, F, w,  0,  1),  // h
      QuadraticSample(A, B, C, D, E, F, w,  1,  1)   // i
    )
  }

  // 主要引理：Horn 算子在二次曲面上精确
  lemma HornExactOnQuadratic(A: real, B: real, C: real,
                             D: real, E: real, F: real,
                             w: real)
    requires w > 0.0
    ensures
      var (a, b, c, d, f, g, h, i) := QuadraticWindow(A, B, C, D, E, F, w);
      DzDx(a, b, c, d, f, g, h, i, w) == A  // 原点处 ∂z/∂x = A
      && DzDy(a, b, c, d, f, g, h, i, w) == B  // 原点处 ∂z/∂y = B
  {
    var (a, b, c, d, f, g, h, i) := QuadraticWindow(A, B, C, D, E, F, w);

    // 展开 DzDx 和 DzDy 的定义
    // DzDx = ((c + 2f + i) - (a + 2d + g)) / (8w)
    // DzDy = ((g + 2h + i) - (a + 2b + c)) / (8w)

    // 计算分子
    var numDx := NumDx(a, b, c, d, f, g, h, i);
    var numDy := NumDy(a, b, c, d, f, g, h, i);

    // 代入二次曲面采样值并化简
    // 通过代数展开可得：
    //   numDx = 8w * A
    //   numDy = 8w * B
    // 因此 DzDx = (8w * A) / (8w) = A, DzDy = B。

    // 以下断言由 Dafny 自动验证（利用实数算术）
    assert numDx == 8.0 * w * A;
    assert numDy == 8.0 * w * B;
  }

  // ------------------------------------------------------------------
  // 三次曲面：z = G x³
  // 在原点处，真实偏导数 ∂z/∂x = 0。
  // Horn 算子给出的 DzDx 余项应为 G w²。
  // ------------------------------------------------------------------

  // 三次曲面采样函数
  function CubicSample(G: real, w: real, p: int, q: int): real
    requires w > 0.0
  {
    var x := p as real * w;
    G * x * x * x
  }

  // 构建 3x3 窗口（中心在原点）
  function CubicWindow(G: real, w: real): (a: real, b: real, c: real,
                                           d: real, f: real,
                                           g: real, h: real, i: real)
    requires w > 0.0
  {
    (
      CubicSample(G, w, -1, -1),  // a
      CubicSample(G, w,  0, -1),  // b
      CubicSample(G, w,  1, -1),  // c
      CubicSample(G, w, -1,  0),  // d
      CubicSample(G, w,  1,  0),  // f
      CubicSample(G, w, -1,  1),  // g
      CubicSample(G, w,  0,  1),  // h
      CubicSample(G, w,  1,  1)   // i
    )
  }

  // 主要引理：Horn 算子在三次曲面 z = G x³ 上的余项
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures
      var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);
      DzDx(a, b, c, d, f, g, h, i, w) == G * w * w
  {
    var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);

    // 展开 DzDx 的定义
    // DzDx = ((c + 2f + i) - (a + 2d + g)) / (8w)

    // 计算分子
    var numDx := NumDx(a, b, c, d, f, g, h, i);

    // 代入三次曲面采样值并化简
    // 对于 z = G x³：
    //   a = G (-w)³ = -G w³
    //   b = 0
    //   c = G ( w)³ =  G w³
    //   d = G (-w)³ = -G w³
    //   f = G ( w)³ =  G w³
    //   g = G (-w)³ = -G w³
    //   h = 0
    //   i = G ( w)³ =  G w³
    //
    // 代入分子：
    //   numDx = (c + 2f + i) - (a + 2d + g)
    //         = (G w³ + 2G w³ + G w³) - (-G w³ + 2(-G w³) + (-G w³))
    //         = (4G w³) - (-4G w³)
    //         = 8G w³
    //
    // 因此 DzDx = (8G w³) / (8w) = G w²。

    assert numDx == 8.0 * G * w * w * w;
  }

  // 推论：余项阶为 O(w²)
  lemma CubicRemainderOrder(G: real, w: real)
    requires w > 0.0
    ensures
      var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);
      exists k: real :: |DzDx(a, b, c, d, f, g, h, i, w)| <= k * w * w
  {
    var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);
    CubicRemainder(G, w);
    // 取 k = |G|，则 |DzDx| = |G| w² ≤ |G| w²
    assert |DzDx(a, b, c, d, f, g, h, i, w)| == |G| * w * w;
  }
}

method Main() {
  print "GeoProofBench P-004 — Horn 坡度算子一致性证明\n";
  print "二次曲面精确性 + 三次曲面 O(w²) 余项\n";
  print "验证命令: dafny verify P004_consistency.dfy\n";
}
