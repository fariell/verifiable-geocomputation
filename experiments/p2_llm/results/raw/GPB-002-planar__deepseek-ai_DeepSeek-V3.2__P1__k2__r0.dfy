// ===========================================================================
//  GeoProofBench · P-001
//  文件 : formal/dafny/P001_horn_slope_exact.dfy
//  算子 : Horn (1981) 有限差分坡度
//  覆盖 : GPB-019 的代数核（平面上的精确恢复）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P001_horn_slope_exact.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  命题：在平面 z = A*x + B*y + C 上，Horn 有限差分算子精确恢复 A 和 B
//  ----------------------------------------------------------------
//  给定规则网格（间距 w > 0），Horn 坡度算子：
//    DzDx = (f - d) / (2w)
//    DzDy = (h - b) / (2w)
//  在任意平面采样值上，恒有 DzDx = A 且 DzDy = B。
//
//  这是 GPB-019 的代数部分（恒等），区别于渐近一致性。
//  注意：本证明不依赖 w → 0 的极限，而是对任意 w > 0 成立。
//
// ===========================================================================

module HornSlopeExact {

  // ------------------------------------------------------------------
  // 3x3 窗口约定（与 P-003 相同：p 向右，q 向下）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  //  Horn (1981) 坡度差分：
  //    ∂z/∂x ≈ (f - d) / (2w)
  //    ∂z/∂y ≈ (h - b) / (2w)
  // ------------------------------------------------------------------

  // 平面函数：z = A*x + B*y + C
  function Plane(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // 网格坐标到实际距离（以中心 e 为原点 (0,0)）
  function GridX(p: int): real { p as real }
  function GridY(q: int): real { q as real }

  // 采样平面上的点
  function Sample(p: int, q: int, A: real, B: real, C: real, w: real): real
    requires w > 0.0
  {
    Plane(GridX(p) * w, GridY(q) * w, A, B, C)
  }

  // 窗口九个点的简写
  function Qa(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample(-1, -1, A, B, C, w) }
  function Qb(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample( 0, -1, A, B, C, w) }
  function Qc(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample( 1, -1, A, B, C, w) }
  function Qd(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample(-1,  0, A, B, C, w) }
  function Qe(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample( 0,  0, A, B, C, w) }
  function Qf(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample( 1,  0, A, B, C, w) }
  function Qg(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample(-1,  1, A, B, C, w) }
  function Qh(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample( 0,  1, A, B, C, w) }
  function Qi(A: real, B: real, C: real, w: real): real
    requires w > 0.0
  { Sample( 1,  1, A, B, C, w) }

  // Horn 有限差分算子
  function HornDzDx(d: real, f: real, w: real): real
    requires w > 0.0
  {
    (f - d) / (2.0 * w)
  }

  function HornDzDy(b: real, h: real, w: real): real
    requires w > 0.0
  {
    (h - b) / (2.0 * w)
  }

  // ==================================================================
  // 主引理：在平面上 Horn 算子精确恢复 A 和 B
  // ==================================================================
  lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDzDx(Qd(A, B, C, w), Qf(A, B, C, w), w) == A
    ensures HornDzDy(Qb(A, B, C, w), Qh(A, B, C, w), w) == B
  {
    // 展开 Qd 和 Qf
    calc {
      Qf(A, B, C, w) - Qd(A, B, C, w);
      ==
      Plane(1.0 * w, 0.0, A, B, C) - Plane(-1.0 * w, 0.0, A, B, C);
      ==
      (A * (1.0 * w) + B * 0.0 + C) - (A * (-1.0 * w) + B * 0.0 + C);
      ==
      A * w + C - (-A * w + C);
      ==
      A * w + A * w;
      ==
      2.0 * A * w;
    }
    // 因此 DzDx = (2.0 * A * w) / (2.0 * w) = A
    assert HornDzDx(Qd(A, B, C, w), Qf(A, B, C, w), w) == A;

    // 展开 Qb 和 Qh
    calc {
      Qh(A, B, C, w) - Qb(A, B, C, w);
      ==
      Plane(0.0, 1.0 * w, A, B, C) - Plane(0.0, -1.0 * w, A, B, C);
      ==
      (A * 0.0 + B * (1.0 * w) + C) - (A * 0.0 + B * (-1.0 * w) + C);
      ==
      B * w - (-B * w);
      ==
      2.0 * B * w;
    }
    // 因此 DzDy = (2.0 * B * w) / (2.0 * w) = B
    assert HornDzDy(Qb(A, B, C, w), Qh(A, B, C, w), w) == B;
  }

  // ==================================================================
  // 辅助引理：平移不变性（平面常数项 C 不影响差分）
  // ==================================================================
  lemma HornInvariantUnderVerticalShift(A: real, B: real, C1: real, C2: real, w: real)
    requires w > 0.0
    ensures HornDzDx(Qd(A, B, C1, w), Qf(A, B, C1, w), w)
         == HornDzDx(Qd(A, B, C2, w), Qf(A, B, C2, w), w)
    ensures HornDzDy(Qb(A, B, C1, w), Qh(A, B, C1, w), w)
         == HornDzDy(Qb(A, B, C2, w), Qh(A, B, C2, w), w)
  {
    // 差分时常数项 C 相减抵消
    assert Qf(A, B, C1, w) - Qd(A, B, C1, w) == Qf(A, B, C2, w) - Qd(A, B, C2, w);
    assert Qh(A, B, C1, w) - Qb(A, B, C1, w) == Qh(A, B, C2, w) - Qb(A, B, C2, w);
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes (algebraic core of GPB-019)\n";
  print "全部由编译期验证: dafny verify P001_horn_slope_exact.dfy\n";
}
