// ===========================================================================
//  GeoProofBench · P-001 (Horn slope exactness)
//  算子 : Horn (1981) 有限差分坡度算子
//  定理 : 在平面 z = A*x + B*y + C 上，Horn 差分精确恢复 A 和 B
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope_exact.dfy
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定 (p 向右, q 向下)
  //
  //     a(-w,-w)   b(0,-w)   c(w,-w)
  //     d(-w,0)     e(0,0)    f(w,0)
  //     g(-w,w)    h(0,w)    i(w,w)
  //
  // Horn (1981) 有限差分坡度算子:
  //   DzDx = [ (c + 2f + i) - (a + 2d + g) ] / (8 * w)
  //   DzDy = [ (g + 2h + i) - (a + 2b + c) ] / (8 * w)
  // ------------------------------------------------------------------

  // 平面高程函数
  function plane(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // 窗口点高程计算
  function Qa(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(-w, -w, A, B, C) }
  
  function Qb(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(0.0, -w, A, B, C) }
  
  function Qc(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(w, -w, A, B, C) }
  
  function Qd(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(-w, 0.0, A, B, C) }
  
  function Qe(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(0.0, 0.0, A, B, C) }
  
  function Qf(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(w, 0.0, A, B, C) }
  
  function Qg(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(-w, w, A, B, C) }
  
  function Qh(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(0.0, w, A, B, C) }
  
  function Qi(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { plane(w, w, A, B, C) }

  // Horn 有限差分算子
  function HornDzDx(
    a: real, d: real, g: real,  // 左列
    c: real, f: real, i: real,  // 右列
    w: real
  ): real
    requires w > 0.0
  {
    ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w)
  }

  function HornDzDy(
    a: real, b: real, c: real,  // 顶行
    g: real, h: real, i: real,  // 底行
    w: real
  ): real
    requires w > 0.0
  {
    ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w)
  }

  // ==================================================================
  // 主定理: 在平面上 Horn 差分精确恢复梯度分量
  // ==================================================================
  lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDzDx(
        Qa(A,B,C,w), Qd(A,B,C,w), Qg(A,B,C,w),
        Qc(A,B,C,w), Qf(A,B,C,w), Qi(A,B,C,w),
        w
      ) == A
    ensures HornDzDy(
        Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
        Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w),
        w
      ) == B
  {
    // 展开所有点的高程表达式
    assert Qa(A,B,C,w) == A*(-w) + B*(-w) + C;
    assert Qb(A,B,C,w) == A*0.0 + B*(-w) + C;
    assert Qc(A,B,C,w) == A*w + B*(-w) + C;
    assert Qd(A,B,C,w) == A*(-w) + B*0.0 + C;
    assert Qe(A,B,C,w) == A*0.0 + B*0.0 + C;
    assert Qf(A,B,C,w) == A*w + B*0.0 + C;
    assert Qg(A,B,C,w) == A*(-w) + B*w + C;
    assert Qh(A,B,C,w) == A*0.0 + B*w + C;
    assert Qi(A,B,C,w) == A*w + B*w + C;

    // 计算 DzDx 的分子部分
    calc {
      (Qc(A,B,C,w) + 2.0*Qf(A,B,C,w) + Qi(A,B,C,w)) 
        - (Qa(A,B,C,w) + 2.0*Qd(A,B,C,w) + Qg(A,B,C,w));
      == 
        ( (A*w - B*w + C) + 2.0*(A*w + C) + (A*w + B*w + C) ) 
        - ( (-A*w - B*w + C) + 2.0*(-A*w + C) + (-A*w + B*w + C) );
      == 
        (A*w - B*w + C + 2.0*A*w + 2.0*C + A*w + B*w + C) 
        - (-A*w - B*w + C -2.0*A*w + 2.0*C -A*w + B*w + C);
      == 
        (4.0*A*w + 4.0*C) - (-4.0*A*w + 4.0*C);
      == 8.0 * A * w;
    }
    // 最终 DzDx = (8Aw)/(8w) = A
    assert HornDzDx(Qa(A,B,C,w), Qd(A,B,C,w), Qg(A,B,C,w),
                   Qc(A,B,C,w), Qf(A,B,C,w), Qi(A,B,C,w), w) 
           == (8.0 * A * w) / (8.0 * w) 
           == A;

    // 计算 DzDy 的分子部分
    calc {
      (Qg(A,B,C,w) + 2.0*Qh(A,B,C,w) + Qi(A,B,C,w)) 
        - (Qa(A,B,C,w) + 2.0*Qb(A,B,C,w) + Qc(A,B,C,w));
      == 
        ( (-A*w + B*w + C) + 2.0*(B*w + C) + (A*w + B*w + C) ) 
        - ( (-A*w - B*w + C) + 2.0*(-B*w + C) + (A*w - B*w + C) );
      == 
        (-A*w + B*w + C + 2.0*B*w + 2.0*C + A*w + B*w + C) 
        - (-A*w - B*w + C -2.0*B*w + 2.0*C + A*w - B*w + C);
      == 
        (4.0*B*w + 4.0*C) - (-4.0*B*w + 4.0*C);
      == 8.0 * B * w;
    }
    // 最终 DzDy = (8Bw)/(8w) = B
    assert HornDzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                   Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w) 
           == (8.0 * B * w) / (8.0 * w) 
           == B;
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes\n";
  print "验证命令: dafny verify P001_horn_slope_exact.dfy\n";
}
