// ===========================================================================
//  GeoProofBench · P-002-bis (1D specialization)
//  文件 : formal/dafny/P002_bis_1d_wang_liu_fill.dfy
//  算子 : Wang & Liu (2002) 洼地填平 (一维左出口特化)
//  覆盖 : GPB-021 的一维代数核心 (单调性、非递减性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_bis_1d_wang_liu_fill.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  Phase 2 的复合验证(P-COMP-1)需要洼地填平作为前置条件。二维 Wang & Liu
//  填平算法在边界播种、4-邻接泛洪,其核心递归规则是:
//      fill[n] = max(orig[n], fill[p])   // p 是已填平的邻居
//
//  一维左出口特化是二维算法的退化情形:只有左邻居 p = i-1 是已处理的。
//  这保留了算法的单调性本质,但简化了证明结构,可作为二维证明的引理基石。
//
//  本文件证明两个基本性质:
//    (i)  每次抬高都是单调的(没有单元格高程降低)
//    (ii) 完整扫描后,剖面是非递减的
//
//  这两个性质是后续验证 D8 严格下降和环终止的基础(见 P-COMP-1)。
// ===========================================================================

module OneDWangLiuFill {

  // ------------------------------------------------------------------
  // 1D 剖面约定
  //
  //   orig[0..N-1] : 原始高程剖面
  //   fill[0..N-1] : 填平后高程剖面
  //
  //  左出口特化: fill[0] = orig[0]
  //              fill[i] = max(orig[i], fill[i-1])   for i > 0
  // ------------------------------------------------------------------

  // ---- 填平算子 (递归定义) ----
  function Fill(orig: seq<real>, i: int): real
    requires 0 <= i < |orig|
    decreases i
  {
    if i == 0 then orig[0]
    else
      let prev := Fill(orig, i-1) in
      if orig[i] > prev then orig[i] else prev
  }

  // ---- 辅助引理: 单调性 (每次抬高不降低) ----
  lemma FillMonotoneStep(orig: seq<real>, i: int)
    requires 0 <= i < |orig|
    ensures Fill(orig, i) >= orig[i]
    decreases i
  {
    if i > 0 {
      FillMonotoneStep(orig, i-1);
      // 根据定义: Fill(orig, i) = max(orig[i], Fill(orig, i-1))
      // 因此 Fill(orig, i) >= orig[i]
    }
  }

  // ---- 主要性质 1: 每次抬高都是单调的 (没有单元格高程降低) ----
  lemma NoDecrease(orig: seq<real>, i: int)
    requires 0 <= i < |orig|
    ensures Fill(orig, i) >= orig[i]
  {
    FillMonotoneStep(orig, i);
  }

  // ---- 辅助引理: 序列单调性 (递推关系) ----
  lemma FillMonotoneSequence(orig: seq<real>, i: int)
    requires 0 <= i < |orig|
    ensures i > 0 ==> Fill(orig, i) >= Fill(orig, i-1)
    decreases i
  {
    if i > 0 {
      FillMonotoneSequence(orig, i-1);
      // 根据定义: Fill(orig, i) = max(orig[i], Fill(orig, i-1))
      // 因此 Fill(orig, i) >= Fill(orig, i-1)
    }
  }

  // ---- 主要性质 2: 完整扫描后剖面是非递减的 ----
  lemma NondecreasingProfile(orig: seq<real>)
    ensures forall i, j :: 0 <= i <= j < |orig| ==> Fill(orig, i) <= Fill(orig, j)
  {
    forall i, j | 0 <= i <= j < |orig|
      ensures Fill(orig, i) <= Fill(orig, j)
    {
      if i == j {
        // 平凡情况
      } else {
        // 对 j 进行归纳
        var k := i + 1;
        while k <= j
          invariant i <= k <= j+1
          invariant Fill(orig, i) <= Fill(orig, k-1)
          decreases j - k
        {
          FillMonotoneSequence(orig, k);
          k := k + 1;
        }
      }
    }
  }

  // ==================================================================
  // 结构注记
  // ------------------------------------------------------------------
  // 一维左出口特化保留了 Wang & Liu 算法的两个关键代数性质:
  //
  //   1) 单调性: 每个单元格在填平后不会低于原始高程。
  //      这是由 max(orig[i], fill[i-1]) 保证的。
  //
  //   2) 非递减性: 填平后的剖面从左到右不会下降。
  //      这是由递推关系 fill[i] >= fill[i-1] 保证的。
  //
  //  这两个性质在二维情况下依然成立,但证明需要处理 4-邻接泛洪的
  //  偏序关系。一维证明为二维证明提供了归纳基础。
  //
  //  在 P-COMP-1 中,非递减性用于证明 D8 流路在填平后的 DEM 上
  //  严格下降(除了平坦区域),从而保证环终止。
  // ==================================================================
}

method Main() {
  print "GeoProofBench P-002-bis — 1D Wang & Liu 洼地填平单调性\n";
  print "全部由编译期验证: dafny verify P002_bis_1d_wang_liu_fill.dfy\n";
}
