// ===========================================================================
//  GeoProofBench · P-COMP-1
//  算子 : Wang & Liu 4-connected pit filling (RaiseNbr step)
//  覆盖 : GPB-021 (填洼后无4邻域洼地)
//  环境 : Dafny 4.11
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  本证明聚焦于填洼算法核心步骤 RaiseNbr 的局部性质:
//      当从已处理单元 p 提升4邻域单元 n 时:
//        (1) 提升操作不会降低 n 的高程
//        (2) n 被提升至至少 max(原始高程[n], 已处理单元填充高程[p])
//
//  该性质是 Wang & Liu 算法正确性的基石, 保证:
//      - 填洼后地形满足 4-neighbor 无洼条件
//      - 提升操作是单调的 (仅升高地形)
//      - 与下游分水岭算法的兼容性 (见 GPB-021 复合验证)
//
//  注: 本文件仅形式化局部提升步骤, 完整算法见 P-002-bis
// ===========================================================================

module RaiseNbrStep {

  // ------------------------------
  // 网格系统参数
  // ------------------------------
  const rows: int  // 网格行数 (>0)
  const cols: int  // 网格列数 (>0)
  requires rows > 0 && cols > 0

  // ------------------------------
  // 高程数据 (不可变)
  // ------------------------------
  const h: array2<real>  // 原始高程矩阵
  requires h.Length0 == rows && h.Length1 == cols

  // ------------------------------
  // 算法状态 (可变)
  // ------------------------------
  var fill: array2<real>    // 填充后高程
  var visited: array2<bool> // 单元处理状态
  requires fill.Length0 == rows && fill.Length1 == cols
  requires visited.Length0 == rows && visited.Length1 == cols

  // ------------------------------
  // 全局不变式 (算法执行中保持)
  // ------------------------------
  predicate Valid()
    reads this, fill, visited, h
  {
    // 已访问单元满足: 填充高程 ≥ 原始高程
    (forall r, c :: 
        0 <= r < rows && 0 <= c < cols && visited[r, c] == true ==>
        fill[r, c] >= h[r, c])
  }

  // ==================================================================
  // 核心引理: RaiseNbr 步骤性质
  // ==================================================================
  method RaiseNbr(r0: int, c0: int, dr: int, dc: int)
    requires Valid()                                 // 初始状态满足不变式
    requires 0 <= r0 < rows && 0 <= c0 < cols        // 已处理单元 p 在网格内
    requires visited[r0, c0] == true                 // p 已处理
    requires (dr, dc) in {(-1,0), (1,0), (0,-1), (0,1)} // 4邻域偏移
    requires 0 <= r0+dr < rows && 0 <= c0+dc < cols  // 邻域单元 n 在网格内
    requires visited[r0+dr, c0+dc] == false          // n 未处理
    modifies fill, visited
    ensures Valid()                                  // 操作后不变式保持
    ensures visited[r0+dr, c0+dc] == true            // n 标记为已处理
    // 性质 (1): 提升后高程 ≥ 原始高程
    ensures fill[r0+dr, c0+dc] >= h[r0+dr, c0+dc]
    // 性质 (2): 提升后高程 ≥ max(原始n, 填充p)
    ensures fill[r0+dr, c0+dc] >= max(h[r0+dr, c0+dc], old(fill[r0, c0]))
  {
    // 邻域单元坐标
    var r1 := r0 + dr;
    var c1 := c0 + dc;

    // 提升操作: fill[n] = max(原始高程[n], 已处理单元填充高程[p])
    var new_fill := max(h[r1, c1], fill[r0, c0]);
    visited[r1, c1] := true;
    fill[r1, c1] := new_fill;

    // 性质 (1) 直接满足: new_fill ≥ h[r1,c1] (由max定义)
    // 性质 (2) 直接满足: new_fill = max(h[r1,c1], fill[r0,c0]) 
    //                  ≥ max(h[r1,c1], old(fill[r0,c0])) 

    // 不变式保持: 仅更新单元 n, 且满足 fill[n] ≥ h[n]
    // (其他单元状态未变)
  }
}

method Main() {
  print "GeoProofBench P-COMP-1 — RaiseNbr 步骤性质\n";
  print "验证命令: dafny verify PCOMP_1_RaiseNbr.dfy\n";
}
