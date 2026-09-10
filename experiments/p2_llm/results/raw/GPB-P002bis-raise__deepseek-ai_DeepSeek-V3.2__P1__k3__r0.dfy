// ===========================================================================
//  GeoProofBench · P-COMP-1 (partial)
//  文件 : formal/dafny/PCOMP_1_RaiseNbr.dfy
//  算子 : Wang & Liu (2016) 填洼的 4‑邻域抬升步骤
//  覆盖 : GPB-021 的代数部分 (RaiseNbr 单调性与下界)
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1_RaiseNbr.dfy
//  日期 : 2026‑09‑06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  Phase 2 的复合验证 P‑COMP‑1 需要三个代数引理:
//      (i)   填洼后 4‑邻域无坑 (min(nbr) ≤ cell)
//      (ii)  平面上的 D8 严格下降 (每步 ≥ 1)
//      (iii) 5×5 平面内环终止 (≤ 50 步)
//
//  本文件处理 (i) 的核心构造块: RaiseNbr 步骤的单调性与下界。
//  这是 W&L 填洼算法正确性的基石——若抬升步骤本身不保持单调，
//  后续的流域分析将失去可靠的高程序。
//
//  注意: 这里只形式化 RaiseNbr 的局部性质，全局填洼的收敛性
//  需要额外的归纳论证（见 P‑002‑bis 或 Lean4 形式化）。
// ===========================================================================

module RaiseNbr {
  // ------------------------------------------------------------------
  // 类型与常量
  // ------------------------------------------------------------------
  type Cell = real
  const inf: real := 1e308  // 表示未处理的无穷大标记

  // ------------------------------------------------------------------
  // 算子: RaiseNbr (4‑邻域抬升步骤)
  // ------------------------------------------------------------------
  // 输入:
  //   orig_n   : 邻居的原始高程
  //   fill_p   : 已处理单元 p 的填后高程
  // 输出:
  //   邻居 n 的新高程 = max(orig_n, fill_p)
  //
  // 语义: 当算法从已处理的单元 p 扩展到其 4‑邻域 n 时，
  //       将 n 的高程抬升至 orig_n 与 fill_p 的较大者。
  // ------------------------------------------------------------------
  function RaiseNbr(orig_n: Cell, fill_p: Cell): Cell
    requires fill_p != inf  // 已处理单元必须有有限高程
  {
    if orig_n >= fill_p then orig_n else fill_p
  }

  // ==================================================================
  // 性质 1: 单调性 (从不降低任何单元的高程)
  // ==================================================================
  // 对任意 orig_n 和有效的 fill_p，RaiseNbr 的结果 ≥ orig_n。
  // 这是填洼算法保持高程下界的关键。
  // ==================================================================
  lemma RaiseNbrNeverDecreases(orig_n: Cell, fill_p: Cell)
    requires fill_p != inf
    ensures RaiseNbr(orig_n, fill_p) >= orig_n
  {
    // 由定义直接得出: max(orig_n, fill_p) ≥ orig_n
  }

  // ==================================================================
  // 性质 2: 下界保证 (至少抬升至 max(orig_n, fill_p))
  // ==================================================================
  // 实际上，RaiseNbr 的结果就是 max(orig_n, fill_p)。
  // 我们将其拆为两个方向的不等式，以匹配自然语言描述。
  // ==================================================================
  lemma RaiseNbrAtLeastOriginal(orig_n: Cell, fill_p: Cell)
    requires fill_p != inf
    ensures RaiseNbr(orig_n, fill_p) >= orig_n
  {
    // 同性质1，为完整性重述
  }

  lemma RaiseNbrAtLeastProcessed(orig_n: Cell, fill_p: Cell)
    requires fill_p != inf
    ensures RaiseNbr(orig_n, fill_p) >= fill_p
  {
    // 由定义: max(orig_n, fill_p) ≥ fill_p
  }

  // 综合引理: 抬升后的高程恰好是 max(orig_n, fill_p)
  lemma RaiseNbrIsMax(orig_n: Cell, fill_p: Cell)
    requires fill_p != inf
    ensures RaiseNbr(orig_n, fill_p) ==
            (if orig_n >= fill_p then orig_n else fill_p)
  {
    // 由函数定义直接成立
  }

  // ==================================================================
  // 应用示例: 验证一次抬升步骤满足任务要求
  // ==================================================================
  method ExampleRaise() {
    var orig: Cell := 5.0;
    var fill: Cell := 7.0;
    assume fill != inf;

    var raised := RaiseNbr(orig, fill);
    // 验证性质
    assert raised >= orig;          // 从不降低
    assert raised >= fill;          // 至少抬升至 fill
    assert raised == 7.0;           // 恰好是 max(5.0, 7.0)
    print "RaiseNbr(5.0, 7.0) = ", raised, "\n";
  }
}

method Main() {
  print "GeoProofBench P‑COMP‑1 (部分) — RaiseNbr 单调性与下界\n";
  print "验证: dafny verify PCOMP_1_RaiseNbr.dfy\n";
}
