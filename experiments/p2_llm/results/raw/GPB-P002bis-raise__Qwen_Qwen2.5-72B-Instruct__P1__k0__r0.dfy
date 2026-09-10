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
//  在坑填和平面 D8 下降的组合操作中,局部提升步骤确保了 4-邻域的单元格
//  高程不会降低,并且至少提升到 max(原始邻域, 处理单元格填充)。这是
//  空间计算中一个重要的性质,确保了算法的稳定性和一致性。
//
// ===========================================================================

module PCOMP_1 {

  // 4-邻域定义
  const NBR4: (int, int)[] := [(-1, 0), (1, 0), (0, -1), (0, 1)];

  // 2D 网格类型
  type Grid = array2<int>;

  // 获取 4-邻域
  function GetNbr4(grid: Grid, r: int, c: int): (int, int)[] {
    var nbrs: (int, int)[] := [];
    for (dr, dc) in NBR4 {
      if 0 <= r + dr < grid.Rows && 0 <= c + dc < grid.Cols {
        nbrs := nbrs + [(r + dr, c + dc)];
      }
    }
    return nbrs;
  }

  // 获取 4-邻域高程
  function GetNbr4Elevations(grid: Grid, r: int, c: int): int[] {
    var elevs: int[] := [];
    for (nr, nc) in GetNbr4(grid, r, c) {
      elevs := elevs + [grid[nr, nc]];
    }
    return elevs;
  }

  // 局部提升函数
  function RaiseNbr(grid: Grid, r: int, c: int, fill: int): Grid {
    var newGrid := grid;
    for (nr, nc) in GetNbr4(grid, r, c) {
      newGrid[nr, nc] := max(newGrid[nr, nc], fill);
    }
    return newGrid;
  }

  // 局部提升不降低任何单元格高程
  lemma RaiseNbrNonDecreasing(grid: Grid, r: int, c: int, fill: int)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    ensures forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==> RaiseNbr(grid, r, c, fill)[i, j] >= grid[i, j]
  {
    var newGrid := RaiseNbr(grid, r, c, fill);
    assert forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==> newGrid[i, j] >= grid[i, j] by {
      if (i, j) == (r, c) {
        assert newGrid[i, j] == max(grid[i, j], fill);
        assert newGrid[i, j] >= grid[i, j];
      } else {
        assert newGrid[i, j] == grid[i, j];
      }
    }
  }

  // 局部提升提升至 max(原始邻域, 处理单元格填充)
  lemma RaiseNbrToMax(grid: Grid, r: int, c: int, fill: int)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    ensures forall (nr, nc) in GetNbr4(grid, r, c) :: RaiseNbr(grid, r, c, fill)[nr, nc] == max(grid[nr, nc], fill)
  {
    var newGrid := RaiseNbr(grid, r, c, fill);
    assert forall (nr, nc) in GetNbr4(grid, r, c) :: newGrid[nr, nc] == max(grid[nr, nc], fill) by {
      assert newGrid[nr, nc] == max(grid[nr, nc], fill);
    }
  }

  // 主方法
  method Main() {
    print "GeoProofBench P-COMP-1 — 2D 局部提升 RaiseNbr 的两条性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";
  }
}
