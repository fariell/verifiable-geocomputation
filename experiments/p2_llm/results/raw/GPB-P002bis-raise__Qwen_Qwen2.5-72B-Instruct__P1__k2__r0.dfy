// ===========================================================================
//  GeoProofBench · P-COMP-1
//  文件 : formal/dafny/PCOMP_1.dfy
//  算子 : 2D 局部提升 RaiseNbr
//  覆盖 : GPB-021(局部提升 4-邻域不降低高程)
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  在局部提升步骤中,提升 4-邻域的高程不会降低任何单元格的高程,并且邻域单元格
//  的高程至少被提升到 max(原始邻域高程, 处理单元格的填充值)。这一性质确保了
//  填洼过程中的高程一致性,是验证空间计算中填洼算法正确性的基础。
// ===========================================================================

module PCOMP_1 {

  // 4-邻域定义
  const NBR4: (int, int)[] := [(-1, 0), (1, 0), (0, -1), (0, 1)];

  // 2D 网格类型
  type Grid = array2 real;

  // 获取 4-邻域
  function method Get4Neighbors(grid: Grid, r: int, c: int): (real, real, real, real)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 0 < r < grid.Rows - 1
    requires 0 < c < grid.Cols - 1
  {
    (grid[r-1, c], grid[r+1, c], grid[r, c-1], grid[r, c+1])
  }

  // 局部提升函数
  function method RaiseNbr(grid: Grid, r: int, c: int, fill: real): Grid
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 0 < r < grid.Rows - 1
    requires 0 < c < grid.Cols - 1
    requires fill >= 0.0
  {
    var (n1, n2, n3, n4) := Get4Neighbors(grid, r, c);
    var newGrid := grid;
    newGrid[r-1, c] := max(n1, fill);
    newGrid[r+1, c] := max(n2, fill);
    newGrid[r, c-1] := max(n3, fill);
    newGrid[r, c+1] := max(n4, fill);
    newGrid
  }

  // 局部提升不降低高程
  lemma RaiseNbrDoesNotDecreaseElevation(grid: Grid, r: int, c: int, fill: real)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 0 < r < grid.Rows - 1
    requires 0 < c < grid.Cols - 1
    requires fill >= 0.0
    ensures forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==>
      RaiseNbr(grid, r, c, fill)[i, j] >= grid[i, j]
  {
    var (n1, n2, n3, n4) := Get4Neighbors(grid, r, c);
    var newGrid := RaiseNbr(grid, r, c, fill);

    // 检查中心单元格
    assert newGrid[r, c] == grid[r, c];

    // 检查 4-邻域
    assert newGrid[r-1, c] == max(n1, fill) >= grid[r-1, c];
    assert newGrid[r+1, c] == max(n2, fill) >= grid[r+1, c];
    assert newGrid[r, c-1] == max(n3, fill) >= grid[r, c-1];
    assert newGrid[r, c+1] == max(n4, fill) >= grid[r, c+1];

    // 检查其他单元格
    forall i, j | 0 <= i < grid.Rows && 0 <= j < grid.Cols
      ensures newGrid[i, j] >= grid[i, j]
    {
      if i == r && j == c {
        // 中心单元格保持不变
        assert newGrid[i, j] == grid[i, j];
      } else if (i == r-1 && j == c) || (i == r+1 && j == c) || (i == r && j == c-1) || (i == r && j == c+1) {
        // 4-邻域单元格提升
        assert newGrid[i, j] == max(grid[i, j], fill) >= grid[i, j];
      } else {
        // 其他单元格保持不变
        assert newGrid[i, j] == grid[i, j];
      }
    }
  }

  // 局部提升提升邻域到 max(原始邻域, 处理单元格的填充值)
  lemma RaiseNbrLiftsToMax(grid: Grid, r: int, c: int, fill: real)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 0 < r < grid.Rows - 1
    requires 0 < c < grid.Cols - 1
    requires fill >= 0.0
    ensures forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==>
      (i == r-1 && j == c) || (i == r+1 && j == c) || (i == r && j == c-1) || (i == r && j == c+1) ==>
      newGrid[i, j] == max(grid[i, j], fill)
  {
    var (n1, n2, n3, n4) := Get4Neighbors(grid, r, c);
    var newGrid := RaiseNbr(grid, r, c, fill);

    // 检查 4-邻域
    assert newGrid[r-1, c] == max(n1, fill);
    assert newGrid[r+1, c] == max(n2, fill);
    assert newGrid[r, c-1] == max(n3, fill);
    assert newGrid[r, c+1] == max(n4, fill);

    // 检查其他单元格
    forall i, j | 0 <= i < grid.Rows && 0 <= j < grid.Cols
      ensures (i == r-1 && j == c) || (i == r+1 && j == c) || (i == r && j == c-1) || (i == r && j == c+1) ==>
        newGrid[i, j] == max(grid[i, j], fill)
    {
      if (i == r-1 && j == c) || (i == r+1 && j == c) || (i == r && j == c-1) || (i == r && j == c+1) {
        assert newGrid[i, j] == max(grid[i, j], fill);
      }
    }
  }

  method Main() {
    print "GeoProofBench P-COMP-1 — 2D 局部提升 RaiseNbr 的性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";
  }
}
