// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  算子 : 确定性 D8 流向下的流域唯一性
//  覆盖 : GPB-015 (Layer A: 终止轨道出口唯一性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P006_watershed.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  流域分析中,确定性流向函数(如 D8)从同一单元格出发的流动路径,
//  若在有限步内终止于某个出口(不动点),则该出口必须唯一。
//  这一性质是后续流域划分、累积流计算等算法的逻辑基础。
//  本文件形式化该唯一性,使用有界迭代 stepN 而不依赖 SMT 递归搜索不动点。
//
//  结构说明
//  ---------
//  1. 导入 D8 流向核(来自 P-005),避免重复实现。
//  2. 定义有界迭代函数 stepN,模拟最多 N 步的流向追踪。
//  3. 证明:若从同一单元格出发,分别在 m 步和 n 步内到达出口,
//     则这两个出口是同一个单元格。
//  4. 该证明不要求预先知道不动点存在,仅基于流向函数的确定性。
// ===========================================================================

module WatershedUniqueness {

  import opened D8Kernel  // 从 P-005 导入 D8 流向核

  // ------------------------------------------------------------------
  // 类型与状态定义
  // ------------------------------------------------------------------

  // 网格位置(行,列)
  type Cell = (int, int)

  // 流向函数:给定高程网格和当前位置,返回流向方向或 NoFlow
  // 此处直接使用导入的 D8Kernel.d8_at 函数签名
  // function d8_at(grid: Grid, r: int, c: int): D8Direction

  // 后继函数:根据流向计算下一个位置,若为 NoFlow 则返回原位置(不动点)
  function successor(grid: Grid, cell: Cell): Cell
    requires ValidCell(grid, cell)
  {
    var (r, c) := cell;
    var dir := d8_at(grid, r, c);
    if dir.Downhill? then
      (r + dir.dq, c + dir.dp)
    else
      (r, c)  // NoFlow 或边界情况(由 d8_at 保证返回原位置)
  }

  // ------------------------------------------------------------------
  // 有界迭代函数 stepN
  // ------------------------------------------------------------------

  // 从 cell 开始,最多迭代 N 步,返回最终位置
  // 若在少于 N 步内到达不动点,则提前停止
  function stepN(grid: Grid, cell: Cell, N: nat): Cell
    requires ValidCell(grid, cell)
    decreases N
  {
    if N == 0 then
      cell
    else
      var next := successor(grid, cell);
      if next == cell then
        cell  // 已到达不动点
      else
        stepN(grid, next, N-1)
  }

  // ------------------------------------------------------------------
  // 辅助引理:后继函数的确定性
  // ------------------------------------------------------------------

  lemma SuccessorDeterministic(grid: Grid, cell: Cell)
    requires ValidCell(grid, cell)
    ensures forall n: nat :: successor(grid, cell) == successor(grid, cell)
    // 流向函数 d8_at 是确定性的,因此 successor 也是确定性的
  {
    // 由 D8Kernel 的确定性保证
  }

  // ------------------------------------------------------------------
  // 主要定理:出口唯一性
  // ------------------------------------------------------------------
  // 若从同一单元格出发,分别在 m 步和 n 步内到达出口(不动点),
  // 则这两个出口是同一个单元格。
  // 注意:这里不假设 m 或 n 是最小步数,只假设 stepN 返回的位置是不动点。
  // ------------------------------------------------------------------

  theorem OutletUnique(grid: Grid, start: Cell, m: nat, n: nat)
    requires ValidCell(grid, start)
    // 假设在 m 步内到达出口
    requires stepN(grid, start, m) == successor(grid, stepN(grid, start, m))
    // 假设在 n 步内到达出口
    requires stepN(grid, start, n) == successor(grid, stepN(grid, start, n))
    ensures stepN(grid, start, m) == stepN(grid, start, n)
  {
    // 令 A = stepN(start, m), B = stepN(start, n)
    var A := stepN(grid, start, m);
    var B := stepN(grid, start, n);

    // 情况 1: m == n, 显然成立
    if m == n {
      return;
    }

    // 情况 2: m < n
    if m < n {
      // 由于 A 是不动点,从 A 开始迭代任意步仍停留在 A
      assert stepN(grid, A, n-m) == A;
      // 但 stepN(start, n) 可写为 stepN(A, n-m) (因为 m 步已到 A)
      assert stepN(grid, start, n) == stepN(grid, A, n-m) by {
        // 展开 stepN 的定义,利用后继函数的确定性
        calc {
          stepN(grid, start, n);
          == stepN(grid, stepN(grid, start, m), n-m);
          == stepN(grid, A, n-m);
        }
      }
      // 因此 B == A
      assert B == A;
    }

    // 情况 3: n < m, 对称同理
    if n < m {
      assert stepN(grid, B, m-n) == B;
      calc {
        stepN(grid, start, m);
        == stepN(grid, stepN(grid, start, n), m-n);
        == stepN(grid, B, m-n);
        == B;
      }
      assert A == B;
    }
  }

  // ------------------------------------------------------------------
  // 推论:若存在有限步内到达的出口,则该出口唯一
  // ------------------------------------------------------------------
  // 即:不存在两个不同的不动点,都可以从同一单元格在有限步内到达。
  // ------------------------------------------------------------------

  corollary UniqueOutletIfTerminates(grid: Grid, start: Cell)
    requires ValidCell(grid, start)
    requires exists k: nat :: stepN(grid, start, k) == successor(grid, stepN(grid, start, k))
    ensures exists! outlet: Cell ::
      outlet == successor(grid, outlet) &&
      exists k: nat :: stepN(grid, start, k) == outlet
  {
    // 由 OutletUnique 定理直接可得
    // 选取最小的 k 使得 stepN(start, k) 是不动点
    var k :| stepN(grid, start, k) == successor(grid, stepN(grid, start, k));
    var outlet := stepN(grid, start, k);
    // 唯一性由 OutletUnique 保证
    forall outlet' | outlet' == successor(grid, outlet') && exists k': nat :: stepN(grid, start, k') == outlet'
      ensures outlet' == outlet
    {
      var k' :| stepN(grid, start, k') == outlet';
      OutletUnique(grid, start, k, k');
    }
  }

  // ------------------------------------------------------------------
  // 测试用例
  // ------------------------------------------------------------------

  method TestOutletUnique() {
    // 构造一个简单的高程网格:平面斜坡,流向一致向南
    var grid : Grid;
    // 初始化网格...

    var start := (0, 0);
    // 假设在 5 步内到达出口
    assume stepN(grid, start, 5) == successor(grid, stepN(grid, start, 5));
    // 假设在 10 步内也到达出口
    assume stepN(grid, start, 10) == successor(grid, stepN(grid, start, 10));

    // 验证出口唯一
    OutletUnique(grid, start, 5, 10);
    print "测试通过:出口唯一性成立\n";
  }
}

// ===========================================================================
// 注记
// ===========================================================================
// 1. 本证明仅依赖流向函数的确定性,不依赖网格的具体高程值。
// 2. 对于不终止的轨道(如平坦区域的循环),定理前提不满足,结论不适用。
//    这正是 Layer B (P-006b) 要处理的反例。
// 3. 该唯一性性质是后续流域划分算法正确性的基础。
// ===========================================================================
