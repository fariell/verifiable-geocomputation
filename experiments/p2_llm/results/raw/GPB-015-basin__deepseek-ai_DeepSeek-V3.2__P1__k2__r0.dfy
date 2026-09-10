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
//  Phase 1 实验显示，在确定性 D8 流向规则下，从同一单元格出发的流径
//  总是收敛到同一个出口点（即使流径长度不同）。这一观察需要形式化证明，
//  以确立流域划分算法的代数基础。
//
//  本文件证明：对于给定的有限网格和确定性后继函数，若从同一单元格出发
//  的轨道在有限步内终止于固定点（出口），则无论终止步数如何，出口相同。
//  证明使用有界迭代 stepN，避免依赖 SMT 递归搜索固定点。
//
//  注：本证明不要求全局无环（允许存在平坦区域循环），但要求所考虑的
//  两条轨道均在有限步内终止于固定点。
// ===========================================================================

module WatershedUniqueness {
  import opened D8Kernel  // 从现有模块导入 D8 流向核

  // ------------------------------------------------------------------
  // 网格坐标与后继函数
  // ------------------------------------------------------------------
  type Cell = (int, int)
  predicate ValidCell(c: Cell, rows: int, cols: int) {
    0 <= c.0 < rows && 0 <= c.1 < cols
  }

  // 确定性后继函数：给定高程网格和单元格，返回流向的相邻单元格或自身（无流）
  function Succ(h: array2<real>, c: Cell): Cell
    requires h.Length0 > 0 && h.Length1 > 0
    requires ValidCell(c, h.Length0, h.Length1)
    reads h
  {
    D8Kernel.D8Flow(h, c)
  }

  // ------------------------------------------------------------------
  // 有界迭代：应用后继函数 n 次
  // ------------------------------------------------------------------
  function stepN(h: array2<real>, start: Cell, n: nat): Cell
    requires h.Length0 > 0 && h.Length1 > 0
    requires ValidCell(start, h.Length0, h.Length1)
    reads h
    decreases n
  {
    if n == 0 then start
    else Succ(h, stepN(h, start, n-1))
  }

  // ------------------------------------------------------------------
  // 固定点谓词：单元格是自身后继（即出口）
  // ------------------------------------------------------------------
  predicate isFixedPoint(h: array2<real>, c: Cell)
    requires h.Length0 > 0 && h.Length1 > 0
    requires ValidCell(c, h.Length0, h.Length1)
    reads h
  {
    Succ(h, c) == c
  }

  // ------------------------------------------------------------------
  // 主要定理：若从同一单元格出发的两条有界轨道均终止于固定点，
  // 则它们的出口相同。
  // ------------------------------------------------------------------
  theorem WatershedUniqueness(
    h: array2<real>,
    start: Cell,
    m: nat, n: nat
  )
    requires h.Length0 > 0 && h.Length1 > 0
    requires ValidCell(start, h.Length0, h.Length1)
    requires isFixedPoint(h, stepN(h, start, m))
    requires isFixedPoint(h, stepN(h, start, n))
    ensures stepN(h, start, m) == stepN(h, start, n)
    reads h
  {
    // 关键引理：一旦到达固定点，继续迭代不会改变结果
    lemma FixedPointStable(k: nat, p: Cell)
      requires isFixedPoint(h, p)
      ensures stepN(h, p, k) == p
      decreases k
    {
      if k == 0 {
        // base case
      } else {
        FixedPointStable(k-1, p);
        assert stepN(h, p, k) == Succ(h, stepN(h, p, k-1));
        assert stepN(h, p, k-1) == p;
        assert Succ(h, p) == p;
      }
    }

    // 情况分析：假设 m ≤ n（对称性）
    if m <= n {
      // 将 n 步分解为 m 步 + (n-m) 步
      var outlet_m := stepN(h, start, m);
      FixedPointStable(n - m, outlet_m);
      assert stepN(h, start, n) == stepN(h, outlet_m, n - m);
      assert stepN(h, outlet_m, n - m) == outlet_m;
    } else {
      // 对称情况：n ≤ m
      var outlet_n := stepN(h, start, n);
      FixedPointStable(m - n, outlet_n);
      assert stepN(h, start, m) == stepN(h, outlet_n, m - n);
      assert stepN(h, outlet_n, m - n) == outlet_n;
    }
  }

  // ------------------------------------------------------------------
  // 辅助引理：终止性蕴含固定点（用于连接外部终止性证明）
  // ------------------------------------------------------------------
  lemma TerminationImpliesFixedPoint(
    h: array2<real>,
    start: Cell,
    bound: nat
  )
    requires h.Length0 > 0 && h.Length1 > 0
    requires ValidCell(start, h.Length0, h.Length1)
    requires forall k: nat :: k < bound ==> stepN(h, start, k) != stepN(h, start, k+1)
    requires stepN(h, start, bound) == stepN(h, start, bound+1)
    ensures isFixedPoint(h, stepN(h, start, bound))
    reads h
  {
    var outlet := stepN(h, start, bound);
    assert Succ(h, outlet) == stepN(h, start, bound+1);
    assert stepN(h, start, bound+1) == outlet;
  }
}

// ===========================================================================
// 附注
// ---------------------------------------------------------------------------
// 本证明仅依赖 D8 后继函数的确定性，不要求网格无坑或无平坦区域。
// 定理前提要求两条轨道均终止于固定点，这可由外部条件（如网格边界、无循环）
// 或更大范围的终止性引理保证。
//
// 对于存在循环的非终止情况（如 P-006b 的 4 环），本定理的前提不满足，
// 因此不产生结论——这与 Layer B 的预期行为一致。
// ===========================================================================
