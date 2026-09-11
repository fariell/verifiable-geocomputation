// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  算子 : 流域出口的唯一性 (在确定性流函数下)
//  覆盖 : GPB-015 (流域出口的唯一性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P006_watershed.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  在数字地形分析中,流域划分是水文建模的基础。流域的出口是水流路径的终点。
//  本文件证明:在确定性流函数(如D8)下,从同一单元格出发的任意两条有限步长
//  的流路径,若均到达出口(不动点),则这两个出口必相同。
//
//  这保证了流域划分的良定义性:每个单元格属于且仅属于一个流域(以出口为标识)。
//
//  注:本证明不要求流路径是最短路径,也不要求流函数无环(但若存在环,则可能
//      无法在有限步内到达出口,此时本定理的条件不满足)。
//
//  相关反例见 P-006b (人工构建的4元环,无法终止)。
//
// ===========================================================================

module WatershedUniqueness {
  // 单元格类型 (行号, 列号)
  datatype Cell = Cell(row: int, col: int)

  // 确定性流函数 (如D8算法)
  // 约定: 若为出口则返回自身 (succ(c) == c)
  const succ: Cell -> Cell

  // 判断是否为出口 (不动点)
  predicate isOutlet(c: Cell) {
    succ(c) == c
  }

  // 有界迭代函数: 应用succ函数n次
  function stepN(s: Cell, n: nat): Cell
    decreases n;
  {
    if n == 0 then s
    else succ(stepN(s, n-1))
  }

  // ========================================================================
  // 核心引理: 一旦到达出口,后续迭代保持不变
  // ========================================================================
  lemma FixedPointStable(c: Cell, k: nat)
    requires isOutlet(c)
    ensures stepN(c, k) == c
    decreases k;
  {
    if k != 0 {
      // 出口单元格应用succ仍为自身
      // 递归证明后续步骤保持稳定
      FixedPointStable(c, k-1);
    }
  }

  // ========================================================================
  // 步数可加性: stepN(s, m+n) = stepN(stepN(s, m), n)
  // ========================================================================
  lemma StepAdditive(s: Cell, m: nat, n: nat)
    ensures stepN(s, m+n) == stepN(stepN(s, m), n)
    decreases n;
  {
    if n == 0 {}
    else {
      StepAdditive(s, m, n-1);
    }
  }

  // ========================================================================
  // 主定理: 流域出口的唯一性
  // ------------------------------------------------------------------------
  // 若从同一起点s出发:
  //   经n1步到达出口o1 (isOutlet(o1))
  //   经n2步到达出口o2 (isOutlet(o2))
  // 则o1 == o2
  // ========================================================================
  theorem WatershedUniqueOutlet(s: Cell, n1: nat, n2: nat)
    requires isOutlet(stepN(s, n1))
    requires isOutlet(stepN(s, n2))
    ensures stepN(s, n1) == stepN(s, n2)
  {
    // 情况1: n1 ≤ n2
    if n1 <= n2 {
      // 计算步数差
      var diff: nat := n2 - n1;
      // 分解迭代: stepN(s, n2) = stepN(stepN(s, n1), diff)
      StepAdditive(s, n1, diff);
      // 出口稳定性: stepN(o1, diff) = o1
      FixedPointStable(stepN(s, n1), diff);
    }
    // 情况2: n2 < n1 (对称情况)
    else {
      var diff: nat := n1 - n2;
      StepAdditive(s, n2, diff);
      FixedPointStable(stepN(s, n2), diff);
    }
  }
}

method Main() {
  print "GeoProofBench P-006 — 流域出口的唯一性\n";
  print "编译期验证: dafny verify P006_watershed.dfy\n";
}
