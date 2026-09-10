// ===========================================================================
//  GeoProofBench · P-002-bis
//  文件 : formal/dafny/P002_bis_raise_nbr.dfy
//  算子 : Wang & Liu (2016) 填洼的局部抬升步骤
//  覆盖 : GPB-021 的代数部分(抬升邻居不降低高程)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_bis_raise_nbr.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么需要这个引理(科学动机)
//  ----------------------------
//  Wang & Liu 的 4-连通填洼算法从边界开始,以优先队列传播高程。
//  核心步骤 RaiseNbr 处理一个已填充的单元格 p 和它的 4-邻居 n:
//      新高程 = max(原始邻居高程, 已填充单元格的高程)
//
//  这个步骤必须保证两个关键的不变量:
//      1) 不会降低任何单元格的高程(单调性)
//      2) 邻居至少被抬升到 max(原始邻居, 已填充单元格)
//
//  本文件证明这个局部步骤满足这两个性质,为整个填洼算法的
//  正确性提供基础模块。
//
// ===========================================================================

module RaiseNbr {
  // ------------------------------------------------------------------
  // 核心函数: 抬升邻居的高程
  // 参数:
  //   orig_nbr: 邻居单元格的原始高程
  //   fill_cell: 已处理单元格的填充后高程
  // 返回: 邻居单元格的新高程
  // ------------------------------------------------------------------
  function RaiseNbr(orig_nbr: real, fill_cell: real): real
  {
    if orig_nbr >= fill_cell then orig_nbr else fill_cell
  }

  // ==================================================================
  // 性质 1: 抬升不会降低高程
  // 对于任何 orig_nbr 和 fill_cell, RaiseNbr 的结果 ≥ orig_nbr
  // ==================================================================
  lemma RaiseNbrNeverDecreases(orig_nbr: real, fill_cell: real)
    ensures RaiseNbr(orig_nbr, fill_cell) >= orig_nbr
  {
    // 根据 RaiseNbr 的定义直接得出
    // 情况 1: orig_nbr >= fill_cell → 返回 orig_nbr = orig_nbr
    // 情况 2: orig_nbr < fill_cell → 返回 fill_cell > orig_nbr
  }

  // ==================================================================
  // 性质 2: 邻居至少被抬升到 max(原始邻居, 已填充单元格)
  // 实际上, RaiseNbr 的结果就是 max(orig_nbr, fill_cell)
  // ==================================================================
  lemma RaiseNbrLiftsToMax(orig_nbr: real, fill_cell: real)
    ensures RaiseNbr(orig_nbr, fill_cell) >= orig_nbr
    ensures RaiseNbr(orig_nbr, fill_cell) >= fill_cell
    ensures RaiseNbr(orig_nbr, fill_cell) == (
      if orig_nbr >= fill_cell then orig_nbr else fill_cell
    )
  {
    // 第一个确保条件已由 RaiseNbrNeverDecreases 证明
    // 第二个确保条件:
    //   情况 1: orig_nbr >= fill_cell → RaiseNbr = orig_nbr ≥ fill_cell
    //   情况 2: orig_nbr < fill_cell → RaiseNbr = fill_cell ≥ fill_cell
    // 第三个确保条件就是函数定义
  }

  // ==================================================================
  // 组合引理: 同时满足两个性质
  // 这正是任务规格中描述的性质
  // ==================================================================
  lemma RaiseNbrProperties(orig_nbr: real, fill_cell: real)
    ensures RaiseNbr(orig_nbr, fill_cell) >= orig_nbr  // 不降低高程
    ensures RaiseNbr(orig_nbr, fill_cell) >= (
      if orig_nbr >= fill_cell then orig_nbr else fill_cell
    )  // 抬升到至少 max(orig_nbr, fill_cell)
  {
    // 调用已证明的引理
    RaiseNbrNeverDecreases(orig_nbr, fill_cell);
    // 第二个确保条件等价于 RaiseNbr >= max(orig_nbr, fill_cell)
    // 而根据定义，RaiseNbr 就是 max(orig_nbr, fill_cell)
    assert RaiseNbr(orig_nbr, fill_cell) == (
      if orig_nbr >= fill_cell then orig_nbr else fill_cell
    );
  }
}

method Main() {
  print "GeoProofBench P-002-bis — RaiseNbr 的两个关键性质\n";
  print "1. 抬升邻居不会降低其高程\n";
  print "2. 邻居被抬升到至少 max(原始邻居, 已处理单元格)\n";
  print "全部由编译期验证: dafny verify P002_bis_raise_nbr.dfy\n";
}
