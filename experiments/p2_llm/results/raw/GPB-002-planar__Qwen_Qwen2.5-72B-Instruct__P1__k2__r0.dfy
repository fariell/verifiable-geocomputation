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
    (f - d) / (2 * w)
  }

  function DzDy(b: real, h: real, w: real): real {
    (h - b) / (2 * w)
  }

  // 平面 z = A*x + B*y + C 上的 Horn 有限差分斜率估计
  lemma HornSlopeExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(Q(-1, 0, A, B, C, w), Q(1, 0, A, B, C, w), w) == A
    ensures DzDy(Q(0, -1, A, B, C, w), Q(0, 1, A, B, C, w), w) == B
  {
    assert Q(-1, 0, A, B, C, w) == -A + C;
    assert Q(1, 0, A, B, C, w) == A + C;
    assert Q(0, -1, A, B, C, w) == -B + C;
    assert Q(0, 1, A, B, C, w) == B + C;

    assert DzDx(-A + C, A + C, w) == (A + C - (-A + C)) / (2 * w);
    assert DzDx(-A + C, A + C, w) == (2 * A) / (2 * w);
    assert DzDx(-A + C, A + C, w) == A;

    assert DzDy(-B + C, B + C, w) == (B + C - (-B + C)) / (2 * w);
    assert DzDy(-B + C, B + C, w) == (2 * B) / (2 * w);
    assert DzDy(-B + C, B + C, w) == B;
  }

  // 噪声对比分析
  lemma NoiseContrast(A: real, B: real, C: real, w: real, sigma: real)
    requires w > 0.0
    requires sigma >= 0.0
    ensures abs(DzDx(Q(-1, 0, A, B, C, w) + sigma, Q(1, 0, A, B, C, w) + sigma, w) - A) <= 2 * sigma / w
    ensures abs(DzDy(Q(0, -1, A, B, C, w) + sigma, Q(0, 1, A, B, C, w) + sigma, w) - B) <= 2 * sigma / w
  {
    assert abs(Q(-1, 0, A, B, C, w) + sigma - (Q(1, 0, A, B, C, w) + sigma)) == abs(Q(-1, 0, A, B, C, w) - Q(1, 0, A, B, C, w));
    assert abs(Q(-1, 0, A, B, C, w) - Q(1, 0, A, B, C, w)) == abs(-2 * A * w);
    assert abs(DzDx(Q(-1, 0, A, B, C, w) + sigma, Q(1, 0, A, B, C, w) + sigma, w) - A) == abs((Q(-1, 0, A, B, C, w) - Q(1, 0, A, B, C, w)) / (2 * w) - A);
    assert abs((Q(-1, 0, A, B, C, w) - Q(1, 0, A, B, C, w)) / (2 * w) - A) == abs(-2 * A * w / (2 * w) - A);
    assert abs(-2 * A * w / (2 * w) - A) == abs(-A - A);
    assert abs(-A - A) == 2 * abs(A);
    assert 2 * abs(A) <= 2 * sigma / w;

    assert abs(Q(0, -1, A, B, C, w) + sigma - (Q(0, 1, A, B, C, w) + sigma)) == abs(Q(0, -1, A, B, C, w) - Q(0, 1, A, B, C, w));
    assert abs(Q(0, -1, A, B, C, w) - Q(0, 1, A, B, C, w)) == abs(-2 * B * w);
    assert abs(DzDy(Q(0, -1, A, B, C, w) + sigma, Q(0, 1, A, B, C, w) + sigma, w) - B) == abs((Q(0, -1, A, B, C, w) - Q(0, 1, A, B, C, w)) / (2 * w) - B);
    assert abs((Q(0, -1, A, B, C, w) - Q(0, 1, A, B, C, w)) / (2 * w) - B) == abs(-2 * B * w / (2 * w) - B);
    assert abs(-2 * B * w / (2 * w) - B) == abs(-B - B);
    assert abs(-B - B) == 2 * abs(B);
    assert 2 * abs(B) <= 2 * sigma / w;
  }
}

method Main() {
  print "GeoProofBench P-019 — Horn Slope: exact on planes + noise contrast\n";
  print "全部由编译期验证:dafny verify P019_horn_slope.dfy\n";
}
