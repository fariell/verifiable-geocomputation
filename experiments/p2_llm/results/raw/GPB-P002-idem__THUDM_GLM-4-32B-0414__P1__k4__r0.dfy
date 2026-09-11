module PitFillingIdempotent {
  // ------------------------------------------------------------------
  // 1D Fill 算子定义 (左出口约定)
  // ------------------------------------------------------------------
  function Fill1D(a: array<int>): array<int>
  {
    var n := a.Length;
    var out := new int[n];
    out[0] := a[0];
    var i := 1;
    while i < n
      invariant i <= n;
      invariant forall j :: 0 <= j < i ==> out[j] == a[j] || (j > 0 && out[j] == out[j-1]);
      invariant forall j :: 0 <= j < i ==> out[j] >= a[j];
    {
      out[i] := max(a[i], out[i-1]);
      i := i + 1;
    }
    return out;
  }

  // ------------------------------------------------------------------
  // 坑填充的不动点性质
  // ------------------------------------------------------------------
  lemma IdempotentFill(a: array<int>)
    requires a != null;
    ensures Fill1D(Fill1D(a)) == Fill1D(a);
  {
    var n := a.Length;
    var filled := Fill1D(a);
    var filled_filled := Fill1D(filled);
    
    // 基础情况:第一个元素不变
    assert filled_filled[0] == filled[0] == a[0];
    
    // 归纳证明:每个后续元素要么等于输入,要么等于前一个填充值
    var i := 1;
    while i < n
      invariant 1 <= i <= n;
      invariant forall j :: 0 <= j < i ==> filled_filled[j] == filled[j];
    {
      // 填充后的数组已经满足单调不减
      assert filled[i] >= filled[i-1];
      
      // 第二次填充不会改变已经填充的值
      assert filled_filled[i] == max(filled[i], filled_filled[i-1]);
      assert filled_filled[i-1] == filled[i-1];
      assert filled[i] >= filled[i-1];
      
      // 因此第二次填充等于第一次填充
      assert filled_filled[i] == filled[i];
      
      i := i + 1;
    }
  }

  // ------------------------------------------------------------------
  // 不溢出左方的格点是不动点
  // ------------------------------------------------------------------
  lemma FixedPointNoSpill(a: array<int>, i: int)
    requires 0 < i < a.Length;
    requires a[i] >= a[i-1];
    ensures Fill1D(a)[i] == a[i];
  {
    var filled := Fill1D(a);
    // 填充过程保持前缀最大值性质
    assert filled[i] == max(a[i], filled[i-1]);
    // 由于a[i] >= a[i-1],且填充过程单调不减
    assert filled[i-1] == a[i-1];
    assert a[i] >= a[i-1];
    // 因此max(a[i], filled[i-1]) == a[i]
    assert filled[i] == a[i];
  }

  method Main()
  {
    // 测试用例1:平面
    var plane := new int[4];
    plane[0] := 5; plane[1] := 5; plane[2] := 5; plane[3] := 5;
    var filled := Fill1D(plane);
    var filled_filled := Fill1D(filled);
    print "Plane test: ", filled == filled_filled;
    
    // 测试用例2:坑
    var pit := new int[3];
    pit[0] := 3; pit[1] := 1; pit[2] := 4;
    filled := Fill1D(pit);
    filled_filled := Fill1D(filled);
    print "Pit test: ", filled == filled_filled;
    
    // 测试用例3:斜坡
    var slope := new int[4];
    slope[0] := 0; slope[1] := 1; slope[2] := 2; slope[3] := 3;
    filled := Fill1D(slope);
    filled_filled := Fill1D(filled);
    print "Slope test: ", filled == filled_filled;
    
    // 测试用例4:级联
    var cascade := new int[3];
    cascade[0] := 3; cascade[1] := 1; cascade[2] := 0;
    filled := Fill1D(cascade);
    filled_filled := Fill1D(filled);
    print "Cascade test: ", filled == filled_filled;
  }
}
