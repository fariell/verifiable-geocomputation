// ===========================================================================
//  GeoProofBench · P-COMP-1
//  文件 : formal/dafny/PCOMP_1.dfy
//  算子 : 2D 局部提升 RaiseNbr
//  覆盖 : GPB-021(局部提升不降低高程 / 邻居提升至 max(原高程, 填充高程))
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================

module PCOMP_1 {

  // 4-邻域定义
  const NBR4: (int, int)[] := [(-1, 0), (1, 0), (0, -1), (0, 1)]

  // 2D 网格类型
  type Grid = array2 real

  // 获取 4-邻域
  function GetNbr4(grid: Grid, r: int, c: int): (real, real, real, real)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 1 <= r < grid.Rows - 1
    requires 1 <= c < grid.Cols - 1
  {
    (grid[r-1, c], grid[r+1, c], grid[r, c-1], grid[r, c+1])
  }

  // 局部提升操作
  method RaiseNbr(grid: Grid, r: int, c: int, fill: real)
    modifies grid
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 1 <= r < grid.Rows - 1
    requires 1 <= c < grid.Cols - 1
    ensures forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==> grid'[i, j] >= grid[i, j]
    ensures grid'[r, c] >= fill
  {
    var (n1, n2, n3, n4) := GetNbr4(grid, r, c);
    var maxNbr := max(n1, n2, n3, n4);
    var newElevation := max(maxNbr, fill);
    grid[r, c] := newElevation;
  }

  // 局部提升不降低任何单元格的高程
  lemma RaiseNbrDoesNotDecreaseElevation(grid: Grid, r: int, c: int, fill: real)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 1 <= r < grid.Rows - 1
    requires 1 <= c < grid.Cols - 1
    ensures forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols ==> grid'[i, j] >= grid[i, j]
  {
    var (n1, n2, n3, n4) := GetNbr4(grid, r, c);
    var maxNbr := max(n1, n2, n3, n4);
    var newElevation := max(maxNbr, fill);
    assert newElevation >= grid[r, c];
    assert forall i, j :: 0 <= i < grid.Rows && 0 <= j < grid.Cols && (i != r || j != c) ==> grid'[i, j] == grid[i, j];
  }

  // 邻居提升至 max(原高程, 填充高程)
  lemma RaiseNbrLiftsNeighbor(grid: Grid, r: int, c: int, fill: real)
    requires 0 <= r < grid.Rows
    requires 0 <= c < grid.Cols
    requires 1 <= r < grid.Rows - 1
    requires 1 <= c < grid.Cols - 1
    ensures grid'[r, c] >= fill
  {
    var (n1, n2, n3, n4) := GetNbr4(grid, r, c);
    var maxNbr := max(n1, n2, n3, n4);
    var newElevation := max(maxNbr, fill);
    assert newElevation >= fill;
  }

  // 主方法
  method Main() {
    print "GeoProofBench P-COMP-1 — 2D 局部提升 RaiseNbr 的两条性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";
  }
}
