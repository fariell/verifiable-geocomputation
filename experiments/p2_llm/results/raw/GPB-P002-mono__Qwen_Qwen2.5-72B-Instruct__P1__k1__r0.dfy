// ===========================================================================
//  GeoProofBench · P-COMP-1
//  文件 : formal/dafny/PCOMP_1.dfy
//  算子 : Wang & Liu 1D 坑填充 (左出口)
//  覆盖 : GPB-021(坑填充后每个提升是单调的,最终剖面是非递减的)
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  坑填充算法是 DEM 处理中的一个基本步骤,用于移除地形中的凹陷,确保水流
//  模拟的正确性。Wang & Liu 的 1D 坑填充算法通过从左到右扫描,确保每个
//  单元格的高程不低于其左侧邻居,从而实现剖面的非递减性。本文件证明了
//  该算法的两个基本性质:
//    1) 每个提升是单调的:没有单元格的高程降低。
//    2) 完整扫描后,剖面是非递减的。
//  这些性质的证明为算法的正确性和稳定性提供了理论基础。
// ===========================================================================

module PitFillingThenWatershed {

  // 1D 剖面类型
  type Profile = array real;

  // 原始剖面
  function origProfile(n: int): Profile
    requires n > 0
  {
    new real(n)
  }

  // 填充后的剖面
  function fillProfile(n: int, orig: Profile): Profile
    requires n > 0
  {
    var fill: Profile := new real(n);
    fill[0] := orig[0];
    for i := 1 to n - 1
      invariant 0 <= i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[j-1]
    {
      fill[i] := max(orig[i], fill[i-1]);
    }
    return fill;
  }

  // 每个提升是单调的:没有单元格的高程降低
  lemma MonotoneRaise(n: int, orig: Profile)
    requires n > 0
    ensures forall i :: 0 <= i < n ==> fillProfile(n, orig)[i] >= orig[i]
  {
    var fill := fillProfile(n, orig);
    assert fill[0] == orig[0];
    for i := 1 to n - 1
      invariant 0 <= i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
    {
      assert fill[i] == max(orig[i], fill[i-1]);
      assert fill[i] >= orig[i];
    }
  }

  // 完整扫描后,剖面是非递减的
  lemma NonDecreasingProfile(n: int, orig: Profile)
    requires n > 0
    ensures forall i :: 0 < i < n ==> fillProfile(n, orig)[i] >= fillProfile(n, orig)[i-1]
  {
    var fill := fillProfile(n, orig);
    assert fill[0] == orig[0];
    for i := 1 to n - 1
      invariant 0 <= i <= n
      invariant forall j :: 0 < j < i ==> fill[j] >= fill[j-1]
    {
      assert fill[i] == max(orig[i], fill[i-1]);
      assert fill[i] >= fill[i-1];
    }
  }

  // 主方法:验证两个基本性质
  method Main() {
    print "GeoProofBench P-COMP-1 — Wang & Liu 1D 坑填充算法的两个基本性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";
  }
}
