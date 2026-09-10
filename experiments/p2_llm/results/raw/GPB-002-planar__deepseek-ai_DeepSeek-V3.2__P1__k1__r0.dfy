// ===========================================================================
//  GeoProofBench · P-001
//  文件 : formal/dafny/P001_horn_slope_exact.dfy
//  算子 : Horn (1981) 有限差分坡度
//  覆盖 : GPB-019 的代数核（平面上的精确恢复）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope_exact.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在平面 z = A*x + B*y + C 上，Horn 有限差分估计 DzDx 和 DzDy
//        精确恢复系数 A 和 B（恒等式，不仅仅是渐近一致）。
//
//  这是 GPB-019 的代数部分，与实验部分（网格间距 w → 0 的一致性）互补。
//  本证明不依赖于 w 的大小，只要 w > 0，估计值就精确等于解析值。
//
// ===========================================================================

module HornSlopeExact {

  // ------------------------------------------------------------------
  // 3x3 窗口约定（与 GeoProofBench 标准一致：x 向右，y 向下）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 有限差分坡度算子：
  //   DzDx = ( (c + 2f + i) - (a + 2d + g) ) / (8 * w)
  //   DzDy = ( (g + 2h + i) - (a + 2b + c) ) / (8 * w)
  // ------------------------------------------------------------------

  // 平面函数：z = A*x + B*y + C
  function Plane(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // 网格点坐标（以中心 e 为原点 (0,0)）
  function Qa(A: real, B: real, C: real, w: real): real
    ensures Qa(A, B, C, w) == Plane(-w, -w, A, B, C)
  {
    Plane(-w, -w, A, B, C)
  }
  function Qb(A: real, B: real, C: real, w: real): real
    ensures Qb(A, B, C, w) == Plane( 0, -w, A, B, C)
  {
    Plane( 0, -w, A, B, C)
  }
  function Qc(A: real, B: real, C: real, w: real): real
    ensures Qc(A, B, C, w) == Plane( w, -w, A, B, C)
  {
    Plane( w, -w, A, B, C)
  }
  function Qd(A: real, B: real, C: real, w: real): real
    ensures Qd(A, B, C, w) == Plane(-w,  0, A, B, C)
  {
    Plane(-w,  0, A, B, C)
  }
  function Qe(A: real, B: real, C: real, w: real): real
    ensures Qe(A, B, C, w) == Plane( 0,  0, A, B, C)
  {
    Plane( 0,  0, A, B, C)
  }
  function Qf(A: real, B: real, C: real, w: real): real
    ensures Qf(A, B, C, w) == Plane( w,  0, A, B, C)
  {
    Plane( w,  0, A, B, C)
  }
  function Qg(A: real, B: real, C: real, w: real): real
    ensures Qg(A, B, C, w) == Plane(-w,  w, A, B, C)
  {
    Plane(-w,  w, A, B, C)
  }
  function Qh(A: real, B: real, C: real, w: real): real
    ensures Qh(A, B, C, w) == Plane( 0,  w, A, B, C)
  {
    Plane( 0,  w, A, B, C)
  }
  function Qi(A: real, B: real, C: real, w: real): real
    ensures Qi(A, B, C, w) == Plane( w,  w, A, B, C)
  {
    Plane( w,  w, A, B, C)
  }

  // Horn 有限差分算子的分子部分（未除以 8w）
  function NumDzDx(a: real, c: real, d: real, f: real, g: real, i: real): real
  {
    (c + 2.0 * f + i) - (a + 2.0 * d + g)
  }
  function NumDzDy(a: real, b: real, c: real, g: real, h: real, i: real): real
  {
    (g + 2.0 * h + i) - (a + 2.0 * b + c)
  }

  // Horn 坡度估计
  function DzDx(a: real, c: real, d: real, f: real, g: real, i: real, w: real): real
    requires w > 0.0
  {
    NumDzDx(a, c, d, f, g, i) / (8.0 * w)
  }
  function DzDy(a: real, b: real, c: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    NumDzDy(a, b, c, g, h, i) / (8.0 * w)
  }

  // ==================================================================
  // 主要引理：在平面上 Horn 坡度估计精确恢复 A 和 B
  // ==================================================================
  lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                 Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w), w) == A
    ensures DzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                 Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w) == B
  {
    // 展开所有网格点高程
    calc {
      NumDzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
              Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w));
      ==
      ((Plane( w, -w, A, B, C) + 2.0 * Plane( w,  0, A, B, C) + Plane( w,  w, A, B, C)) -
       (Plane(-w, -w, A, B, C) + 2.0 * Plane(-w,  0, A, B, C) + Plane(-w,  w, A, B, C)));
      ==
      (((A*w + B*(-w) + C) + 2.0*(A*w + B*0 + C) + (A*w + B*w + C)) -
       ((A*(-w) + B*(-w) + C) + 2.0*(A*(-w) + B*0 + C) + (A*(-w) + B*w + C)));
      ==
      ((A*w - B*w + C + 2.0*A*w + 2.0*C + A*w + B*w + C) -
       (-A*w - B*w + C - 2.0*A*w + 2.0*C - A*w + B*w + C));
      ==
      ((4.0*A*w + 4.0*C) - (-4.0*A*w + 4.0*C));
      ==
      8.0 * A * w;
    }
    assert NumDzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                   Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w)) == 8.0 * A * w;

    calc {
      NumDzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
              Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w));
      ==
      ((Plane(-w, w, A, B, C) + 2.0 * Plane(0, w, A, B, C) + Plane(w, w, A, B, C)) -
       (Plane(-w, -w, A, B, C) + 2.0 * Plane(0, -w, A, B, C) + Plane(w, -w, A, B, C)));
      ==
      (((A*(-w) + B*w + C) + 2.0*(A*0 + B*w + C) + (A*w + B*w + C)) -
       ((A*(-w) + B*(-w) + C) + 2.0*(A*0 + B*(-w) + C) + (A*w + B*(-w) + C)));
      ==
      ((-A*w + B*w + C + 2.0*B*w + 2.0*C + A*w + B*w + C) -
       (-A*w - B*w + C - 2.0*B*w + 2.0*C + A*w - B*w + C));
      ==
      ((4.0*B*w + 4.0*C) - (-4.0*B*w + 4.0*C));
      ==
      8.0 * B * w;
    }
    assert NumDzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                   Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w)) == 8.0 * B * w;

    // 除以 8w 即得 A 和 B
    assert DzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w), w) == A;
    assert DzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w) == B;
  }

  // ==================================================================
  // 辅助引理：平移不变性（平面上的常数偏移不影响坡度估计）
  // ==================================================================
  lemma TranslationInvariant(A: real, B: real, C: real, K: real, w: real)
    requires w > 0.0
    ensures DzDx(Qa(A,B,C,w) + K, Qc(A,B,C,w) + K, Qd(A,B,C,w) + K,
                 Qf(A,B,C,w) + K, Qg(A,B,C,w) + K, Qi(A,B,C,w) + K, w)
            == DzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                    Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w), w)
    ensures DzDy(Qa(A,B,C,w) + K, Qb(A,B,C,w) + K, Qc(A,B,C,w) + K,
                 Qg(A,B,C,w) + K, Qh(A,B,C,w) + K, Qi(A,B,C,w) + K, w)
            == DzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                    Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w)
  {
    // 分子中的常数项相互抵消
    assert NumDzDx(Qa(A,B,C,w) + K, Qc(A,B,C,w) + K, Qd(A,B,C,w) + K,
                   Qf(A,B,C,w) + K, Qg(A,B,C,w) + K, Qi(A,B,C,w) + K)
           == NumDzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                      Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w));
    assert NumDzDy(Qa(A,B,C,w) + K, Qb(A,B,C,w) + K, Qc(A,B,C,w) + K,
                   Qg(A,B,C,w) + K, Qh(A,B,C,w) + K, Qi(A,B,C,w) + K)
           == NumDzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                      Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w));
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes\n";
  print "全部由编译期验证: dafny verify P001_horn_slope_exact.dfy\n";
}
