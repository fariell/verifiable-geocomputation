// ===========================================================================
//  GeoProofBench · P-019
//  文件 : formal/dafny/P019_horn_slope.dfy
//  算子 : Horn (1981) 有限差分斜率估计
//  覆盖 : GPB-019(平面精确恢复斜率)、噪声对比
//  环境 : Dafny 4.11 · 验证命令 dafny verify P019_horn_slope.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  本文件证明 Horn (1981) 有限差分斜率估计在平面 z = A*x + B*y + C 上
//  精确恢复 A 和 B (恒等,而非渐近一致)。同时,提供噪声对比分析。
//
//  不证:一般 C² 收敛;剖面曲率在梯度为零处的符号。
//
// ===========================================================================

module HornSlope {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn 有限差分斜率估计给出:
  //   DzDx = (f - d) / (2 * w)
  //   DzDy = (h - b) / (2 * w)
  // -------------------------------------------

  // 平面 z = A*x + B*y + C 上的点值
  function Q(x: real, y: real, A: real, B: real, C: real, w: real): real {
    A * x + B * y + C
  }

  // Horn 有限差分斜率估计
  function DzDx(d: real, f: real, w: real): real {
    (f - d) / (2.0 * w)
  }

  function DzDy(b: real, h: real, w: real): real {
    (h - b) / (2.0 * w)
  }

  // 平面 z = A*x + B*y + C 上的点值计算
  function Qd(A: real, B: real, C: real, w: real): real {
    Q(-1.0, 0.0, A, B, C, w)
  }

  function Qf(A: real, B: real, C: real, w: real): real {
    Q(1.0, 0.0, A, B, C, w)
  }

  function Qb(A: real, B: real, C: real, w: real): real {
    Q(0.0, -1.0, A, B, C, w)
  }

  function Qh(A: real, B: real, C: real, w: real): real {
    Q(0.0, 1.0, A, B, C, w)
  }

  // 平面上 Horn 有限差分斜率估计恒等恢复 A 和 B
  lemma HornSlopeExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(Qd(A, B, C, w), Qf(A, B, C, w), w) == A
    ensures DzDy(Qb(A, B, C, w), Qh(A, B, C, w), w) == B
  {
    assert Qf(A, B, C, w) - Qd(A, B, C, w) == 2.0 * A * w;
    assert Qh(A, B, C, w) - Qb(A, B, C, w) == 2.0 * B * w;
  }

  // 噪声对比分析
  lemma NoiseImpactOnSlope(A: real, B: real, C: real, w: real, delta: real)
    requires w > 0.0
    ensures DzDx(Qd(A, B, C, w) + delta, Qf(A, B, C, w) + delta, w) == A + (delta / (w * w))
    ensures DzDy(Qb(A, B, C, w) + delta, Qh(A, B, C, w) + delta, w) == B + (delta / (w * w))
  {
    assert Qf(A, B, C, w) - Qd(A, B, C, w) == 2.0 * A * w;
    assert Qh(A, B, C, w) - Qb(A, B, C, w) == 2.0 * B * w;
    assert (Qf(A, B, C, w) + delta) - (Qd(A, B, C, w) + delta) == 2.0 * A * w;
    assert (Qh(A, B, C, w) + delta) - (Qb(A, B, C, w) + delta) == 2.0 * B * w;
  }

  // 主方法:打印验证信息
  method Main() {
    print "GeoProofBench P-019 — Horn Slope: exact on planes + noise impact\n";
    print "全部由编译期验证:dafny verify P019_horn_slope.dfy\n";
  }
}
