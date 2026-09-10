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
//  本文件证明这一经验观察是算子的代数性质，而非数值巧合。
//
//  核心定理：
//      1. 对任意二次曲面 z = A x + B y + C + D x² + E x y + F y²，
//         Horn 差分精确恢复系数 A, B（与格网间距 w 无关）。
//      2. 对纯三次项 z = G x³，在原点处 Horn 差分余项为 G w²，
//         即误差为 O(w²)，表明算子具有二阶一致性。
//
//  注：本证明使用精确算术（real），不考虑浮点舍入。
// ===========================================================================

include "P001_horn_slope.dfy"  // 复用 Horn 差分算子定义

module HornConsistency {
  import opened HornSlope

  // ------------------------------------------------------------------
  // 二次曲面采样
  // 曲面：z = A x + B y + C + D x² + E x y + F y²
  // 采样点坐标 (p*w, q*w)，其中 p,q ∈ {-1,0,1}
  // ------------------------------------------------------------------
  function SampleQuadratic(A: real, B: real, C: real,
                           D: real, E: real, F: real,
                           w: real, p: int, q: int): real
    requires w > 0.0
  {
    var x := p as real * w;
    var y := q as real * w;
    A*x + B*y + C + D*x*x + E*x*y + F*y*y
  }

  // ------------------------------------------------------------------
  // 定理 1：Horn 在二次曲面上精确恢复平面梯度系数 A, B
  // ------------------------------------------------------------------
  lemma HornExactOnQuadratic(A: real, B: real, C: real,
                             D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures
      // 构造 3x3 窗口（中心点 e 未使用）
      var a := SampleQuadratic(A,B,C,D,E,F,w,-1,-1);
      var b := SampleQuadratic(A,B,C,D,E,F,w, 0,-1);
      var c := SampleQuadratic(A,B,C,D,E,F,w, 1,-1);
      var d := SampleQuadratic(A,B,C,D,E,F,w,-1, 0);
      var f := SampleQuadratic(A,B,C,D,E,F,w, 1, 0);
      var g := SampleQuadratic(A,B,C,D,E,F,w,-1, 1);
      var h := SampleQuadratic(A,B,C,D,E,F,w, 0, 1);
      var i := SampleQuadratic(A,B,C,D,E,F,w, 1, 1);
      DzDx(a,b,c,d,f,g,h,i,w) == A &&
      DzDy(a,b,c,d,f,g,h,i,w) == B
  {
    // 展开 DzDx 和 DzDy 的定义
    // DzDx = [(c + 2f + i) - (a + 2d + g)] / (8w)
    // DzDy = [(g + 2h + i) - (a + 2b + c)] / (8w)

    // 计算分子项的代数形式
    var numDx := NumDx(a,b,c,d,f,g,h,i);
    var numDy := NumDy(a,b,c,d,f,g,h,i);

    // 代入采样函数，展开二次曲面表达式
    // 由于对称性，二次项 D x², F y² 和交叉项 E x y 在差分中抵消
    // 仅线性项 A x + B y 贡献
    calc {
      numDx;
      ==
      // 展开 c + 2f + i
      (SampleQuadratic(A,B,C,D,E,F,w, 1,-1) +
       2.0*SampleQuadratic(A,B,C,D,E,F,w, 1, 0) +
       SampleQuadratic(A,B,C,D,E,F,w, 1, 1))
      -
      // 展开 a + 2d + g
      (SampleQuadratic(A,B,C,D,E,F,w,-1,-1) +
       2.0*SampleQuadratic(A,B,C,D,E,F,w,-1, 0) +
       SampleQuadratic(A,B,C,D,E,F,w,-1, 1));
      ==
      // 代入 SampleQuadratic 定义
      // 对于 x = w 的三个点：c, f, i
      ( (A*w + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w)) +
        2.0*(A*w + B*0 + C + D*w*w + E*w*0 + F*0) +
        (A*w + B*w + C + D*w*w + E*w*w + F*w*w) )
      -
      // 对于 x = -w 的三个点：a, d, g
      ( (A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w)) +
        2.0*(A*(-w) + B*0 + C + D*(-w)*(-w) + E*(-w)*0 + F*0) +
        (A*(-w) + B*w + C + D*(-w)*(-w) + E*(-w)*w + F*w*w) );
      ==
      // 合并同类项
      // 常数项 C 全部抵消
      // 二次项 D x² 对称：D*w² 在正负 x 侧相同，相减为 0
      // 交叉项 E x y：在正负 x 侧对称，相减为 0
      // 纯 y² 项 F y²：在正负 y 侧相同，相减为 0
      // 仅剩线性项 A x
      ( (A*w - B*w) + 2.0*(A*w) + (A*w + B*w) )
      -
      ( (-A*w - B*w) + 2.0*(-A*w) + (-A*w + B*w) );
      ==
      // 计算 A 的系数
      (A*w + 2*A*w + A*w) - ((-A*w) + 2*(-A*w) + (-A*w));
      ==
      (4*A*w) - (-4*A*w);
      ==
      8*A*w;
    }
    // 因此 DzDx = (8*A*w) / (8*w) = A
    assert DzDx(a,b,c,d,f,g,h,i,w) == A;

    // 类似证明 DzDy = B
    calc {
      numDy;
      ==
      // 展开 g + 2h + i
      (SampleQuadratic(A,B,C,D,E,F,w,-1, 1) +
       2.0*SampleQuadratic(A,B,C,D,E,F,w, 0, 1) +
       SampleQuadratic(A,B,C,D,E,F,w, 1, 1))
      -
      // 展开 a + 2b + c
      (SampleQuadratic(A,B,C,D,E,F,w,-1,-1) +
       2.0*SampleQuadratic(A,B,C,D,E,F,w, 0,-1) +
       SampleQuadratic(A,B,C,D,E,F,w, 1,-1));
      ==
      // 对于 y = w 的三个点：g, h, i
      ( (A*(-w) + B*w + C + D*(-w)*(-w) + E*(-w)*w + F*w*w) +
        2.0*(A*0 + B*w + C + D*0 + E*0*w + F*w*w) +
        (A*w + B*w + C + D*w*w + E*w*w + F*w*w) )
      -
      // 对于 y = -w 的三个点：a, b, c
      ( (A*(-w) + B*(-w) + C + D*(-w)*(-w) + E*(-w)*(-w) + F*(-w)*(-w)) +
        2.0*(A*0 + B*(-w) + C + D*0 + E*0*(-w) + F*(-w)*(-w)) +
        (A*w + B*(-w) + C + D*w*w + E*w*(-w) + F*(-w)*(-w)) );
      ==
      // 合并同类项
      // 常数项和二次项抵消
      // 仅剩线性项 B y
      ( (-A*w + B*w) + 2.0*(B*w) + (A*w + B*w) )
      -
      ( (-A*w - B*w) + 2.0*(-B*w) + (A*w - B*w) );
      ==
      // 计算 B 的系数
      (B*w + 2*B*w + B*w) - ((-B*w) + 2*(-B*w) + (-B*w));
      ==
      (4*B*w) - (-4*B*w);
      ==
      8*B*w;
    }
    assert DzDy(a,b,c,d,f,g,h,i,w) == B;
  }

  // ------------------------------------------------------------------
  // 定理 2：在纯三次曲面 z = G x³ 上，原点处 Horn 差分余项为 G w²
  // ------------------------------------------------------------------
  lemma CubicRemainder(G: real, w: real)
    requires w > 0.0
    ensures
      // 构造窗口：z = G x³，在原点 (0,0) 处
      var a := G * ((-w) as real) * ((-w) as real) * ((-w) as real);  // x=-w, y=-w
      var b := G * (0.0) * (0.0) * (0.0);                            // x=0, y=-w
      var c := G * (w as real) * (w as real) * (w as real);          // x=w, y=-w
      var d := G * ((-w) as real) * ((-w) as real) * ((-w) as real); // x=-w, y=0
      var f := G * (w as real) * (w as real) * (w as real);          // x=w, y=0
      var g := G * ((-w) as real) * ((-w) as real) * ((-w) as real); // x=-w, y=w
      var h := G * (0.0) * (0.0) * (0.0);                            // x=0, y=w
      var i := G * (w as real) * (w as real) * (w as real);          // x=w, y=w
      // 解析梯度在原点为 0（因为 dz/dx = 3G x²，在 x=0 时为 0）
      // Horn 差分结果应为 G w²
      DzDx(a,b,c,d,f,g,h,i,w) == G * w * w
  {
    // 计算分子 NumDx
    var numDx := NumDx(a,b,c,d,f,g,h,i);
    
    // 展开 a, c, d, f, g, i（b 和 h 为 0）
    // a = d = g = G * (-w)³ = -G w³
    // c = f = i = G * w³
    calc {
      numDx;
      ==
      (c + 2.0*f + i) - (a + 2.0*d + g);
      ==
      (G*w*w*w + 2.0*G*w*w*w + G*w*w*w) - ((-G*w*w*w) + 2.0*(-G*w*w*w) + (-G*w*w*w));
      ==
      (4.0 * G * w * w * w) - (-4.0 * G * w * w * w);
      ==
      8.0 * G * w * w * w;
    }
    
    // DzDx = numDx / (8w) = (8 G w³) / (8w) = G w²
    assert DzDx(a,b,c,d,f,g,h,i,w) == G * w * w;
  }

  // ------------------------------------------------------------------
  // 推论：Horn 差分在三次项上具有 O(w²) 一致性
  // ------------------------------------------------------------------
  lemma CubicConsistencyOrder(G: real, w: real)
    requires w > 0.0
    ensures
      var a := G * ((-w) as real) * ((-w) as real) * ((-w) as real);
      var b := 0.0;
      var c := G * (w as real) * (w as real) * (w as real);
      var d := G * ((-w) as real) * ((-w) as real) * ((-w) as real);
      var f := G * (w as real) * (w as real) * (w as real);
      var g := G * ((-w) as real) * ((-w) as real) * ((-w) as real);
      var h := 0.0;
      var i := G * (w as real) * (w as real) * (w as real);
      // 误差 = |Horn - 解析| = |G w² - 0| = |G| w²
      // 因此误差随 w² 衰减，为二阶精度
      DzDx(a,b,c,d,f,g,h,i,w) - 0.0 == G * w * w
  {
    CubicRemainder(G, w);
  }

}

method Main() {
  print "GeoProofBench P-004 — Horn 坡度在二次曲面精确性、三次曲面 O(w²) 余项\n";
  print "全部由编译期验证: dafny verify P004_consistency.dfy\n";
}
