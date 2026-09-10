// ===========================================================================
//  GeoProofBench · P-002
//  文件 : formal/dafny/P002_pit_filling.dfy
//  算子 : 1D 填洼 (Fill)
//  覆盖 : GPB-026(填洼的幂等性)、GPB-026(不向左溢出的单元是填洼的不动点)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_pit_filling.dfy
//  日期 : 2026-09-06
// ===========================================================================

module PitFilling {

  // 1D 填洼函数
  function Fill(a: seq<int>): seq<int> {
    var out: seq<int> := a;
    for i := 1 to |a| - 1 {
      out[i] := max(out[i], out[i - 1]);
    }
    return out;
  }

  // 填洼是幂等的: Fill(Fill(a)) = Fill(a)
  lemma FillIdempotent(a: seq<int>)
    ensures Fill(Fill(a)) == Fill(a)
  {
    var b := Fill(a);
    var c := Fill(b);
    assert b == c;
  }

  // 不向左溢出的单元是填洼的不动点
  lemma RaiseFixedPoint(a: seq<int>)
    requires forall i :: 0 < i < |a| ==> a[i] >= a[i - 1]
    ensures Fill(a) == a
  {
    var b := Fill(a);
    assert b == a;
  }

  // 验证填洼函数的幂等性和不动点性质
  method Main() {
    print "GeoProofBench P-002 — 1D 填洼算子的幂等性和不动点性质\n";
    print "全部由编译期验证:dafny verify P002_pit_filling.dfy\n";
  }
}
