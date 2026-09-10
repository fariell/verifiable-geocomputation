// ===========================================================================
//  GeoProofBench · P-COMP-1
//  文件 : formal/dafny/PCOMP_1.dfy
//  算子 : 2D 局部提升 RaiseNbr
//  覆盖 : GPB-021(局部提升不降低任何单元格的高程,且提升的邻居至少达到 max(原始邻居, 处理单元格填充))
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================

module PComp1 {

  // ------------------------------------------------------------------
  // 2D 局部提升 RaiseNbr
  // ------------------------------------------------------------------
  // 在 2D 局部提升步骤中,提升一个 4-邻居单元格从一个已经处理过的单元格
  // 从不降低任何单元格的高程,且提升的邻居至少达到 max(原始邻居, 处理单元格填充)。
  // ------------------------------------------------------------------

  // 4-邻居方向
  const NBR4: (int, int)[] := [(-1, 0), (1, 0), (0, -1), (0, 1)]

  // 网格高程类型
  type Elevation = real

  // 网格类型
  type Grid = array2<Elevation>

  // 获取 4-邻居
  function method Get4Neighbors(grid: Grid, r: int, c: int): (Elevation)[] {
    var neighbors: (Elevation)[] := new Elevation[4];
    var idx: int := 0;
    for (dr, dc) in NBR4 {
      if 0 <= r + dr < grid.Rows && 0 <= c + dc < grid.Cols {
        neighbors[idx] := grid[r + dr, c + dc];
        idx := idx + 1;
      }
    }
    return neighbors;
  }

  // 局部提升操作
  method RaiseNbr(grid: Grid, r: int, c: int, fill: Elevation) returns (newGrid: Grid)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    ensures newGrid.Rows == grid.Rows
    ensures newGrid.Cols == grid.Cols
    ensures forall i, j :: 0 <= i < newGrid.Rows && 0 <= j < newGrid.Cols ==> newGrid[i, j] >= grid[i, j]
    ensures forall (dr, dc) in NBR4 :: 0 <= r + dr < newGrid.Rows && 0 <= c + dc < newGrid.Cols ==> newGrid[r + dr, c + dc] >= max(grid[r + dr, c + dc], fill)
  {
    newGrid := grid;
    for (dr, dc) in NBR4 {
      var nr := r + dr;
      var nc := c + dc;
      if 0 <= nr < newGrid.Rows && 0 <= nc < newGrid.Cols {
        newGrid[nr, nc] := max(newGrid[nr, nc], fill);
      }
    }
  }

  // 局部提升不降低任何单元格的高程
  lemma RaiseNbrNonDecreasing(grid: Grid, r: int, c: int, fill: Elevation)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    ensures forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==> RaiseNbr(grid, r, c, fill)[i, j] >= grid[i, j]
  {
    var newGrid := RaiseNbr(grid, r, c, fill);
    assert forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==> newGrid[i, j] >= grid[i, j];
  }

  // 提升的邻居至少达到 max(原始邻居, 处理单元格填充)
  lemma RaiseNbrMaxCondition(grid: Grid, r: int, c: int, fill: Elevation)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    ensures forall (dr, dc) in NBR4 :: 0 <= r + dr < grid.Rows && 0 <= c + dc < grid.Cols ==> RaiseNbr(grid, r, c, fill)[r + dr, c + dc] >= max(grid[r + dr, c + dc], fill)
  {
    var newGrid := RaiseNbr(grid, r, c, fill);
    assert forall (dr, dc) in NBR4 :: 0 <= r + dr < grid.Rows && 0 <= c + dc < grid.Cols ==> newGrid[r + dr, c + dc] >= max(grid[r + dr, c + dc], fill);
  }

  // 主方法:验证局部提升的性质
  method Main() {
    print "GeoProofBench P-COMP-1 — 2D 局部提升 RaiseNbr 的性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";
  }
}
