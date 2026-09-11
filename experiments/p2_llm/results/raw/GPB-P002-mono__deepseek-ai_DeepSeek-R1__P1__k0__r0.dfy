// ===========================================================================
//  GeoProofBench · P-COMP-1 (1D Wang-Liu pit-filling)
//  算子 : 1D Wang-Liu 填洼算法 (左侧出口)
//  覆盖 : GPB-021 (填洼后地形非递减)、单调性(无高程降低)
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
// ===========================================================================

module WangLiu1D {

  // -------------------------------------------------------------------------
  // 1D 填洼算子定义
  // -------------------------------------------------------------------------
  function method Fill(orig: array<real>, i: int): real
    requires orig != null
    requires 0 <= i < orig.Length
    decreases i  // 递归终止于 i=0
  {
    if i == 0 then orig[0] 
    else max(orig[i], Fill(orig, i-1))
  }

  // -------------------------------------------------------------------------
  // 性质 1: 单调性 (无高程降低)
  // 每个单元的填洼高程 ≥ 原始高程
  // -------------------------------------------------------------------------
  lemma FillMonotone(orig: array<real>, i: int)
    requires orig != null
    requires 0 <= i < orig.Length
    ensures Fill(orig, i) >= orig[i]
  {
    // 递归基础: i=0 时直接相等
    if i > 0 {
      // 归纳步骤: 由 max 性质保证
      assert Fill(orig, i) == max(orig[i], Fill(orig, i-1)) >= orig[i];
    }
  }

  // -------------------------------------------------------------------------
  // 性质 2: 非递减性 (填洼后地形单调)
  // 任意相邻单元满足 fill[i] ≤ fill[i+1]
  // -------------------------------------------------------------------------
  lemma FillNonDecreasing(orig: array<real>, i: int)
    requires orig != null
    requires 0 <= i < orig.Length - 1
    ensures Fill(orig, i) <= Fill(orig, i+1)
  {
    // 由定义直接推导: 
    //   fill[i+1] = max(orig[i+1], fill[i]) ≥ fill[i]
    assert Fill(orig, i+1) == max(orig[i+1], Fill(orig, i)) >= Fill(orig, i);
  }

  // -------------------------------------------------------------------------
  // 全局非递减性 (强结论)
  // 对任意 i ≤ j, 有 fill[i] ≤ fill[j]
  // -------------------------------------------------------------------------
  lemma GlobalNonDecreasing(orig: array<real>, i: int, j: int)
    requires orig != null
    requires 0 <= i <= j < orig.Length
    ensures Fill(orig, i) <= Fill(orig, j)
    decreases j - i
  {
    if i < j {
      // 传递性: i->i+1 和 (i+1)->j
      FillNonDecreasing(orig, i, i+1);
      GlobalNonDecreasing(orig, i+1, j);
    }
  }
}

method Main() {
  print "GeoProofBench P-COMP-1 — 1D Wang-Liu 填洼算子的形式化验证\n";
  print "验证命令: dafny verify PCOMP_1.dfy\n";
}
