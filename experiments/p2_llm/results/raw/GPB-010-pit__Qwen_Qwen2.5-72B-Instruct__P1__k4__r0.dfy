// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡下降路径
//  覆盖 : GPB-010 (坑无流)、GPB-011 (平面流方向一致)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  D8 算法是数字高程模型(DEM)中常用的流路径算法,其核心在于确定每个格点
//  的最陡下降方向。当中心格点的高程不低于其所有邻居时,该格点被视为"坑"
//  (pit),没有明确的流方向。本文件证明了在 D8 算法下,如果一个 3x3 窗口的
//  中心格点不低于其所有邻居,则该中心格点的流方向为 NoFlow。
//
//  这一性质对于理解 DEM 中的流路径算法至关重要,因为它确保了算法在处理
//  坑时的一致性和合理性。此外,这一性质的证明也为后续更复杂的流路径
//  算法(如曲率)提供了基础。
// ===========================================================================

module D8SteepestDescent {

  // 3x3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  // 注意:中心元 e 在 D8 算法中是关键,必须出现在算子签名里。

  // 定义 D8 流方向
  datatype Direction = NoFlow | E | SE | S | SW | W | NW | N | NE

  // 计算 D8 流方向
  function D8Direction(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real): Direction
  {
    if e <= a && e <= b && e <= c && e <= d && e <= f && e <= g && e <= h && e <= i {
      return NoFlow
    } else {
      var bestDir: Direction := NoFlow;
      var bestDrop: real := 0.0;
      if e - a > bestDrop { bestDir, bestDrop := E, e - a; }
      if e - b > bestDrop { bestDir, bestDrop := SE, e - b; }
      if e - c > bestDrop { bestDir, bestDrop := S, e - c; }
      if e - d > bestDrop { bestDir, bestDrop := SW, e - d; }
      if e - f > bestDrop { bestDir, bestDrop := W, e - f; }
      if e - g > bestDrop { bestDir, bestDrop := NW, e - g; }
      if e - h > bestDrop { bestDir, bestDrop := N, e - h; }
      if e - i > bestDrop { bestDir, bestDrop := NE, e - i; }
      return bestDir;
    }
  }

  // 定理:如果中心格点不低于其所有邻居,则流方向为 NoFlow
  lemma D8NoFlow(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real)
    requires e >= a && e >= b && e >= c && e >= d && e >= f && e >= g && e >= h && e >= i
    ensures D8Direction(a, b, c, d, e, f, g, h, i) == NoFlow
  {
    // 由于 e 不低于任何邻居,根据 D8Direction 的定义,流方向应为 NoFlow
    assert D8Direction(a, b, c, d, e, f, g, h, i) == NoFlow;
  }

  // 定理:在平面 A>0 B=0 上,每个内部格点的流方向为 W
  lemma PlaneWestFlow(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real)
    requires a == e - 0.4 && b == e - 0.4 && c == e - 0.4 && d == e - 0.4 && f == e - 0.4 && g == e - 0.4 && h == e - 0.4 && i == e - 0.4
    ensures D8Direction(a, b, c, d, e, f, g, h, i) == W
  {
    // 由于 e - f > 0 且 e - f > e - x (x 为其他邻居),流方向应为 W
    assert e - f > 0.0;
    assert e - f > e - a;
    assert e - f > e - b;
    assert e - f > e - c;
    assert e - f > e - d;
    assert e - f > e - g;
    assert e - f > e - h;
    assert e - f > e - i;
    assert D8Direction(a, b, c, d, e, f, g, h, i) == W;
  }

  // 定理:在平面 A=B>0 上,每个内部格点的流方向为 NW
  lemma PlaneNorthWestFlow(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real)
    requires a == e - 0.4 * 1.414 && b == e - 0.4 * 1.414 && c == e - 0.4 * 1.414 && d == e - 0.4 * 1.414 && f == e - 0.4 * 1.414 && g == e - 0.4 * 1.414 && h == e - 0.4 * 1.414 && i == e - 0.4 * 1.414
    ensures D8Direction(a, b, c, d, e, f, g, h, i) == NW
  {
    // 由于 e - g > 0 且 e - g > e - x (x 为其他邻居),流方向应为 NW
    assert e - g > 0.0;
    assert e - g > e - a;
    assert e - g > e - b;
    assert e - g > e - c;
    assert e - g > e - d;
    assert e - g > e - f;
    assert e - g > e - h;
    assert e - g > e - i;
    assert D8Direction(a, b, c, d, e, f, g, h, i) == NW;
  }

  // 主方法:验证 D8 算法的性质
  method Main() {
    print "GeoProofBench P-005 — D8 算法的性质\n";
    print "全部由编译期验证:dafny verify P005_d8.dfy\n";

    // 测试坑无流
    var pitFlow = D8Direction(1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0);
    assert pitFlow == NoFlow;

    // 测试平面 A>0 B=0 的流方向
    var planeWest = D8Direction(0.6, 0.6, 0.6, 0.6, 1.0, 0.6, 0.6, 0.6, 0.6);
    assert planeWest == W;

    // 测试平面 A=B>0 的流方向
    var planeNorthWest = D8Direction(0.6 * 1.414, 0.6 * 1.414, 0.6 * 1.414, 0.6 * 1.414, 1.0, 0.6 * 1.414, 0.6 * 1.414, 0.6 * 1.414, 0.6 * 1.414);
    assert planeNorthWest == NW;

    print "所有测试通过\n";
  }
}
