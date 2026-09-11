// ===========================================================================
//  GeoProofBench · P-001 (algebraic core of GPB-019)
//  算子 : Horn (1981) 3x3 一阶差分(坡度)
//  覆盖 : 平面上的精确恢复
//  环境 : Dafny 4.11
// ===========================================================================

module HornSlopeExact {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-003 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn 一阶差分给出:
  //   ∂z/∂x = [ (c - a) + 2*(f - d) + (i - g) ] / (8w)
  //   ∂z/∂y = [ (g - a) + 2*(h - b) + (i - c) ] / (8w)
  // -------------------------------------------

  // Horn 坡度算子 (x方向)
  function HornDzDx(a: real, d: real, g: real, c: real, f: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (c - a) + 2.0*(f - d) + (i - g) ) / (8.0 * w)
  }

  // Horn 坡度算子 (y方向)
  function HornDzDy(a: real, b: real, c: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (g - a) + 2.0*(h - b) + (i - c) ) / (8.0 * w)
  }

  // 平面高程函数: z = A*x + B*y + C
  function PlaneAt(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // 网格点高程 (中心 e 在 (0,0))
  function a(A: real, B: real, C: real, w: real): real { PlaneAt(-w, -w, A, B, C) }
  function b(A: real, B: real, C: real, w: real): real { PlaneAt( 0.0, -w, A, B, C) }
  function c(A: real, B: real, C: real, w: real): real { PlaneAt( w, -w, A, B, C) }
  function d(A: real, B: real, C: real, w: real): real { PlaneAt(-w,  0.0, A, B, C) }
  function e(A: real, B: real, C: real, w: real): real { PlaneAt( 0.0, 0.0, A, B, C) }
  function f(A: real, B: real, C: real, w: real): real { PlaneAt( w,  0.0, A, B, C) }
  function g(A: real, B: real, C: real, w: real): real { PlaneAt(-w,  w, A, B, C) }
  function h(A: real, B: real, C: real, w: real): real { PlaneAt( 0.0, w, A, B, C) }
  function i(A: real, B: real, C: real, w: real): real { PlaneAt( w,  w, A, B, C) }

  // ==================================================================
  // 核心定理: 平面上 Horn 算子精确恢复梯度分量
  // ==================================================================
  lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDzDx(
        a(A,B,C,w), d(A,B,C,w), g(A,B,C,w),
        c(A,B,C,w), f(A,B,C,w), i(A,B,C,w), w) == A
    ensures HornDzDy(
        a(A,B,C,w), b(A,B,C,w), c(A,B,C,w),
        g(A,B,C,w), h(A,B,C,w), i(A,B,C,w), w) == B
  {
    // 展开所有网格点高程
    // a: (-w,-w) -> A*(-w) + B*(-w) + C
    // c: (w,-w)  -> A*w + B*(-w) + C
    // d: (-w,0)  -> A*(-w) + B*0 + C
    // f: (w,0)   -> A*w + B*0 + C
    // g: (-w,w)  -> A*(-w) + B*w + C
    // i: (w,w)   -> A*w + B*w + C

    // 计算 DzDx 分子分量
    assert c(A,B,C,w) - a(A,B,C,w) == (A*w - B*w + C) - (-A*w - B*w + C) == 2.0 * A * w;
    assert f(A,B,C,w) - d(A,B,C,w) == (A*w + C) - (-A*w + C) == 2.0 * A * w;
    assert i(A,B,C,w) - g(A,B,C,w) == (A*w + B*w + C) - (-A*w + B*w + C) == 2.0 * A * w;

    // 合并 DzDx 分子
    var num_x := (c(A,B,C,w) - a(A,B,C,w)) + 
                2.0*(f(A,B,C,w) - d(A,B,C,w)) + 
                (i(A,B,C,w) - g(A,B,C,w));
    assert num_x == 2.0*A*w + 2.0*(2.0*A*w) + 2.0*A*w == 8.0 * A * w;

    // 最终 DzDx = (8Aw)/(8w) = A
    assert HornDzDx(a(A,B,C,w), d(A,B,C,w), g(A,B,C,w), 
                    c(A,B,C,w), f(A,B,C,w), i(A,B,C,w), w) 
            == num_x / (8.0 * w) == A;

    // 计算 DzDy 分子分量
    assert g(A,B,C,w) - a(A,B,C,w) == (-A*w + B*w + C) - (-A*w - B*w + C) == 2.0 * B * w;
    assert h(A,B,C,w) - b(A,B,C,w) == (B*w + C) - (-B*w + C) == 2.0 * B * w;
    assert i(A,B,C,w) - c(A,B,C,w) == (A*w + B*w + C) - (A*w - B*w + C) == 2.0 * B * w;

    // 合并 DzDy 分子
    var num_y := (g(A,B,C,w) - a(A,B,C,w)) + 
                2.0*(h(A,B,C,w) - b(A,B,C,w)) + 
                (i(A,B,C,w) - c(A,B,C,w));
    assert num_y == 2.0*B*w + 2.0*(2.0*B*w) + 2.0*B*w == 8.0 * B * w;

    // 最终 DzDy = (8Bw)/(8w) = B
    assert HornDzDy(a(A,B,C,w), b(A,B,C,w), c(A,B,C,w), 
                    g(A,B,C,w), h(A,B,C,w), i(A,B,C,w), w) 
            == num_y / (8.0 * w) == B;
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes (algebraic core of GPB-019)\n";
  print "Verified by Dafny\n";
}
