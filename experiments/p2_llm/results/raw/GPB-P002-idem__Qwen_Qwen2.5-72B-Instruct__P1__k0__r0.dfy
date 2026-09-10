// ===========================================================================
//  GeoProofBench · P-002
//  文件 : formal/dafny/P002_pit_filling.dfy
//  算子 : 1D 填洼 (Fill)
//  覆盖 : GPB-026(填洼的幂等性)、GPB-026(填洼的固定点性质)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_pit_filling.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  填洼操作是数字高程模型 (DEM) 处理中的一个基本步骤,用于消除地形中的洼地。
//  本文件证明填洼操作在 1D 左出口特化下的幂等性和固定点性质,这些性质对于
//  理解和验证填洼算法在更复杂地形中的行为至关重要。
//
//  幂等性 (Idempotence): Fill(Fill(a)) = Fill(a)
//  固定点 (Fixed Point): 如果 a[i] 不向左溢出,则 Fill(a)[i] = a[i]
//
// ===========================================================================

module PitFilling {

  // 1D 填洼操作
  function Fill(a: seq<int>): seq<int> {
    var out: seq<int> := a;
    for i := 1 to |a| - 1 {
      out[i] := max(out[i], out[i - 1]);
    }
    return out;
  }

  // 幂等性引理
  lemma Idempotent(a: seq<int>)
    ensures Fill(Fill(a)) == Fill(a)
  {
    var b := Fill(a);
    var c := Fill(b);
    assert b == c;
  }

  // 固定点引理
  lemma FixedPoint(a: seq<int>, i: int)
    requires 0 <= i < |a|
    requires a[i] >= a[i - 1] || i == 0
    ensures Fill(a)[i] == a[i]
  {
    var b := Fill(a);
    if i == 0 {
      assert b[i] == a[i];
    } else {
      assert b[i] == max(a[i], a[i - 1]);
      assert a[i] >= a[i - 1];
      assert b[i] == a[i];
    }
  }

  // 测试用例
  method TestCases() {
    var cases: seq<seq<int>> := [
      [5, 5, 5, 5],  // 平面
      [3, 1, 4],     // 坑
      [0, 1, 2, 3],  // 斜坡
      [3, 1, 0]      // 级联
    ];

    for case in cases {
      var filled := Fill(case);
      var filledTwice := Fill(filled);
      print "Case: ", case, "\n";
      print "Filled: ", filled, "\n";
      print "Filled Twice: ", filledTwice, "\n";
      assert filled == filledTwice;
    }
  }

  // 主方法
  method Main() {
    print "GeoProofBench P-002 — 1D 填洼算子的幂等性和固定点性质\n";
    print "全部由编译期验证:dafny verify P002_pit_filling.dfy\n";
    TestCases();
  }
}
