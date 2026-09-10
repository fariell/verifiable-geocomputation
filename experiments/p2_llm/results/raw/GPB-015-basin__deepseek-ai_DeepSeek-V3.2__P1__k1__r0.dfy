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
//  这一性质是流域划分算法正确性的基础:若同一单元格可流向两个不同出口,
//  则流域边界将出现矛盾。
//
//  本文件形式化该唯一性,采用有界迭代 stepN 而非 SMT 递归搜索不动点,
//  避免对终止性的全称量化,专注于"若两条有限路径都终止,则出口相等"。
//  这对应 GPB-015 Layer A 的代数部分。
//
//  注:本证明不要求全局终止性(允许循环),仅要求当两条有限路径都找到
//  出口时,这两个出口是同一个单元格。
// ===========================================================================

module WatershedUniqueness {

  // ------------------------------------------------------------------
  // 网格坐标与流向约定
  // ------------------------------------------------------------------
  type Cell = (int, int)  // (行, 列), 行向下为正

  // D8 方向名(引用自 P005 模块,此处仅声明签名)
  datatype D8Dir = NoFlow | E | NE | N | NW | W | SW | S | SE

  // 流向函数:给定高程矩阵和单元格,返回流向(可能为 NoFlow)
  // 此为抽象函数,具体实现见 P005_d8 模块
  function D8At(h: array2<real>, r: int, c: int): D8Dir

  // 后继函数:若流向非 NoFlow,则移动到相邻单元格
  function Successor(h: array2<real>, cell: Cell): Cell
    requires 0 <= cell.0 < h.Length0 && 0 <= cell.1 < h.Length1
  {
    var (r, c) := cell;
    var dir := D8At(h, r, c);
    if dir == NoFlow then
      (r, c)
    else
      match dir {
        case E  => (r, c+1)
        case NE => (r-1, c+1)
        case N  => (r-1, c)
        case NW => (r-1, c-1)
        case W  => (r, c-1)
        case SW => (r+1, c-1)
        case S  => (r+1, c)
        case SE => (r+1, c+1)
      }
  }

  // ------------------------------------------------------------------
  // 有界迭代:应用后继函数 step 次
  // ------------------------------------------------------------------
  function StepN(h: array2<real>, start: Cell, step: nat): Cell
    requires 0 <= start.0 < h.Length0 && 0 <= start.1 < h.Length1
    decreases step
  {
    if step == 0 then
      start
    else
      Successor(h, StepN(h, start, step-1))
  }

  // ------------------------------------------------------------------
  // 不动点判定:单元格是否为出口(流向自身)
  // ------------------------------------------------------------------
  predicate IsFixedPoint(h: array2<real>, cell: Cell)
    requires 0 <= cell.0 < h.Length0 && 0 <= cell.1 < h.Length1
  {
    Successor(h, cell) == cell
  }

  // ------------------------------------------------------------------
  // 主要定理:若从同一单元格出发,在有限步 m 和 n 都到达不动点,
  // 则这两个不动点是同一个单元格。
  // ------------------------------------------------------------------
  theorem WatershedUniqueness(
    h: array2<real>,
    start: Cell,
    m: nat, n: nat
  )
    requires 0 <= start.0 < h.Length0 && 0 <= start.1 < h.Length1
    requires IsFixedPoint(h, StepN(h, start, m))
    requires IsFixedPoint(h, StepN(h, start, n))
    ensures StepN(h, start, m) == StepN(h, start, n)
  {
    // 关键观察:一旦到达不动点,继续迭代将停留在该点
    // 即:对于任意 k ≥ m, StepN(h, start, k) = StepN(h, start, m)
    // 同理对于 n。
    // 因此,取 k = max(m, n), 两个表达式都等于 StepN(h, start, k)
    var k := if m > n then m else n;
    lemma_fixed_point_stable(h, start, m, k);
    lemma_fixed_point_stable(h, start, n, k);
  }

  // ------------------------------------------------------------------
  // 辅助引理:若第 m 步是不动点,则所有后续步都停留在此点
  // ------------------------------------------------------------------
  lemma lemma_fixed_point_stable(
    h: array2<real>,
    start: Cell,
    m: nat, k: nat
  )
    requires 0 <= start.0 < h.Length0 && 0 <= start.1 < h.Length1
    requires m <= k
    requires IsFixedPoint(h, StepN(h, start, m))
    ensures StepN(h, start, k) == StepN(h, start, m)
    decreases k - m
  {
    if m == k {
      // 基础情况
    } else {
      // 归纳步骤
      lemma_fixed_point_stable(h, start, m, k-1);
      // 现在 StepN(h, start, k-1) = StepN(h, start, m)
      var prev := StepN(h, start, k-1);
      // 由不动点性质,后继仍是自身
      assert Successor(h, prev) == prev;
      // 因此 StepN(h, start, k) = Successor(h, prev) = prev
      assert StepN(h, start, k) == StepN(h, start, m);
    }
  }

  // ------------------------------------------------------------------
  // 推论:若两条有限路径都终止于出口,则出口相同
  // (等价于定理,但使用路径长度可能不同)
  // ------------------------------------------------------------------
  corollary UniqueOutletIfBothTerminate(
    h: array2<real>,
    start: Cell,
    steps1: nat, steps2: nat
  )
    requires 0 <= start.0 < h.Length0 && 0 <= start.1 < h.Length1
    requires IsFixedPoint(h, StepN(h, start, steps1))
    requires IsFixedPoint(h, StepN(h, start, steps2))
    ensures StepN(h, start, steps1) == StepN(h, start, steps2)
  {
    WatershedUniqueness(h, start, steps1, steps2);
  }

  // ------------------------------------------------------------------
  // 注记:与 GPB-015 Layer B 的关系
  // ------------------------------------------------------------------
  // 本文件证明的是 Layer A:当轨道终止时,出口唯一。
  // Layer B (P-006b) 构造了一个 4 单元格的平坦环,其中流向形成循环,
  // 不存在不动点。该反例不违反本定理,因为前提条件(存在不动点)不满足。
  //
  // 实际 DEM 中,平坦区域确实可能产生循环,此时流域划分需要额外处理
  // (如填洼或平坦区域解析)。本定理划清了确定性流向的可靠边界:
  //   终止 → 唯一出口
  //   不终止 → 需要额外算法处理
  // ==================================================================
}

method Main() {
  print "GeoProofBench P-006 — 确定性 D8 流向下的流域出口唯一性\n";
  print "验证命令: dafny verify P006_watershed.dfy\n";
  print "覆盖: GPB-015 Layer A (终止轨道出口唯一性)\n";
}
