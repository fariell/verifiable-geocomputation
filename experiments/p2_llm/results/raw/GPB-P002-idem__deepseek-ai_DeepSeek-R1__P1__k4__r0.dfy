// ===========================================================================
//  GeoProofBench · P-COMP-5
//  算子 : 1D 左出口填洼
//  覆盖 : GPB-026 (填洼幂等性/非溢流固定点)
//  环境 : Dafny 4.11
// ===========================================================================
module PitFilling1D {

  // 1D 填洼算子: 计算前缀最大值
  function Fill(a: seq<real>): (b: seq<real>)
    requires |a| > 0
    ensures |b| == |a|
  {
    if |a| == 1 then [a[0]]
    else
      var prefix := Fill(a[0..|a|-1]);
      var last := max(a[|a|-1], prefix[|prefix|-1]);
      prefix + [last]
  }

  // 非溢流谓词: 每个单元不低于前驱单元
  predicate IsNonSpilling(a: seq<real>)
    requires |a| > 0
  {
    forall i :: 1 <= i < |a| ==> a[i] >= a[i-1]
  }

  // 幂等性定理: Fill(Fill(a)) = Fill(a)
  lemma Idempotent(a: seq<real>)
    requires |a| > 0
    ensures Fill(Fill(a)) == Fill(a)
  {
    // 关键步骤1: 填洼结果自动满足非溢流条件
    assert IsNonSpilling(Fill(a)) by {
      forall j | 1 <= j < |Fill(a)| 
        ensures Fill(a)[j] >= Fill(a)[j-1] 
      {
        calc {
          Fill(a)[j];
        == // 展开Fill定义
          max(a[j], Fill(a[0..j])[j-1]);
        >= // max性质
          Fill(a[0..j])[j-1];
        == { assert Fill(a[0..j])[j-1] == Fill(a)[j-1]; } 
          Fill(a)[j-1];
        }
      }
    }
    // 关键步骤2: 非溢流序列是填洼算子的固定点
    FixedPoint(Fill(a));
  }

  // 固定点定理: 非溢流序列在填洼下不变
  lemma FixedPoint(a: seq<real>)
    requires |a| > 0
    requires IsNonSpilling(a)
    ensures Fill(a) == a
  {
    // 归纳证明: 每个位置满足 Fill(a)[i] == a[i]
    forall i | 0 <= i < |a|
      ensures Fill(a)[i] == a[i]
    {
      FixedPointIndex(a, i);
    }
  }

  // 辅助引理: 单点固定性证明
  lemma FixedPointIndex(a: seq<real>, i: int)
    requires |a| > 0
    requires IsNonSpilling(a)
    requires 0 <= i < |a|
    ensures Fill(a)[i] == a[i]
    decreases i
  {
    if i > 0 {
      // 归纳步骤: 先证前驱位置成立
      FixedPointIndex(a, i-1);
      // 非溢流条件保证当前值不小于前值
      assert a[i] >= a[i-1];
      // 填洼计算等价于取max(当前值, 前驱填洼值)
      assert Fill(a)[i] == max(a[i], Fill(a)[i-1]);
      // 代入归纳假设和前值关系
      assert max(a[i], Fill(a)[i-1]) == max(a[i], a[i-1]) == a[i];
    }
  }

  method Main() {
    print "P-COMP-5 / GPB-026: 1D填洼幂等性与固定点性质\n";
    print "定理: ∀a≠∅ • Fill(Fill(a)) = Fill(a)\n";
    print "定理: ∀a∈NonSpilling • Fill(a) = a\n";
  }
}
