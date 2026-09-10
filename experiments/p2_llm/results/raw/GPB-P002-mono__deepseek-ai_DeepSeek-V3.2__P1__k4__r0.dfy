// ===========================================================================
//  GeoProofBench · P-002-bis (1D specialization)
//  文件 : formal/dafny/P002_bis_1d_wang_liu_fill.dfy
//  算子 : Wang & Liu (1996) 洼地填平 · 一维左出口特化
//  覆盖 : GPB-021 的一维代数核心(单调性、非递减性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_bis_1d_wang_liu_fill.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么做一维特化(科学动机)
//  --------------------------
//  Wang & Liu 的二维填洼算法在 GPB-021 中用于消除 4-邻域洼地。
//  其核心递推规则是: Fill[i] = max(orig[i], Fill[i-1]) (左出口)。
//  一维特化保留了该规则的全部单调性本质,但避免了二维的边界播种、
//  优先队列等控制结构,让我们可以聚焦于**高程单调性**的形式证明。
//
//  本文件证明两条基本性质:
//     1) 每次抬高都是单调的: 填平后的高程不低于原始高程。
//     2) 完整扫描后,剖面是非递减的: 从左到右不会下降。
//
//  这两条性质是二维填洼算法正确性的基石,也是后续流向分析(P-005)
//  和流域划分(P-006)的前提。
// ===========================================================================

module OneDWangLiuFill {

  // ------------------------------------------------------------------
  // 一维高程剖面(长度 n ≥ 1)
  // ------------------------------------------------------------------
  type Index = int
  const n: int
  ghost predicate ValidIndex(i: Index) {
    0 <= i < n
  }

  // 原始高程剖面
  const orig: array<real>

  // 填平后的高程剖面
  function Fill(i: Index): real
    requires ValidIndex(i)
    reads orig
    decreases i
  {
    if i == 0 then orig[0]
    else
      let prev := Fill(i-1) in
      if orig[i] > prev then orig[i] else prev
  }

  // ==================================================================
  // 性质 1: 每次抬高都是单调的
  //   ∀i. Fill[i] ≥ orig[i]
  // ==================================================================
  lemma FillIsMonotone(i: Index)
    requires ValidIndex(i)
    ensures Fill(i) >= orig[i]
    decreases i
  {
    if i == 0 {
      // 基态: Fill[0] = orig[0]
    } else {
      // 归纳步: Fill[i] = max(orig[i], Fill[i-1])
      FillIsMonotone(i-1);
      // 由 max 的定义直接得出
    }
  }

  // ==================================================================
  // 性质 2: 完整扫描后剖面是非递减的
  //   ∀i < n-1. Fill[i] ≤ Fill[i+1]
  // ==================================================================
  lemma FillIsNondecreasing(i: Index)
    requires ValidIndex(i) && i < n-1
    ensures Fill(i) <= Fill(i+1)
    decreases i
  {
    // 对 i 进行归纳
    if i == 0 {
      // 检查 Fill[0] 和 Fill[1]
      // Fill[1] = max(orig[1], Fill[0])
      // 因此 Fill[1] ≥ Fill[0]
    } else {
      // 归纳假设: Fill(i-1) ≤ Fill(i)
      FillIsNondecreasing(i-1);
      // 现在证明 Fill(i) ≤ Fill(i+1)
      // Fill(i+1) = max(orig[i+1], Fill(i))
      // 因此 Fill(i+1) ≥ Fill(i)
    }
  }

  // ==================================================================
  // 辅助引理: 递推关系的显式形式
  //  用于外部模块引用时的不变式构造
  // ==================================================================
  lemma FillRecurrence(i: Index)
    requires ValidIndex(i)
    ensures Fill(i) == if i == 0 then orig[0]
                       else (if orig[i] > Fill(i-1) then orig[i] else Fill(i-1))
  {
    // 由函数定义直接得出
  }

  // ==================================================================
  // 边界条件与完整性
  // ------------------------------------------------------------------
  // 一维特化中,左边界(i=0)是自然出口,其高程保持不变。
  // 右边界没有特殊处理,但非递减性保证了 Fill[n-1] 是全局最大值。
  // ==================================================================
  lemma LeftBoundary()
    ensures Fill(0) == orig[0]
  {
    // 由定义
  }

  lemma GlobalMaximum()
    ensures forall j: Index :: ValidIndex(j) ==> Fill(j) <= Fill(n-1)
  {
    // 由非递减性归纳可得
    forall j: Index | ValidIndex(j)
      ensures Fill(j) <= Fill(n-1)
    {
      var k := j;
      while k < n-1
        invariant ValidIndex(k)
        invariant Fill(j) <= Fill(k)
        decreases n-1-k
      {
        FillIsNondecreasing(k);
        k := k + 1;
      }
    }
  }
}

method Main() {
  print "GeoProofBench P-002-bis — 一维 Wang & Liu 填洼单调性证明\n";
  print "验证: dafny verify P002_bis_1d_wang_liu_fill.dfy\n";
}
