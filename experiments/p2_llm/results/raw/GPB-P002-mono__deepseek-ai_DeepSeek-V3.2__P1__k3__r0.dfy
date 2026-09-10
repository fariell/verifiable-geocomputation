// ===========================================================================
//  GeoProofBench · P-002-bis (1D specialization)
//  文件 : formal/dafny/P002_bis_1d_wang_liu_fill.dfy
//  算子 : Wang & Liu (1996) 洼地填平算法的一维特化（左侧出口）
//  覆盖 : GPB-021 的一维代数核心（单调性、非递减性）
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_bis_1d_wang_liu_fill.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条（科学动机）
//  --------------------------
//  Phase 2 的组合验证（P-COMP-1）需要洼地填平算法的形式化性质作为前提。
//  二维 Wang & Liu 算法（4‑邻接泛洪）的核心递归规则是：
//      fill[n] = max(orig[n], fill[p])  其中 p 是已填平的邻居
//
//  一维特化（左侧出口）是理解该规则单调性本质的最简模型：
//      Fill[0] = orig[0]
//      Fill[i] = max(orig[i], Fill[i-1])   for i > 0
//
//  本文件证明两条基本性质：
//      (1) 单调性：每次填平只可能抬高，不会降低高程。
//      (2) 非递减性：完整扫描后，填平后的剖面是非递减的。
//
//  这两条性质是后续证明“填平后无 4‑邻接洼地”的基础（见 GPB-021‑(i)）。
// ===========================================================================

module OneDWangLiuFill {

  // ------------------------------------------------------------------
  // 一维高程剖面（长度为 N 的实数序列）
  // ------------------------------------------------------------------
  type Profile = seq<real>

  // ------------------------------------------------------------------
  // 一维 Wang & Liu 填平（左侧出口）
  // ------------------------------------------------------------------
  function Fill(orig: Profile): Profile
    requires |orig| > 0
    ensures |Fill(orig)| == |orig|
    ensures Fill(orig)[0] == orig[0]
    ensures forall i | 1 <= i < |orig| ::
      Fill(orig)[i] == max(orig[i], Fill(orig)[i-1])
  {
    if |orig| == 1 then [orig[0]]
    else
      var prev := Fill(orig[..|orig|-1]);
      prev + [max(orig[|orig|-1], prev[|prev|-1])]
  }

  // ==================================================================
  // 性质 1：单调性（填平不会降低原始高程）
  // ==================================================================
  lemma FillMonotone(orig: Profile, i: int)
    requires |orig| > 0
    requires 0 <= i < |orig|
    ensures Fill(orig)[i] >= orig[i]
  {
    if i == 0 {
      // 根据定义 Fill(orig)[0] == orig[0]
    } else {
      // 归纳步骤：Fill(orig)[i] == max(orig[i], Fill(orig)[i-1])
      // 因此 Fill(orig)[i] >= orig[i]
    }
  }

  // ==================================================================
  // 性质 2：非递减性（填平后的剖面从左到右不下降）
  // ==================================================================
  lemma FillNonDecreasing(orig: Profile, i: int)
    requires |orig| > 0
    requires 0 <= i < |orig| - 1
    ensures Fill(orig)[i] <= Fill(orig)[i+1]
  {
    // 根据定义 Fill(orig)[i+1] == max(orig[i+1], Fill(orig)[i])
    // 因此 Fill(orig)[i+1] >= Fill(orig)[i]
  }

  // ==================================================================
  // 辅助引理：递推关系的直接展开（用于外部组合证明）
  // ==================================================================
  lemma FillRecursive(orig: Profile, i: int)
    requires |orig| > 0
    requires 1 <= i < |orig|
    ensures Fill(orig)[i] == max(orig[i], Fill(orig)[i-1])
  {
    // 由函数定义直接可得
  }

  // ==================================================================
  // 验证示例（非证明必要，仅演示）
  // ==================================================================
  method Example() {
    var orig: Profile := [3.0, 1.0, 4.0, 1.0, 5.0];
    var filled := Fill(orig);
    print "原始剖面: ", orig, "\n";
    print "填平后:   ", filled, "\n";
    // 验证单调性
    for i := 0 to |orig|-1
      invariant forall j | 0 <= j < i :: filled[j] >= orig[j]
    {
      assert filled[i] >= orig[i] by { FillMonotone(orig, i); }
    }
    // 验证非递减性
    for i := 0 to |orig|-2
      invariant forall j | 0 <= j < i :: filled[j] <= filled[j+1]
    {
      assert filled[i] <= filled[i+1] by { FillNonDecreasing(orig, i); }
    }
    print "一维 Wang & Liu 填平验证通过。\n";
  }
}

method Main() {
  print "GeoProofBench P-002-bis — 一维 Wang & Liu 洼地填平（左侧出口）\n";
  print "性质：单调性、非递减性\n";
  print "验证命令：dafny verify P002_bis_1d_wang_liu_fill.dfy\n";
  OneDWangLiuFill.Example();
}
