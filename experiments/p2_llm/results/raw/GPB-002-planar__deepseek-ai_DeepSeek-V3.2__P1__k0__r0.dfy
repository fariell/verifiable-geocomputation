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
//        精确恢复系数 A 和 B（恒等，不仅仅是渐近一致）。
//
//  3x3 窗口约定（与 P-003 相同：p 向右，q 向下）
//
//     a(-1,-1)   b( 0,-1)   c( 1,-1)
//     d(-1, 0)     e        f( 1, 0)
//     g(-1, 1)   h( 0, 1)   i( 1, 1)
//
//  Horn (1981) 有限差分公式：
//    DzDx = (c + 2f + i - a - 2d - g) / (8 * w)
//    DzDy = (g + 2h + i - a - 2b - c) / (8 * w)
//
//  本文件证明：当高程来自平面 z = A*x + B*y + C 时，
//    DzDx = A, DzDy = B 精确成立（与网格间距 w>0 无关）。
//
// ===========================================================================

module HornSlopeExact {

  // ------------------------------------------------------------------
  // 平面高程函数
  // ------------------------------------------------------------------
  function plane(x: real, y: real, A: real, B: real, C: real): real
  {
    A * x + B * y + C
  }

  // ------------------------------------------------------------------
  // Horn 有限差分算子（分子部分，不含分母 8*w）
  // ------------------------------------------------------------------
  function NumDzDx(a: real, c: real, d: real, f: real, g: real, i: real): real
  {
    c + 2.0 * f + i - a - 2.0 * d - g
  }

  function NumDzDy(a: real, b: real, c: real, g: real, h: real, i: real): real
  {
    g + 2.0 * h + i - a - 2.0 * b - c
  }

  // ------------------------------------------------------------------
  // 完整的 Horn 坡度估计（含分母）
  // ------------------------------------------------------------------
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
  // 辅助引理：平面上的窗口高程
  // ------------------------------------------------------------------
  lemma PlaneWindow(A: real, B: real, C: real, w: real)
    returns (
      a: real, b: real, c: real,
      d: real, e: real, f: real,
      g: real, h: real, i: real
    )
    ensures a == plane(-w, -w, A, B, C)
    ensures b == plane( 0.0, -w, A, B, C)
    ensures c == plane( w, -w, A, B, C)
    ensures d == plane(-w,  0.0, A, B, C)
    ensures e == plane( 0.0,  0.0, A, B, C)
    ensures f == plane( w,  0.0, A, B, C)
    ensures g == plane(-w,  w, A, B, C)
    ensures h == plane( 0.0,  w, A, B, C)
    ensures i == plane( w,  w, A, B, C)
  {
    a := plane(-w, -w, A, B, C);
    b := plane( 0.0, -w, A, B, C);
    c := plane( w, -w, A, B, C);
    d := plane(-w,  0.0, A, B, C);
    e := plane( 0.0,  0.0, A, B, C);
    f := plane( w,  0.0, A, B, C);
    g := plane(-w,  w, A, B, C);
    h := plane( 0.0,  w, A, B, C);
    i := plane( w,  w, A, B, C);
  }

  // ------------------------------------------------------------------
  // 主定理：Horn 算子在平面上精确恢复 A 和 B
  // ------------------------------------------------------------------
  theorem HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures
      exists a, b, c, d, e, f, g, h, i ::
        a == plane(-w, -w, A, B, C) &&
        b == plane( 0.0, -w, A, B, C) &&
        c == plane( w, -w, A, B, C) &&
        d == plane(-w,  0.0, A, B, C) &&
        e == plane( 0.0,  0.0, A, B, C) &&
        f == plane( w,  0.0, A, B, C) &&
        g == plane(-w,  w, A, B, C) &&
        h == plane( 0.0,  w, A, B, C) &&
        i == plane( w,  w, A, B, C) &&
        DzDx(a, c, d, f, g, i, w) == A &&
        DzDy(a, b, c, g, h, i, w) == B
  {
    var a', b', c', d', e', f', g', h', i' :|
      a' == plane(-w, -w, A, B, C) &&
      b' == plane( 0.0, -w, A, B, C) &&
      c' == plane( w, -w, A, B, C) &&
      d' == plane(-w,  0.0, A, B, C) &&
      e' == plane( 0.0,  0.0, A, B, C) &&
      f' == plane( w,  0.0, A, B, C) &&
      g' == plane(-w,  w, A, B, C) &&
      h' == plane( 0.0,  w, A, B, C) &&
      i' == plane( w,  w, A, B, C);
    // 展开平面高程表达式
    calc {
      NumDzDx(a', c', d', f', g', i');
      ==
      (A * w + B * (-w) + C) + 2.0 * (A * w + B * 0.0 + C) + (A * w + B * w + C)
      - (A * (-w) + B * (-w) + C) - 2.0 * (A * (-w) + B * 0.0 + C) - (A * (-w) + B * w + C);
      ==
      // 合并同类项
      (A*w - B*w + C) + (2*A*w + 2*C) + (A*w + B*w + C)
      - (-A*w - B*w + C) - (-2*A*w + 2*C) - (-A*w + B*w + C);
      ==
      // 进一步简化
      (A*w - B*w + C + 2*A*w + 2*C + A*w + B*w + C)
      - (-A*w - B*w + C - 2*A*w + 2*C - A*w + B*w + C);
      ==
      // 计算括号内
      (4*A*w + 4*C) - (-4*A*w + 4*C);
      ==
      8*A*w;
    }
    assert NumDzDx(a', c', d', f', g', i') == 8.0 * A * w;
    assert DzDx(a', c', d', f', g', i', w) == (8.0 * A * w) / (8.0 * w) == A;

    calc {
      NumDzDy(a', b', c', g', h', i');
      ==
      (A * (-w) + B * w + C) + 2.0 * (A * 0.0 + B * w + C) + (A * w + B * w + C)
      - (A * (-w) + B * (-w) + C) - 2.0 * (A * 0.0 + B * (-w) + C) - (A * w + B * (-w) + C);
      ==
      // 合并同类项
      (-A*w + B*w + C) + (2*B*w + 2*C) + (A*w + B*w + C)
      - (-A*w - B*w + C) - (-2*B*w + 2*C) - (A*w - B*w + C);
      ==
      // 进一步简化
      (-A*w + B*w + C + 2*B*w + 2*C + A*w + B*w + C)
      - (-A*w - B*w + C - 2*B*w + 2*C + A*w - B*w + C);
      ==
      // 计算括号内
      (4*B*w + 4*C) - (-4*B*w + 4*C);
      ==
      8*B*w;
    }
    assert NumDzDy(a', b', c', g', h', i') == 8.0 * B * w;
    assert DzDy(a', b', c', g', h', i', w) == (8.0 * B * w) / (8.0 * w) == B;
  }

  // ------------------------------------------------------------------
  // 不变性引理：整体高程平移不影响坡度估计
  // ------------------------------------------------------------------
  lemma TranslationInvariant(a: real, b: real, c: real, d: real, f: real,
                             g: real, h: real, i: real, K: real, w: real)
    requires w > 0.0
    ensures DzDx(a + K, c + K, d + K, f + K, g + K, i + K, w) == DzDx(a, c, d, f, g, i, w)
    ensures DzDy(a + K, b + K, c + K, g + K, h + K, i + K, w) == DzDy(a, b, c, g, h, i, w)
  {
    assert NumDzDx(a + K, c + K, d + K, f + K, g + K, i + K) == NumDzDx(a, c, d, f, g, i);
    assert NumDzDy(a + K, b + K, c + K, g + K, h + K, i + K) == NumDzDy(a, b, c, g, h, i);
  }
}

method Main() {
  print "GeoProofBench P-001 — Horn slope exact on planes\n";
  print "全部由编译期验证: dafny verify P001_horn_slope_exact.dfy\n";
}
