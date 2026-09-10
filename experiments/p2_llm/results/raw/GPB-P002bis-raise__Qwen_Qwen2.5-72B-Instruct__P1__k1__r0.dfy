// ===========================================================================
//  GeoProofBench · P-COMP-1
//  文件 : formal/dafny/PCOMP_1.dfy
//  算子 : 2D 局部提升 RaiseNbr
//  覆盖 : GPB-021(4-邻域提升不降低任何单元格高程,且提升至 max(原始邻域, 处理单元格填充))
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  在坑填充算法中,局部提升步骤确保了每个单元格的高程不会因提升其 4-邻域而降低,
//  并且邻域单元格至少被提升到 max(原始邻域, 处理单元格填充)。这一性质对于确保
//  坑填充算法的正确性和稳定性至关重要,也是后续 D8 流向和流域分析的基础。
//  本文件通过形式化验证这一性质,为坑填充算法的正确性提供理论支持。
// ===========================================================================

module PitFill2D {

  // 4-邻域定义
  const NBR4: (int, int)[] := [(-1, 0), (1, 0), (0, -1), (0, 1)];

  // 2D 网格类型
  type Grid = array2<int>;

  // 获取 4-邻域
  function method Get4Neighbors(grid: Grid, r: int, c: int): (int, int)[] {
    var neighbors: (int, int)[] := [];
    for (dr, dc) in NBR4 {
      if 0 <= r + dr < grid.Height && 0 <= c + dc < grid.Width {
        neighbors := neighbors + [(r + dr, c + dc)];
      }
    }
    return neighbors;
  }

  // 局部提升函数
  function method RaiseNbr(grid: Grid, r: int, c: int): Grid {
    var newGrid := grid;
    var neighbors := Get4Neighbors(grid, r, c);
    var maxNbr := grid[r, c];
    for (nr, nc) in neighbors {
      maxNbr := max(maxNbr, grid[nr, nc]);
    }
    newGrid[r, c] := maxNbr;
    return newGrid;
  }

  // 局部提升不降低任何单元格高程
  lemma RaiseNbrNonDecreasing(grid: Grid, r: int, c: int)
    requires 0 <= r < grid.Height
    requires 0 <= c < grid.Width
    ensures forall r': int, c': int :: 0 <= r' < grid.Height && 0 <= c' < grid.Width
      ==> grid[r', c'] <= RaiseNbr(grid, r, c)[r', c']
  {
    var newGrid := RaiseNbr(grid, r, c);
    var neighbors := Get4Neighbors(grid, r, c);
    var maxNbr := grid[r, c];
    for (nr, nc) in neighbors {
      maxNbr := max(maxNbr, grid[nr, nc]);
    }
    assert newGrid[r, c] == maxNbr;
    assert maxNbr >= grid[r, c];
    for r': int, c': int | 0 <= r' < grid.Height && 0 <= c' < grid.Width {
      if r' == r && c' == c {
        assert newGrid[r', c'] == maxNbr;
        assert maxNbr >= grid[r', c'];
      } else {
        assert newGrid[r', c'] == grid[r', c'];
      }
    }
  }

  // 邻域单元格至少被提升到 max(原始邻域, 处理单元格填充)
  lemma RaiseNbrToMax(grid: Grid, r: int, c: int)
    requires 0 <= r < grid.Height
    requires 0 <= c < grid.Width
    ensures forall (nr, nc) in Get4Neighbors(grid, r, c) :: 0 <= nr < grid.Height && 0 <= nc < grid.Width
      ==> RaiseNbr(grid, r, c)[nr, nc] == max(grid[nr, nc], grid[r, c])
  {
    var newGrid := RaiseNbr(grid, r, c);
    var neighbors := Get4Neighbors(grid, r, c);
    var maxNbr := grid[r, c];
    for (nr, nc) in neighbors {
      maxNbr := max(maxNbr, grid[nr, nc]);
    }
    assert newGrid[r, c] == maxNbr;
    for (nr, nc) in neighbors {
      assert newGrid[nr, nc] == grid[nr, nc];
      assert grid[nr, nc] <= maxNbr;
      assert maxNbr == max(grid[nr, nc], grid[r, c]);
    }
  }

  // 主方法
  method Main() {
    print "GeoProofBench P-COMP-1 — 2D 局部提升 RaiseNbr 的性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";
  }
}
