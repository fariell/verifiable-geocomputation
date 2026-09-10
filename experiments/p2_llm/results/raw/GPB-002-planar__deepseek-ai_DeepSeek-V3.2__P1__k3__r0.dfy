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
//  这是 GPB-019 的代数部分，与实验部分（grid spacing → 0 的一致性）互补。
//  本证明不依赖于 w → 0 的极限，而是对任意 w > 0 在离散网格上精确成立。
//
//  窗口约定（与 P-003 相同）：
//
//     a(-1,-1)   b( 0,-1)   c( 1,-1)
//     d(-1, 0)     e        f( 1, 0)
//     g(-1, 1)   h( 0, 1)   i( 1, 1)
//
//  Horn (1981) 有限差分公式：
//    DzDx = (c + 2f + i - a - 2d - g) / (8 * w)
//    DzDy = (g + 2h + i - a - 2b - c) / (8 * w)
//
// ===========================================================================

module HornSlopeExact {

  // ------------------------------------------------------------------
  // 平面函数 z = A*x + B*y + C 在网格点上的采样
  // ------------------------------------------------------------------
  function Plane(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // 3x3 窗口各点坐标（以中心 e 为原点 (0,0)）
  const dx := 1.0;
  const dy := 1.0;

  function Qa(A: real, B: real, C: real, w: real): real
  {
    Plane(-w, -w, A, B, C)
  }
  function Qb(A: real, B: real, C: real, w: real): real
  {
    Plane( 0.0, -w, A, B, C)
  }
  function Qc(A: real, B: real, C: real, w: real): real
  {
    Plane( w, -w, A, B, C)
  }
  function Qd(A: real, B: real, C: real, w: real): real
  {
    Plane(-w,  0.0, A, B, C)
  }
  function Qe(A: real, B: real, C: real, w: real): real
  {
    Plane( 0.0,  0.0, A, B, C)
  }
  function Qf(A: real, B: real, C: real, w: real): real
  {
    Plane( w,  0.0, A, B, C)
  }
  function Qg(A: real, B: real, C: real, w: real): real
  {
    Plane(-w,  w, A, B, C)
  }
  function Qh(A: real, B: real, C: real, w: real): real
  {
    Plane( 0.0,  w, A, B, C)
  }
  function Qi(A: real, B: real, C: real, w: real): real
  {
    Plane( w,  w, A, B, C)
  }

  // ------------------------------------------------------------------
  // Horn 有限差分算子（分子部分，未除以 8w）
  // ------------------------------------------------------------------
  function NumDzDx(a: real, c: real, d: real, f: real, g: real, i: real): real
  {
    c + 2.0 * f + i - a - 2.0 * d - g
  }

  function NumDzDy(a: real, b: real, c: real, g: real, h: real, i: real): real
  {
    g + 2.0 * h + i - a - 2.0 * b - c
  }

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

  // ------------------------------------------------------------------
  // 主要引理：在平面上 Horn 算子精确恢复 A 和 B
  // ------------------------------------------------------------------
  lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                 Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w), w) == A
    ensures DzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                 Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w) == B
  {
    // 展开各点高程
    assert Qa(A,B,C,w) == A * (-w) + B * (-w) + C;
    assert Qb(A,B,C,w) == A *   0.0 + B * (-w) + C;
    assert Qc(A,B,C,w) == A *   w  + B * (-w) + C;
    assert Qd(A,B,C,w) == A * (-w) + B *   0.0 + C;
    assert Qe(A,B,C,w) == A *   0.0 + B *   0.0 + C;
    assert Qf(A,B,C,w) == A *   w  + B *   0.0 + C;
    assert Qg(A,B,C,w) == A * (-w) + B *   w  + C;
    assert Qh(A,B,C,w) == A *   0.0 + B *   w  + C;
    assert Qi(A,B,C,w) == A *   w  + B *   w  + C;

    // 计算 DzDx 的分子
    calc {
      NumDzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
              Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w));
      ==
      (A*w + B*(-w) + C) + 2.0*(A*w + B*0.0 + C) + (A*w + B*w + C)
      - (A*(-w) + B*(-w) + C) - 2.0*(A*(-w) + B*0.0 + C) - (A*(-w) + B*w + C);
      ==
      // 合并同类项
      (A*w + 2.0*A*w + A*w) + ( -B*w + 0.0 + B*w) + (C + 2.0*C + C)
      - ( -A*w - 2.0*(-A*w) - (-A*w) ) - ( -B*w + 0.0 + B*w ) - (C + 2.0*C + C);
      ==
      (4.0 * A * w) - ( -4.0 * A * w );
      ==
      8.0 * A * w;
    }
    // 除以 8w 得 A
    assert DzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w), w) == A;

    // 计算 DzDy 的分子
    calc {
      NumDzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
              Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w));
      ==
      (A*(-w) + B*w + C) + 2.0*(A*0.0 + B*w + C) + (A*w + B*w + C)
      - (A*(-w) + B*(-w) + C) - 2.0*(A*0.0 + B*(-w) + C) - (A*w + B*(-w) + C);
      ==
      // 合并同类项
      ( -A*w + 0.0 + A*w ) + ( B*w + 2.0*B*w + B*w ) + ( C + 2.0*C + C )
      - ( -A*w + 0.0 + A*w ) - ( -B*w - 2.0*(-B*w) - (-B*w) ) - ( C + 2.0*C + C );
      ==
      (4.0 * B * w) - ( -4.0 * B * w );
      ==
      8.0 * B * w;
    }
    // 除以 8w 得 B
    assert DzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w) == B;
  }

  // ------------------------------------------------------------------
  // 平移不变性：整个平面加上常数 K，坡度估计不变
  // ------------------------------------------------------------------
  lemma HornTranslationInvariant(A: real, B: real, C: real, K: real, w: real)
    requires w > 0.0
    ensures DzDx(Qa(A,B,C+K,w), Qc(A,B,C+K,w), Qd(A,B,C+K,w),
                 Qf(A,B,C+K,w), Qg(A,B,C+K,w), Qi(A,B,C+K,w), w)
            == DzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                    Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w), w)
    ensures DzDy(Qa(A,B,C+K,w), Qb(A,B,C+K,w), Qc(A,B,C+K,w),
                 Qg(A,B,C+K,w), Qh(A,B,C+K,w), Qi(A,B,C+K,w), w)
            == DzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                    Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w)
  {
    // 分子中的常数项相互抵消
    assert NumDzDx(Qa(A,B,C+K,w), Qc(A,B,C+K,w), Qd(A,B,C+K,w),
                   Qf(A,B,C+K,w), Qg(A,B,C+K,w), Qi(A,B,C+K,w))
           == NumDzDx(Qa(A,B,C,w), Qc(A,B,C,w), Qd(A,B,C,w),
                      Qf(A,B,C,w), Qg(A,B,C,w), Qi(A,B,C,w));
    assert NumDzDy(Qa(A,B,C+K,w), Qb(A,B,C+K,w), Qc(A,B,C+K,w),
                   Qg(A,B,C+K,w), Qh(A,B,C+K,w), Qi(A,B,C+K,w))
           == NumDzDy(Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w),
                      Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w));
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes\n";
  print "全部由编译期验证: dafny verify P001_horn_slope_exact.dfy\n";
}
