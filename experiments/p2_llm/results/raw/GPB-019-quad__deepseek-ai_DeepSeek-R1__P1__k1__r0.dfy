// ===========================================================================
//  GeoProofBench · P-004
//  算子 : Horn (1981) 3x3 有限差分坡度在二次/三次曲面上的精度
//  覆盖 : GPB-019 (代数部分:二次曲面精确性,三次曲面余项)
//  环境 : Dafny 4.11
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  GPB-019 的核心代数结论: Horn 坡度算子
//    (1) 在任意二次曲面上精确恢复梯度系数 (A,B)
//    (2) 在三次曲面 z = Gx³ 上,中心点 x 方向坡度余项为 Gw²
//
//  本文件形式化这两条代数性质,解释:
//    (1) 为何二次曲面精确性成立 (线性差分 + 二次项对称抵消)
//    (2) 为何三次曲面余项为 O(w²) (泰勒展开的三阶项主导)
//
//  结合 P-001 的线性性质,构成 Horn 坡度算子的完整代数画像。
// ===========================================================================

module HornExactness {

  // ------------------------------------------------------------------
  // 3x3 窗口约定 (行偏移 q 向下为正)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // 注意:中心元 e 在 Horn 一阶差分中的权为 0, 不出现在算子签名
  // ------------------------------------------------------------------

  // ---- Horn 核函数 (与 P-001 一致) ----
  function NumDx(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (c + 2.0*f + i) - (a + 2.0*d + g) }

  function NumDy(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (g + 2.0*h + i) - (a + 2.0*b + c) }

  function DzDx(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
  requires w > 0.0
  { NumDx(a, b, c, d, f, g, h, i) / (8.0 * w) }

  function DzDy(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
  requires w > 0.0
  { NumDy(a, b, c, d, f, g, h, i) / (8.0 * w) }

  // ==================================================================
  // 二次曲面: z = A·x + B·y + C + D·x² + E·x·y + F·y²
  // 性质: Horn 坡度精确恢复系数 (A,B)
  // ==================================================================

  // ---- 二次曲面采样函数 ----
  function quadratic_z(A: real, B: real, C: real, D: real, E: real, F: real, 
                       x: real, y: real): real 
  { 
    A*x + B*y + C + D*x*x + E*x*y + F*y*y 
  }

  function quad_a(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, -w, -w) }
  function quad_b(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, 0.0, -w) }
  function quad_c(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, w, -w) }
  function quad_d(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, -w, 0.0) }
  function quad_f(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, w, 0.0) }
  function quad_g(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, -w, w) }
  function quad_h(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, 0.0, w) }
  function quad_i(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real 
  { quadratic_z(A, B, C, D, E, F, w, w) }

  // ---- 精确性引理 ----
  lemma QuadraticExactness(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures DzDx(quad_a(A,B,C,D,E,F,w), quad_b(A,B,C,D,E,F,w), quad_c(A,B,C,D,E,F,w),
                quad_d(A,B,C,D,E,F,w), quad_f(A,B,C,D,E,F,w),
                quad_g(A,B,C,D,E,F,w), quad_h(A,B,C,D,E,F,w), quad_i(A,B,C,D,E,F,w), w) 
            == A
    ensures DzDy(quad_a(A,B,C,D,E,F,w), quad_b(A,B,C,D,E,F,w), quad_c(A,B,C,D,E,F,w),
                quad_d(A,B,C,D,E,F,w), quad_f(A,B,C,D,E,F,w),
                quad_g(A,B,C,D,E,F,w), quad_h(A,B,C,D,E,F,w), quad_i(A,B,C,D,E,F,w), w) 
            == B
  {
    // 代数展开后,二次项对称抵消,线性项精确恢复 (A,B)
    // Dafny 自动验证代数恒等式
  }

  // ==================================================================
  // 三次曲面: z = G·x³
  // 性质: 中心点 x 方向坡度余项 = G·w²
  // ==================================================================

  // ---- 三次曲面采样函数 ----
  function cubic_z(G: real, x: real, y: real): real 
  { 
    G * x * x * x  // 无 y 依赖
  }

  function cubic_a(G: real, w: real): real { cubic_z(G, -w, -w) }
  function cubic_b(G: real, w: real): real { cubic_z(G, 0.0, -w) }
  function cubic_c(G: real, w: real): real { cubic_z(G, w, -w) }
  function cubic_d(G: real, w: real): real { cubic_z(G, -w, 0.0) }
  function cubic_f(G: real, w: real): real { cubic_z(G, w, 0.0) }
  function cubic_g(G: real, w: real): real { cubic_z(G, -w, w) }
  function cubic_h(G: real, w: real): real { cubic_z(G, 0.0, w) }
  function cubic_i(G: real, w: real): real { cubic_z(G, w, w) }

  // ---- 余项引理 ----
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures DzDx(cubic_a(G,w), cubic_b(G,w), cubic_c(G,w),
                cubic_d(G,w), cubic_f(G,w),
                cubic_g(G,w), cubic_h(G,w), cubic_i(G,w), w) 
            == G * w * w
  {
    // 直接计算分子:
    //   NumDx = [c + 2f + i] - [a + 2d + g]
    //         = [G·w³ + 2·(G·w³) + G·w³] - [(-G·w³) + 2·(-G·w³) + (-G·w³)]
    //         = (4G·w³) - (-4G·w³) = 8G·w³
    // 因此 DzDx = (8G·w³) / (8w) = G·w²
    // Dafny 自动验证代数恒等式
  }

  // ==================================================================
  // 结构注记
  // ------------------------------------------------------------------
  // 二次精确性成立的关键:
  //   1) 线性差分: 坡度算子是高程的线性泛函
  //   2) 二次对称性: 二次项在 3x3 窗口的差分计算中完全抵消
  //
  // 三次余项 O(w²) 的机制:
  //   泰勒展开: f(x) = f(0) + f'(0)x + f''(0)x²/2 + f'''(ξ)x³/6
  //   Horn 差分格式的截断误差来自三阶导数项,其贡献为 O(w²)
  //   本文件对 z=Gx³ 的特例给出了精确余项 Gw²
  //
  // 结合 P-001 的线性/平移不变性,完整刻画了 Horn 算子的代数行为。
  // ==================================================================
}

method Main() {
  print "GeoProofBench P-004 — Horn 坡度在二次/三次曲面上的精确性与余项\n";
  print "全部由编译期验证\n";
}
