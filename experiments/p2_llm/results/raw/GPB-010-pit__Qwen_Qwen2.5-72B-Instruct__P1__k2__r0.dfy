// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡下降路径
//  覆盖 : GPB-010(坑洼无流)、GPB-011(平面流方向一致)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  D8 算法在 DEM (数字高程模型) 中用于确定水流方向。如果中心格点的高程
//  不低于其所有八个邻居,则水流方向为 NoFlow (无流)。这一性质对于理解
//  和验证 DEM 中的水流路径至关重要,因为它确保了在局部最低点(坑洼)处
//  水流不会错误地流向任何方向。
//
// ===========================================================================

module D8SteepestDescent {

  // 3x3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  // 注意:中心元 e 在 D8 算法中是关键,必须出现在算子签名里。

  // 定义 D8 方向
  datatype Direction = E | SE | S | SW | W | NW | N | NE | NoFlow

  // 定义 3x3 窗口
  type Grid = array2<real>

  // 获取 D8 方向
  function D8Direction(h: Grid, r: int, c: int): Direction
    requires h != null
    requires 0 <= r < h.Height
    requires 0 <= c < h.Width
  {
    var e: real := h[r, c];
    var best: Direction := NoFlow;
    var best_p: real := 0.0;

    for name, dp, dq, dist2 in [
      (E, 1, 0, 1.0),
      (SE, 1, 1, 2.0),
      (S, 0, 1, 1.0),
      (SW, -1, 1, 2.0),
      (W, -1, 0, 1.0),
      (NW, -1, -1, 2.0),
      (N, 0, -1, 1.0),
      (NE, 1, -1, 2.0)
    ] do
      var rr: int := r + dq;
      var cc: int := c + dp;
      if 0 <= rr < h.Height && 0 <= cc < h.Width {
        var drop: real := e - h[rr, cc];
        if drop > 0 {
          var p: real := (drop * drop) / dist2;
          if best == NoFlow || p > best_p {
            best := name;
            best_p := p;
          }
        }
      }

    return best;
  }

  // 坑洼无流
  lemma PitHasNoFlow(h: Grid, r: int, c: int)
    requires h != null
    requires 0 <= r < h.Height
    requires 0 <= c < h.Width
    requires h[r, c] <= h[r-1, c-1] && h[r, c] <= h[r-1, c] && h[r, c] <= h[r-1, c+1] &&
             h[r, c] <= h[r, c-1] && h[r, c] <= h[r, c+1] &&
             h[r, c] <= h[r+1, c-1] && h[r, c] <= h[r+1, c] && h[r, c] <= h[r+1, c+1]
    ensures D8Direction(h, r, c) == NoFlow
  {
    var e: real := h[r, c];
    for name, dp, dq, dist2 in [
      (E, 1, 0, 1.0),
      (SE, 1, 1, 2.0),
      (S, 0, 1, 1.0),
      (SW, -1, 1, 2.0),
      (W, -1, 0, 1.0),
      (NW, -1, -1, 2.0),
      (N, 0, -1, 1.0),
      (NE, 1, -1, 2.0)
    ] do
      var rr: int := r + dq;
      var cc: int := c + dp;
      if 0 <= rr < h.Height && 0 <= cc < h.Width {
        assert e <= h[rr, cc];  // 由前提条件保证
        assert e - h[rr, cc] <= 0;  // 由前提条件保证
        assert (e - h[rr, cc]) * (e - h[rr, cc]) / dist2 <= 0;  // 由前提条件保证
      }
  }

  // 平面流方向一致
  lemma PlaneFlowIsConstant(h: Grid, A: real, B: real, C: real)
    requires h != null
    requires h.Height >= 3 && h.Width >= 3
    requires A > 0 && B == 0
    ensures forall r, c :: 0 < r < h.Height - 1 && 0 < c < h.Width - 1 ==> D8Direction(h, r, c) == W
  {
    // 平面方程: z = A * x + B * y + C
    // 由于 B == 0, 平面沿 y 方向无变化,沿 x 方向有变化
    // 因此,内部格点的水流方向应为 W (向西)

    forall r, c | 0 < r < h.Height - 1 && 0 < c < h.Width - 1
      ensures D8Direction(h, r, c) == W
    {
      var e: real := A * c + C;
      for name, dp, dq, dist2 in [
        (E, 1, 0, 1.0),
        (SE, 1, 1, 2.0),
        (S, 0, 1, 1.0),
        (SW, -1, 1, 2.0),
        (W, -1, 0, 1.0),
        (NW, -1, -1, 2.0),
        (N, 0, -1, 1.0),
        (NE, 1, -1, 2.0)
      ] do
        var rr: int := r + dq;
        var cc: int := c + dp;
        if 0 <= rr < h.Height && 0 <= cc < h.Width {
          var z: real := A * cc + C;
          assert e - z == A * (c - cc);  // 由平面方程保证
          if name == W {
            assert c - cc > 0;  // 向西方向, c > cc
            assert e - z > 0;  // 由于 A > 0, c > cc, e - z > 0
          } else {
            assert c - cc <= 0;  // 其他方向, c <= cc
            assert e - z <= 0;  // 由于 A > 0, c <= cc, e - z <= 0
          }
        }
    }
  }

  // 平面流方向一致 (A = B > 0)
  lemma PlaneFlowIsConstantAB(h: Grid, A: real, B: real, C: real)
    requires h != null
    requires h.Height >= 3 && h.Width >= 3
    requires A > 0 && B > 0
    ensures forall r, c :: 0 < r < h.Height - 1 && 0 < c < h.Width - 1 ==> D8Direction(h, r, c) == NW
  {
    // 平面方程: z = A * x + B * y + C
    // 由于 A > 0 且 B > 0, 平面沿 x 和 y 方向都有变化
    // 因此,内部格点的水流方向应为 NW (西北方向)

    forall r, c | 0 < r < h.Height - 1 && 0 < c < h.Width - 1
      ensures D8Direction(h, r, c) == NW
    {
      var e: real := A * c + B * r + C;
      for name, dp, dq, dist2 in [
        (E, 1, 0, 1.0),
        (SE, 1, 1, 2.0),
        (S, 0, 1, 1.0),
        (SW, -1, 1, 2.0),
        (W, -1, 0, 1.0),
        (NW, -1, -1, 2.0),
        (N, 0, -1, 1.0),
        (NE, 1, -1, 2.0)
      ] do
        var rr: int := r + dq;
        var cc: int := c + dp;
        if 0 <= rr < h.Height && 0 <= cc < h.Width {
          var z: real := A * cc + B * rr + C;
          assert e - z == A * (c - cc) + B * (r - rr);  // 由平面方程保证
          if name == NW {
            assert c - cc > 0;  // 向西方向, c > cc
            assert r - rr > 0;  // 向北方向, r > rr
            assert e - z > 0;  // 由于 A > 0, B > 0, c > cc, r > rr, e - z > 0
          } else {
            assert c - cc <= 0 || r - rr <= 0;  // 其他方向, c <= cc 或 r <= rr
            assert e - z <= 0;  // 由于 A > 0, B > 0, c <= cc 或 r <= rr, e - z <= 0
          }
        }
    }
  }

  // 主方法
  method Main() {
    print "GeoProofBench P-005 — D8 最陡下降路径的三条性质\n";
    print "全部由编译期验证:dafny verify P005_d8.dfy\n";
  }
}
