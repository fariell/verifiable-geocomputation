// ===========================================================================
//  GeoProofBench · P-COMP-1 (1D specialization)
//  算子 : Wang-Liu pit-filling (left outlet)
//  覆盖 : GPB-021 的一维特例(填洼后非递减)
//  环境 : Dafny 4.11
// ===========================================================================

module WangLiu1D {

  // -------------------------------------------------------------------------
  // 1D Wang-Liu pit-filling with left outlet
  // 
  // 定义:
  //   Fill[0] = orig[0]
  //   Fill[i] = max(orig[i], Fill[i-1])   for i > 0
  //
  // 性质:
  //   (1) 单调性: 所有高程点只升不降 (Fill[i] ≥ orig[i])
  //   (2) 非递减性: 填充后序列单调不减 (Fill[i] ≤ Fill[i+1])
  // -------------------------------------------------------------------------

  // 递归定义填充函数
  function fillAt(orig: array<real>, i: int): real
    requires orig != null
    requires 0 <= i < orig.Length
    decreases i  // 递归终止于i=0
  {
    if i == 0 then orig[0]
    else max(orig[i], fillAt(orig, i-1))
  }

  // 主填充方法
  method Fill(orig: array<real>) returns (fill: array<real>)
    requires orig != null
    ensures fill != null && fill.Length == orig.Length
    ensures forall i :: 0 <= i < orig.Length ==> fill[i] == fillAt(orig, i)
    // 单调性: 所有点高程不降低
    ensures forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]
    // 非递减性: 填充后序列单调不减
    ensures forall i :: 0 <= i < orig.Length - 1 ==> fill[i] <= fill[i+1]
  {
    fill := new real[orig.Length];
    var idx := 0;
    
    while idx < orig.Length
      invariant 0 <= idx <= orig.Length
      invariant forall j :: 0 <= j < idx ==> fill[j] == fillAt(orig, j)
    {
      fill[idx] := fillAt(orig, idx);
      idx := idx + 1;
    }
  }

  // ========================================================================
  // 核心性质证明
  // ========================================================================

  // 性质1: 单调性引理 (所有点只升不降)
  lemma Monotonicity(orig: array<real>, i: int)
    requires orig != null
    requires 0 <= i < orig.Length
    ensures fillAt(orig, i) >= orig[i]
  {
    // 递归基础: i=0时 fillAt(orig,0)=orig[0]
    // 递归步骤: fillAt(orig,i)=max(orig[i],fillAt(orig,i-1)) ≥ orig[i]
  }

  // 性质2: 非递减性引理 (序列单调不减)
  lemma NonDecreasing(orig: array<real>, i: int)
    requires orig != null
    requires 0 <= i < orig.Length - 1
    ensures fillAt(orig, i) <= fillAt(orig, i+1)
  {
    // 由定义: 
    //   fillAt(orig, i+1) = max(orig[i+1], fillAt(orig, i))
    // 因此必然有 fillAt(orig, i) ≤ fillAt(orig, i+1)
  }
}

method Main() {
  print "GeoProofBench P-COMP-1 — 1D Wang-Liu填洼算子验证\n";
  print "性质1: 所有点高程不降低 (单调性)\n";
  print "性质2: 填充后序列单调不减 (非递减性)\n";
  print "验证命令: dafny verify WangLiu1D.dfy\n";
}
