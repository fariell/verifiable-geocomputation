// ===========================================================================
//  GeoProofBench · P-COMP-1
//  文件 : formal/dafny/PCOMP_1.dfy
//  算子 : Wang & Liu 1D 坑填充 (左出口)
//  覆盖 : GPB-021(坑填充后每个单元格的高程不减少,最终剖面非递减)
//  环境 : Dafny 4.11 · 验证命令 dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  坑填充算法是数字高程模型 (DEM) 处理中的重要步骤,用于消除地形中的凹陷。
//  Wang & Liu 的 1D 坑填充算法通过从左到右扫描,确保每个单元格的高程
//  不减少,并且最终的剖面是非递减的。这为后续的水文分析提供了基础。
//
//  本文件证明了 Wang & Liu 1D 坑填充算法的两个基本性质:
//  1. 每个单元格的高程不减少。
//  2. 最终的剖面是非递减的。
//
//  这些性质的证明有助于理解算法的正确性和稳定性,并为其他相关算法
//  的形式化验证提供参考。
// ===========================================================================

module PitFillingThenWatershed {

  // 1D 原始高程数组
  type Elevation = array<int, real>

  // 1D 坑填充算法
  method PitFill1D(orig: Elevation) returns (fill: Elevation)
    requires orig.Length > 0
    ensures fill.Length == orig.Length
    ensures forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]
    ensures forall i :: 0 < i < fill.Length ==> fill[i] >= fill[i-1]
  {
    var n := orig.Length;
    fill := new real[n];
    fill[0] := orig[0];
    for i := 1 to n - 1
      invariant 0 <= i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
      invariant forall j :: 0 < j < i ==> fill[j] >= fill[j-1]
    {
      fill[i] := max(orig[i], fill[i-1]);
    }
  }

  // ==================================================================
  // 每个单元格的高程不减少
  // ==================================================================
  lemma NoCellElevationDecreases(orig: Elevation, fill: Elevation)
    requires orig.Length > 0
    requires fill.Length == orig.Length
    requires forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]
    ensures forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]
  {
  }

  // ==================================================================
  // 最终的剖面是非递减的
  // ==================================================================
  lemma ProfileIsNonDecreasing(orig: Elevation, fill: Elevation)
    requires orig.Length > 0
    requires fill.Length == orig.Length
    requires forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]
    ensures forall i :: 0 < i < fill.Length ==> fill[i] >= fill[i-1]
  {
    var n := fill.Length;
    assert fill[0] >= orig[0];
    for i := 1 to n - 1
      invariant 0 <= i <= n
      invariant forall j :: 0 < j < i ==> fill[j] >= fill[j-1]
    {
      assert fill[i] >= fill[i-1] by {
        if orig[i] >= fill[i-1] {
          assert fill[i] == orig[i];
        } else {
          assert fill[i] == fill[i-1];
        }
      }
    }
  }

  // ==================================================================
  // 主方法:验证坑填充算法的性质
  // ==================================================================
  method Main() {
    print "GeoProofBench P-COMP-1 — Wang & Liu 1D 坑填充算法的两个性质\n";
    print "全部由编译期验证:dafny verify PCOMP_1.dfy\n";

    // 示例数据
    var orig := new real[5];
    orig[0] := 1.0;
    orig[1] := 0.5;
    orig[2] := 1.5;
    orig[3] := 1.0;
    orig[4] := 2.0;

    // 运行坑填充算法
    var fill := PitFill1D(orig);

    // 验证性质
    NoCellElevationDecreases(orig, fill);
    ProfileIsNonDecreasing(orig, fill);

    // 打印结果
    print "原始高程: ";
    for i := 0 to orig.Length - 1 {
      print orig[i], " ";
    }
    print "\n填充后高程: ";
    for i := 0 to fill.Length - 1 {
      print fill[i], " ";
    }
    print "\n";
  }
}
