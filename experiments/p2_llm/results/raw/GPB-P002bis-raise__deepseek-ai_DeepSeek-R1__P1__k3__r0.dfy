// ===========================================================================
//  GeoProofBench · P-COMP-1 (RaiseNbr step)
//  算子 : Wang & Liu 4-connected flood fill (RaiseNbr step)
//  覆盖 : GPB-021 (pit-fill then unique D8 basin) 的填注步性质
//  环境 : Dafny 4.11
// ===========================================================================
//
//  性质: 在 RaiseNbr 步中, 提升一个4-邻居时:
//        (a) 该邻居的高程不会降低 (即填注后的高程 >= 原始高程)
//        (b) 该邻居被提升至至少为 max(原始邻居高程, 已处理单元的填注高程)
//
//  注: 本文件仅形式化单步性质, 不涉及整个填注算法或流域划分.
// ===========================================================================

module RaiseNbrStep {

  // 定义 max 函数
  function max(a: real, b: real): real {
    if a >= b then a else b
  }

  // 不变式: 所有已访问的单元, 其填注高程不低于原始高程
  predicate Invariant(R: int, C: int, h: array<real>, fill: array<real>, visited: array<bool>)
    requires h != null && fill != null && visited != null
    requires R > 0 && C > 0
    requires h.Length == R*C && fill.Length == R*C && visited.Length == R*C
    reads h, fill, visited
  {
    forall r: int, c: int ::
      0 <= r < R && 0 <= c < C && visited[r*C + c] ==>
        fill[r*C + c] >= h[r*C + c]
  }

  // RaiseNbr 步方法
  method RaiseNbrStep(R: int, C: int, h: array<real>, fill: array<real>, visited: array<bool>, 
                      p_r: int, p_c: int, n_r: int, n_c: int)
    requires h != null && fill != null && visited != null
    requires R > 0 && C > 0
    requires h.Length == R*C && fill.Length == R*C && visited.Length == R*C
    requires Invariant(R, C, h, fill, visited)  // 不变式成立
    requires 0 <= p_r < R && 0 <= p_c < C
    requires visited[p_r*C + p_c]               // p 已处理
    requires (n_r, n_c) in [(p_r-1, p_c), (p_r+1, p_c), (p_r, p_c-1), (p_r, p_c+1)]  // 4-邻接
    requires 0 <= n_r < R && 0 <= n_c < C       // n 在网格内
    requires !visited[n_r*C + n_c]              // n 未访问
    modifies fill, visited
    ensures Invariant(R, C, h, fill, visited)   // 不变式保持
    ensures visited[n_r*C + n_c]                // n 被标记为已访问
    ensures fill[n_r*C + n_c] == max(h[n_r*C + n_c], old(fill[p_r*C + p_c]))  // 核心性质
    ensures forall r: int, c: int :: 
      0 <= r < R && 0 <= c < C && (r != n_r || c != n_c) ==>
        fill[r*C + c] == old(fill[r*C + c]) && 
        visited[r*C + c] == old(visited[r*C + c])  // 其他单元不变
  {
    // 标记邻居为已访问
    visited[n_r*C + n_c] := true;
    
    // 计算新高程: max(原始高程, 已处理单元填注值)
    var new_fill := max(h[n_r*C + n_c], fill[p_r*C + p_c]);
    fill[n_r*C + n_c] := new_fill;

    // 自动证明: 
    //   (a) new_fill >= h[n] (由max定义)
    //   (b) new_fill >= fill[p] (由max定义)
    //   (c) 其他单元不变 (由赋值保证)
  }

  // 主方法 (演示用途)
  method Main() {
    print "GeoProofBench P-COMP-1 (RaiseNbr step) — 填注步的局部性质\n";
    print "由编译期验证: dafny verify ...\n";
  }
}
