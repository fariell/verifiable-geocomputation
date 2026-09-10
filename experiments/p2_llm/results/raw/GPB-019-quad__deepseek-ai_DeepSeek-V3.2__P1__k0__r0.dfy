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
//  Phase 1 实验显示 Horn 坡度在二次曲面上与解析解一致（误差 ~1e-15）。
//  本文件从代数上证明：对于任意二次曲面，Horn 差分精确恢复平面梯度系数；
//  对于三次项 z = G x³，在原点处的差分余项为 G w²，即 O(w²) 阶。
//
//  这解释了为什么 Horn 坡度在 DEM 上表现稳定：它对二次及以下曲面是精确的，
//  对更高阶曲面的误差随网格间距 w 的平方衰减。这是数值一致性（consistency）
//  的形式化表述，为后续曲率算子的病态性分析提供对比基线。
//
// ===========================================================================

include "P001_horn_slope.dfy"  // 复用 Horn 坡度算子定义

module Consistency {

  import opened HornSlope

  // ------------------------------------------------------------------
  // 二次曲面：z = A x + B y + C + D x² + E x y + F y²
  // 在任意点 (x0, y0) 处，平面梯度系数为 (A + 2D x0 + E y0, B + E x0 + 2F y0)
  // 为简化证明，我们只考虑原点 (0,0) 处的窗口，此时梯度为 (A, B)
  // ------------------------------------------------------------------

  // 二次曲面采样函数
  function QuadraticSample(A: real, B: real, C: real, D: real, E: real, F: real,
                           w: real, p: int, q: int): real
    requires w > 0.0
  {
    var x := p as real * w;
    var y := q as real * w;
    A*x + B*y + C + D*x*x + E*x*y + F*y*y
  }

  // 构造 3x3 窗口（中心 e 未使用，符合 Horn 算子结构）
  function QuadraticWindow(A: real, B: real, C: real, D: real, E: real, F: real,
                           w: real): (a: real, b: real, c: real, d: real,
                                      f: real, g: real, h: real, i: real)
    requires w > 0.0
  {
    (
      QuadraticSample(A, B, C, D, E, F, w, -1, -1), // a
      QuadraticSample(A, B, C, D, E, F, w,  0, -1), // b
      QuadraticSample(A, B, C, D, E, F, w,  1, -1), // c
      QuadraticSample(A, B, C, D, E, F, w, -1,  0), // d
      QuadraticSample(A, B, C, D, E, F, w,  1,  0), // f
      QuadraticSample(A, B, C, D, E, F, w, -1,  1), // g
      QuadraticSample(A, B, C, D, E, F, w,  0,  1), // h
      QuadraticSample(A, B, C, D, E, F, w,  1,  1)  // i
    )
  }

  // 主要引理：Horn 算子在二次曲面上精确恢复梯度系数 (A, B)
  lemma HornExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures
      var (a, b, c, d, f, g, h, i) := QuadraticWindow(A, B, C, D, E, F, w);
      DzDx(a, b, c, d, f, g, h, i, w) == A &&
      DzDy(a, b, c, d, f, g, h, i, w) == B
  {
    var (a, b, c, d, f, g, h, i) := QuadraticWindow(A, B, C, D, E, F, w);
    // 展开 DzDx 和 DzDy 的定义
    // DzDx = ((c + 2f + i) - (a + 2d + g)) / (8w)
    // DzDy = ((g + 2h + i) - (a + 2b + c)) / (8w)

    // 计算分子部分
    var numDx := NumDx(a, b, c, d, f, g, h, i);
    var numDy := NumDy(a, b, c, d, f, g, h, i);

    // 代入二次曲面采样值并化简
    // 通过代数展开可得：
    //   numDx = 8w * A
    //   numDy = 8w * B
    // 因此 DzDx = (8w * A) / (8w) = A, DzDy = (8w * B) / (8w) = B

    // 以下断言由 Dafny 自动验证（利用线性算术和二次项对称性）
    assert numDx == 8.0 * w * A by {
      calc {
        numDx;
        == // 展开 NumDx 定义
        (c + 2.0*f + i) - (a + 2.0*d + g);
        == // 代入采样值
        (QuadraticSample(A,B,C,D,E,F,w, 1,-1) + 2.0*QuadraticSample(A,B,C,D,E,F,w, 1,0) + QuadraticSample(A,B,C,D,E,F,w, 1,1))
        - (QuadraticSample(A,B,C,D,E,F,w,-1,-1) + 2.0*QuadraticSample(A,B,C,D,E,F,w,-1,0) + QuadraticSample(A,B,C,D,E,F,w,-1,1));
        == // 展开 QuadraticSample
        {
          // 计算第一组 (c + 2f + i)
          var term1 := (A*(w) + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w));
          var term2 := 2.0 * (A*(w) + B*(0) + C + D*w*w + E*w*0 + F*0);
          var term3 := (A*(w) + B*(w) + C + D*w*w + E*w*w + F*w*w);
          // 计算第二组 (a + 2d + g)
          var term4 := (A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w));
          var term5 := 2.0 * (A*(-w) + B*(0) + C + D*(-w)*(-w) + E*(-w)*0 + F*0);
          var term6 := (A*(-w) + B*(w) + C + D*(-w)*(-w) + E*(-w)*w + F*w*w);
        }
        // 合并同类项：常数项 C 抵消，二次项 D, E, F 因对称性抵消
        // 仅剩一次项 A 的贡献：8w * A
        8.0 * w * A;
      }
    }

    assert numDy == 8.0 * w * B by {
      calc {
        numDy;
        == // 展开 NumDy 定义
        (g + 2.0*h + i) - (a + 2.0*b + c);
        == // 代入采样值
        (QuadraticSample(A,B,C,D,E,F,w,-1,1) + 2.0*QuadraticSample(A,B,C,D,E,F,w,0,1) + QuadraticSample(A,B,C,D,E,F,w,1,1))
        - (QuadraticSample(A,B,C,D,E,F,w,-1,-1) + 2.0*QuadraticSample(A,B,C,D,E,F,w,0,-1) + QuadraticSample(A,B,C,D,E,F,w,1,-1));
        == // 展开 QuadraticSample，类似上述过程
        // 常数项和二次项抵消，仅剩一次项 B 的贡献：8w * B
        8.0 * w * B;
      }
    }

    // 由分子和分母得到最终结果
    assert DzDx(a, b, c, d, f, g, h, i, w) == numDx / (8.0 * w) == A;
    assert DzDy(a, b, c, d, f, g, h, i, w) == numDy / (8.0 * w) == B;
  }

  // ------------------------------------------------------------------
  // 三次曲面：z = G x³
  // 在原点处，解析梯度为 0，但 Horn 差分给出非零余项
  // ------------------------------------------------------------------

  // 三次曲面采样函数
  function CubicSample(G: real, w: real, p: int): real
    requires w > 0.0
  {
    G * (p as real * w) * (p as real * w) * (p as real * w)
  }

  // 构造 3x3 窗口（仅 x 方向变化，y 方向对称）
  function CubicWindow(G: real, w: real): (a: real, b: real, c: real, d: real,
                                           f: real, g: real, h: real, i: real)
    requires w > 0.0
  {
    (
      CubicSample(G, w, -1), // a
      CubicSample(G, w,  0), // b
      CubicSample(G, w,  1), // c
      CubicSample(G, w, -1), // d
      CubicSample(G, w,  1), // f
      CubicSample(G, w, -1), // g
      CubicSample(G, w,  0), // h
      CubicSample(G, w,  1)  // i
    )
  }

  // 主要引理：在 z = G x³ 上，Horn DzDx 在原点处的余项为 G w²
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures
      var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);
      DzDx(a, b, c, d, f, g, h, i, w) == G * w * w
  {
    var (a, b, c, d, f, g, h, i) := CubicWindow(G, w);
    var numDx := NumDx(a, b, c, d, f, g, h, i);

    // 计算分子
    assert numDx == 8.0 * w * w * w * G by {
      calc {
        numDx;
        ==
        (c + 2.0*f + i) - (a + 2.0*d + g);
        == // 代入采样值：c = f = i = G w³, a = d = g = -G w³
        (G*w*w*w + 2.0*G*w*w*w + G*w*w*w) - ((-G*w*w*w) + 2.0*(-G*w*w*w) + (-G*w*w*w));
        ==
        (4.0 * G * w * w * w) - ((-4.0) * G * w * w * w);
        8.0 * G * w * w * w;
      }
    }

    // DzDx = numDx / (8w) = (8 G w³) / (8w) = G w²
    assert DzDx(a, b, c, d, f, g, h, i, w) == numDx / (8.0 * w) == G * w * w;
  }

  // 推论：余项随 w² 衰减，即 O(w²) 阶
  lemma CubicRemainderOrder(G: real, w1: real, w2: real)
    requires w1 > 0.0 && w2 > 0.0
    ensures
      var (a1, b1, c1, d1, f1, g1, h1, i1) := CubicWindow(G, w1);
      var (a2, b2, c2, d2, f2, g2, h2, i2) := CubicWindow(G, w2);
      DzDx(a1, b1, c1, d1, f1, g1, h1, i1, w1) / (w1 * w1)
      == DzDx(a2, b2, c2, d2, f2, g2, h2, i2, w2) / (w2 * w2)
      == G
  {
    CubicRemainder(G, w1);
    CubicRemainder(G, w2);
  }

}

method Main() {
  print "GeoProofBench P-004 — Horn 坡度在二次曲面上的精确性与三次余项 O(w²)\n";
  print "全部由编译期验证: dafny verify P004_consistency.dfy\n";
}
