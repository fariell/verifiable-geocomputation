// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  算子 : 流域唯一性(确定性 D8 流路)
//  覆盖 : GPB-015 (流域唯一性: 若从同一起点经任意两有限步长到达出口,则两出口相同)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P006_watershed.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  流域分析中,一个基本问题是:从每个格网单元出发的流路是否必然终止于唯一出口?
//  本文件证明:在确定性 D8 流模型下,若流路在有限步内终止(即到达一个固定点),
//  则终止点唯一(与步数无关)。这为后续的填洼算法(P-002)和曲率分析(P-003)提供
//  了基础不变式。
//
//  注:本文件不处理非终止情形(如 GPB-015 的环状平地反例)。非终止情形由
//      P-006b 单独处理。
//
// ===========================================================================

module Watershed {
  // 格网维度(抽象常量)
  const rows: int, cols: int
  assume rows > 0 && cols > 0  // 非空格网

  // 格网单元类型(行号, 列号)
  type Cell = (int, int)

  // 有效单元谓词
  predicate valid(c: Cell) {
    0 <= c.0 < rows && 0 <= c.1 < cols
  }

  // 抽象后继函数(D8 流模型)
  // - 要求:输入必须是有效单元
  // - 保证:输出为有效单元或自身(出口)
  function succ(c: Cell): Cell
    requires valid(c)
    ensures valid(result) || result == c

  // 出口单元谓词(固定点)
  predicate isOutlet(c: Cell) {
    valid(c) && succ(c) == c
  }

  // 有界迭代函数(步进 n 次)
  // - 若中途遇到出口则停止
  function stepN(s: Cell, n: nat): Cell
    requires valid(s)
    ensures valid(result)  // 结果始终有效
    decreases n
  {
    if n == 0 then s
    else
      let prev := stepN(s, n-1);
      if isOutlet(prev) then prev else succ(prev)
  }

  // ========================================================================
  // 核心引理:出口稳定性
  // ------------------------------------------------------------------------
  // 一旦在 k 步到达出口,则任意更多步数(n ≥ k)将停留在同一出口
  // ========================================================================
  lemma StepNStable(s: Cell, k: nat, n: nat)
    requires valid(s)
    requires isOutlet(stepN(s, k))
    requires n >= k
    ensures stepN(s, n) == stepN(s, k)
    decreases n - k
  {
    if n == k {
      // 基础情况:步数相等
    } else {
      // 归纳步骤:先证 n-1 步稳定
      StepNStable(s, k, n-1);
      // 由定义知第 n 步将保持出口状态
    }
  }

  // ========================================================================
  // 主定理:流域出口唯一性
  // ------------------------------------------------------------------------
  // 若从同一起点 s 出发,经不同步数(n 和 m)均到达出口,
  // 则两出口必相同
  // ========================================================================
  theorem WatershedUniqueness(s: Cell, n: nat, m: nat)
    requires valid(s)
    requires isOutlet(stepN(s, n))
    requires isOutlet(stepN(s, m))
    ensures stepN(s, n) == stepN(s, m)
  {
    // 根据 n 和 m 的相对大小分情况证明
    if n <= m {
      StepNStable(s, n, m);  // n ≤ m 时 m 步稳定于 n 步出口
    } else {
      StepNStable(s, m, n);  // m < n 时 n 步稳定于 m 步出口
    }
  }
}

method Main() {
  print "GeoProofBench P-006 — 确定性 D8 流域出口唯一性\n";
  print "定理已验证: dafny verify P006_watershed.dfy\n";
}
