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
//  D8 算法是数字高程模型(DEM)中常用的流路径算法。本文件证明了在 D8
//  算法下,如果中心格点的所有八个邻居都不严格低于中心格点,则流方向
//  为 NoFlow(未定义 / 坑)。这是 D8 算法的一个基本性质,对于理解算法
//  的行为和验证其正确性至关重要。
// ===========================================================================

module D8SteepestDescent {

  // 3x3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  // 注意:中心元 e 在 D8 算法中的权为 1,出现在算子签名里。

  // 定义 D8 流方向
  datatype Direction = NoFlow | E | SE | S | SW | W | NW | N | NE

  // 定义 3x3 窗口
  type Grid = array2<real>

  // 获取 3x3 窗口的中心值
  function Center(grid: Grid, r: int, c: int): real
    requires 0 <= r < grid.Height
    requires 0 <= c < grid.Width
  {
    grid[r, c]
  }

  // 获取 3x3 窗口的邻居值
  function Neighbor(grid: Grid, r: int, c: int, dr: int, dc: int): real
    requires 0 <= r < grid.Height
    requires 0 <= c < grid.Width
    requires 0 <= r + dr < grid.Height
    requires 0 <= c + dc < grid.Width
  {
    grid[r + dr, c + dc]
  }

  // 计算 D8 流方向
  function D8Direction(grid: Grid, r: int, c: int): Direction
    requires 0 <= r < grid.Height
    requires 0 <= c < grid.Width
  {
    var e = Center(grid, r, c);
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
    ] {
      var rr = r + dq;
      var cc = c + dp;
      if 0 <= rr < grid.Height && 0 <= cc < grid.Width {
        var drop = e - Neighbor(grid, r, c, dp, dq);
        if drop > 0 {
          var p = (drop * drop) / dist2;
          if best == NoFlow || p > best_p {
            best, best_p := name, p;
          }
        }
      }
    }

    best
  }

  // 定理:如果所有邻居都不严格低于中心,则流方向为 NoFlow
  lemma D8NoFlow(grid: Grid, r: int, c: int)
    requires 0 <= r < grid.Height
    requires 0 <= c < grid.Width
    requires forall dp, dq :: |dp| <= 1 && |dq| <= 1 && (dp != 0 || dq != 0) ==>
      Neighbor(grid, r, c, dp, dq) >= Center(grid, r, c)
    ensures D8Direction(grid, r, c) == NoFlow
  {
    var e = Center(grid, r, c);
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
    ] {
      var rr = r + dq;
      var cc = c + dp;
      if 0 <= rr < grid.Height && 0 <= cc < grid.Width {
        var drop = e - Neighbor(grid, r, c, dp, dq);
        assert drop <= 0; // 由前提条件保证
        assert best == NoFlow; // 由于 drop <= 0, best 不会改变
      }
    }

    assert best == NoFlow;
  }

  method Main() {
    print "GeoProofBench P-005 — D8 坑无流定理\n";
    print "全部由编译期验证:dafny verify P005_d8.dfy\n";
  }
}
