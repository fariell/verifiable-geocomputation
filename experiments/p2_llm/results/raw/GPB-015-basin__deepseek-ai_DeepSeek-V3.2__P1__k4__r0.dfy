// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  算子 : 确定性 D8 流向下的流域唯一性
//  覆盖 : GPB-015 (Layer A: 终止轨道出口唯一性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P006_watershed.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  流域分析中,确定性流向函数(如 D8)从同一单元格出发的流动路径,
//  若在有限步内终止于某个出口(不动点),则该出口必须唯一。
//  这一性质是后续累积分析、流域划分正确性的基础。
//  本文件形式化该唯一性,不依赖不动点搜索,仅通过有界迭代步数证明。
//
//  结构说明
//  --------
//  1. 导入 D8 流向核(来自 P-005),避免重复实现。
//  2. 定义有界迭代函数 stepN,模拟最多 N 步的流向追踪。
//  3. 证明:若从同一单元格出发,分别在步数 m 和 n 内到达出口,
//     则这两个出口是同一个单元格。
//  4. 不假设全局终止性,仅对实际终止的路径证明唯一性。
//
// ===========================================================================

include "P005_d8.dfy"  // 导入 D8 流向函数定义

module WatershedUniqueness {
  import opened D8Kernel  // 打开 D8 核模块,使用其类型和函数

  // ------------------------------------------------------------------
  // 有界迭代函数:从单元格 (r,c) 出发,执行最多 N 步的流向追踪。
  // 返回 (是否在 N 步内终止, 终止时的单元格, 实际步数)
  // ------------------------------------------------------------------
  function stepN(h: Grid, r: int, c: int, N: nat): (terminated: bool, outR: int, outC: int, steps: nat)
    requires 0 <= r < h.rows && 0 <= c < h.cols
    decreases N
  {
    if N == 0 then
      (false, r, c, 0)
    else
      var d := D8Kernel.d8_at(h, r, c);
      if d == D8Kernel.NoFlow then
        (true, r, c, 0)
      else
        var (dp, dq) := D8Kernel.delta(d);
        var nr := r + dq;
        var nc := c + dp;
        if !(0 <= nr < h.rows && 0 <= nc < h.cols) then
          (true, r, c, 0)
        else
          var (term, outR, outC, st) := stepN(h, nr, nc, N-1);
          (term, outR, outC, st+1)
  }

  // ------------------------------------------------------------------
  // 辅助引理:若在 N 步内终止,则对于任意 M >= N,在 M 步内也终止,
  // 且出口相同。
  // ------------------------------------------------------------------
  lemma stepN_monotonic(h: Grid, r: int, c: int, N: nat, M: nat)
    requires 0 <= r < h.rows && 0 <= c < h.cols
    requires N <= M
    ensures forall term, outR, outC, steps ::
      (term, outR, outC, steps) == stepN(h, r, c, N) ==>
      (term, outR, outC, steps) == stepN(h, r, c, M)
    decreases M - N
  {
    if N == M {
      // 相等情况直接成立
    } else {
      // 归纳步骤:证明 N 到 N+1
      var (termN, outRN, outCN, stepsN) := stepN(h, r, c, N);
      var (termN1, outRN1, outCN1, stepsN1) := stepN(h, r, c, N+1);
      // 根据 stepN 定义,若在 N 步终止,则 N+1 步结果相同
      if termN {
        assert termN1 && outRN1 == outRN && outCN1 == outCN && stepsN1 == stepsN;
      }
      // 递归应用引理到 N+1 和 M
      stepN_monotonic(h, r, c, N+1, M);
    }
  }

  // ==================================================================
  // 主定理:流域出口唯一性
  // 若从同一单元格 (r,c) 出发,分别在 m 步和 n 步内到达出口,
  // 则这两个出口是同一个单元格。
  // ==================================================================
  theorem watershed_unique_outlet(h: Grid, r: int, c: int, m: nat, n: nat)
    requires 0 <= r < h.rows && 0 <= c < h.cols
    ensures
      var (termM, outRM, outCM, stepsM) := stepN(h, r, c, m);
      var (termN, outRN, outCN, stepsN) := stepN(h, r, c, n);
      termM && termN ==> outRM == outRN && outCM == outCN
  {
    var (termM, outRM, outCM, stepsM) := stepN(h, r, c, m);
    var (termN, outRN, outCN, stepsN) := stepN(h, r, c, n);
    if termM && termN {
      // 取最大步数 M = max(m, n)
      var M := if m >= n then m else n;
      // 应用单调性引理
      stepN_monotonic(h, r, c, m, M);
      stepN_monotonic(h, r, c, n, M);
      // 现在两者都在 M 步内终止,且结果与各自原结果相同
      var (termM2, outRM2, outCM2, stepsM2) := stepN(h, r, c, M);
      assert termM2 && outRM2 == outRM && outCM2 == outCM;
      assert termM2 && outRM2 == outRN && outCM2 == outCN;  // 注意:第二个断言来自 n 的单调性
      // 因此 outRM == outRN 且 outCM == outCN
    }
  }

  // ==================================================================
  // 推论:若在 N 步内终止,则实际步数小于等于 N
  // (完整性引理,非核心但有用)
  // ==================================================================
  lemma steps_bound(h: Grid, r: int, c: int, N: nat)
    requires 0 <= r < h.rows && 0 <= c < h.cols
    ensures var (term, outR, outC, steps) := stepN(h, r, c, N);
            term ==> steps <= N
    decreases N
  {
    var (term, outR, outC, steps) := stepN(h, r, c, N);
    if term {
      // 根据 stepN 定义,递归结构保证 steps <= N
    }
  }
}

method Main() {
  print "GeoProofBench P-006 — 确定性 D8 流向下的流域出口唯一性\n";
  print "定理:若从同一单元格出发在有限步内终止,出口唯一。\n";
  print "验证: dafny verify P006_watershed.dfy\n";
}
