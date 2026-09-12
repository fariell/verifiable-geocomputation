// ===========================================================================
//  GeoProofBench · P-COMP-5 / GPB-026
//  算子 : 1D 洼地填充 (左出口)
//  性质 : 幂等性 (Fill(Fill(a)) = Fill(a)) 及不动点 (非洼地单元不变)
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_5_idempotent.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  Phase 2 实验揭示: 二维填洼算法的幂等性高度依赖调度策略(堆的键序)。
//  为分离核心逻辑,本文件聚焦一维特化(左出口),证明:
//      1) 幂等性: 对任意高程序列,重复填充不改变结果
//      2) 不动点: 已满足左出口非洼条件的单元在填充中保持不变
//
//  一维特化是二维算法的基础构件(如流向追踪中的流路)。本证明为后续
//  二维形式化(见 P-002/GPB-021–023)建立代数不变式。
//
// ===========================================================================

module PitFilling1D {

  // -------------------------------------------------------------------------
  // 1D 洼地填充算子 (左出口)
  // 定义: b[0] = a[0]; ∀i≥1, b[i] = max(a[i], b[i-1])
  // 语义: 从左向右传播高程,消除所有洼地(左出口)
  // -------------------------------------------------------------------------
  function Fill(a: seq<real>): seq<real>
    requires |a| > 0  // 非空序列
    ensures |Fill(a)| == |a|
  {
    if |a| == 1 then
      [a[0]]  // 单元素序列
    else
      var prefix := Fill(a[0..|a|-1]);  // 递归填充前缀
      prefix + [max(a[|a|-1], prefix[|a|-2])]  // 附加新元素
  }

  // -------------------------------------------------------------------------
  // 引理: 填充结果是非递减序列
  // 关键不变式: ∀i∈[1, |a|), Fill(a)[i] ≥ Fill(a)[i-1]
  // -------------------------------------------------------------------------
  lemma FillIsNonDecreasing(a: seq<real>)
    requires |a| > 0
    ensures forall i: int :: 1 <= i < |Fill(a)| ==> Fill(a)[i] >= Fill(a)[i-1]
  {
    if |a| > 1 {
      // 归纳步骤: 分解为前缀 + 末元素
      var prefix := a[0..|a|-1];
      var last := a[|a|-1];
      var filled_prefix := Fill(prefix);

      // 前缀已满足非递减性(归纳假设)
      FillIsNonDecreasing(prefix);

      // 末元素满足: Fill(a)[-1] ≥ filled_prefix[-1]
      assert Fill(a)[|a|-1] == max(last, filled_prefix[|prefix|-1]);
      assert Fill(a)[|a|-1] >= filled_prefix[|prefix|-1];

      // 组合性质: 前缀非递减且末元素不低于前缀末元素
      assert forall i: int :: 1 <= i < |prefix| ==> 
        Fill(a)[i] == filled_prefix[i] >= filled_prefix[i-1] == Fill(a)[i-1];
    }
  }

  // ========================================================================
  // 主定理 1: 幂等性 (Fill(Fill(a)) = Fill(a))
  // 证明策略:
  //   1) 由 FillIsNonDecreasing 知 Fill(a) 已非递减
  //   2) 非递减序列是填充算子的不动点(见定理2)
  // ========================================================================
  theorem Idempotent(a: seq<real>)
    requires |a| > 0
    ensures Fill(Fill(a)) == Fill(a)
  {
    // 步骤1: 证明 Fill(a) 是非递减序列
    FillIsNonDecreasing(a);

    // 步骤2: 应用不动点定理
    FixedPoint(Fill(a));
  }

  // ========================================================================
  // 主定理 2: 不动点性质
  // 若输入序列 a 满足: ∀i≥1, a[i] ≥ a[i-1] (左出口非洼条件)
  // 则 Fill(a) = a
  // ========================================================================
  theorem FixedPoint(a: seq<real>)
    requires |a| > 0
    requires forall i: int :: 1 <= i < |a| ==> a[i] >= a[i-1]  // 非递减条件
    ensures Fill(a) == a
  {
    if |a| == 1 {
      // 单元素序列平凡成立
    } else {
      var prefix := a[0..|a|-1];
      var last := a[|a|-1];

      // 前缀满足非递减条件(由a的性质)
      assert forall i: int :: 1 <= i < |prefix| ==> prefix[i] >= prefix[i-1];

      // 归纳: Fill(prefix) = prefix
      FixedPoint(prefix);

      // 由非递减条件: last ≥ prefix[|prefix|-1] = a[|a|-2]
      assert last >= prefix[|prefix|-1];

      // 因此: max(last, Fill(prefix)[|prefix|-1]) = max(last, prefix[|prefix|-1]) = last
      assert Fill(a) == Fill(prefix) + [last] == prefix + [last] == a;
    }
  }

  // ========================================================================
  // 效用函数: 序列相等引理
  // 证明两个序列在逐元素相等的条件下完全相等
  // ========================================================================
  lemma SequenceEqual(a: seq<real>, b: seq<real>)
    requires |a| == |b|
    requires forall i: int :: 0 <= i < |a| ==> a[i] == b[i]
    ensures a == b
  {
    // 由序列公理直接得出
  }
}

method Main() {
  print "GeoProofBench P-COMP-5 — 1D 洼地填充幂等性及不动点\n";
  print "验证命令: dafny verify PCOMP_5_idempotent.dfy\n";
}
