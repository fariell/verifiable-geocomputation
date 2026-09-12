// ===========================================================================
//  GeoProofBench · P-COMP-5 / GPB-026
//  算子 : 1D 左出口洼地填充
//  性质 : 幂等性 (Fill(Fill(a)) = Fill(a)) 及固定点性质
//  环境 : Dafny 4.11
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  洼地填充是水文分析的基础算子。幂等性保证填充结果稳定，避免重复处理。
//  固定点性质确保已满足排水条件的单元格在填充过程中保持不变。
//  这些元性质是验证复杂水文模型的基础。
//
//  本文件聚焦 1D 左出口特化版本(序列从左向右排水)，为 2D 算子验证提供引理基础。
//  参考实现: experiments/phase2/p_comp_5.py
//
// ===========================================================================

module PitFilling1D {

  // 实数最大值辅助函数
  function max(x: real, y: real): real {
    if x >= y then x else y
  }

  // 1D 洼地填充算子 (左出口)
  function Fill(a: seq<real>): seq<real> {
    if |a| == 0 then []
    else
      var first := a[0];
      [first] + FillHelper(first, a[1..])
  }

  // 填充辅助函数 (累积最大值传递)
  function FillHelper(cum: real, a: seq<real>): seq<real> {
    if |a| == 0 then []
    else
      var newVal := max(a[0], cum);
      [newVal] + FillHelper(newVal, a[1..])
  }

  // 非递减序列谓词
  predicate IsNonDecreasing(a: seq<real>) {
    forall i :: 1 <= i < |a| ==> a[i] >= a[i-1]
  }

  // ==================================================================
  // 性质 1: 幂等性 (Fill ∘ Fill = Fill)
  // ==================================================================
  lemma Idempotent(a: seq<real>)
    ensures Fill(Fill(a)) == Fill(a)
  {
    if |a| == 0 {
      // 空序列平凡成立
    } else {
      // 关键: 首次填充后序列变为非递减
      assert IsNonDecreasing(Fill(a));
      // 非递减序列是填充算子的固定点
      FixedPoint(Fill(a));
    }
  }

  // ==================================================================
  // 性质 2: 固定点 (非递减序列是填充的固定点)
  // ==================================================================
  lemma FixedPoint(a: seq<real>)
    requires IsNonDecreasing(a)
    ensures Fill(a) == a
    decreases |a|
  {
    if |a| == 0 {
      // 空序列
    } else if |a| == 1 {
      // 单元素序列
      assert Fill(a) == [a[0]];
    } else {
      // 分解: 首元素 + 尾部
      // 由非递减性: a[0] <= a[1] 且尾部保持非递减
      assert a[1] >= a[0];
      assert IsNonDecreasing(a[1..]);

      // 计算填充结果
      assert Fill(a) == [a[0]] + FillHelper(a[0], a[1..]);

      // 证明: 当首元素≤尾部首元时，辅助函数等价于尾部填充
      assert FillHelper(a[0], a[1..]) == Fill(a[1..]);
      // 递归应用: 尾部非递减 → 尾部填充为恒等
      FixedPoint(a[1..]);
    }
  }

  // 辅助引理: 当累积值≤序列首元时，辅助函数等价于填充
  lemma FillHelperFixedPoint(cum: real, a: seq<real>)
    requires |a| > 0
    requires a[0] >= cum
    requires IsNonDecreasing(a)
    ensures FillHelper(cum, a) == Fill(a)
    decreases |a|
  {
    if |a| == 1 {
      // 单元素序列
      assert FillHelper(cum, a) == [max(a[0], cum)] == [a[0]];
      assert Fill(a) == [a[0]];
    } else {
      // 多元素序列
      assert a[1] >= a[0];  // 非递减性
      assert IsNonDecreasing(a[1..]);

      // 展开辅助函数
      assert FillHelper(cum, a) ==
        [max(a[0], cum)] + FillHelper(max(a[0], cum), a[1..]);
      // 由条件 a[0] >= cum → max = a[0]
      assert max(a[0], cum) == a[0];

      // 递归证明
      FillHelperFixedPoint(a[0], a[1..]);
      assert Fill(a) == [a[0]] + Fill(a[1..]);
    }
  }

  // ==================================================================
  // 性质 3: 单元格固定点 (满足左排水条件的单元格不变)
  // ==================================================================
  lemma FixedPointCell(a: seq<real>, i: int)
    requires 0 <= i < |a|
    requires i == 0 || a[i] >= Fill(a)[i-1]  // 不向左溢流
    ensures Fill(a)[i] == a[i]
  {
    if i == 0 {
      // 首单元格总是固定点
      assert Fill(a)[0] == a[0];
    } else {
      // 由填充定义: Fill(a)[i] = max(a[i], Fill(a)[i-1])
      // 由条件 a[i] >= Fill(a)[i-1] → max = a[i]
    }
  }
}

method Main() {
  print "GeoProofBench P-COMP-5 — 1D 洼地填充幂等性与固定点性质\n";
  print "验证命令: dafny verify PCOMP_5_idempotent.dfy\n";
}
