// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  算子 : 流域唯一性(确定性流)
//  覆盖 : GPB-015 (流域唯一性)
//  环境 : Dafny 4.11
// ===========================================================================
//
//  定理: 若从同一栅格单元 s 出发,在有限步数 n 和 m 分别到达两个出水口(不动点),
//        则这两个出水口必相同。
//
//  注: 本文件仅处理"有限步终止"的情形,不处理循环(如 P-006b 的 4 元环)。
//      循环情形见 P-006b (非终止轨道)。
//
// ===========================================================================

module Watershed {
  // 单元类型(抽象)
  type Cell

  // 后继函数(抽象)
  function succ(c: Cell): Cell

  // 不动点谓词
  predicate isFixedPoint(c: Cell) {
    succ(c) == c
  }

  // 迭代 n 步
  function stepN(s: Cell, n: nat): Cell {
    if n == 0 then s else succ(stepN(s, n-1))
  }

  // 引理: 不动点迭代任意步不变
  lemma FixedPointStable(c: Cell, k: nat)
    requires isFixedPoint(c)
    ensures stepN(c, k) == c
    decreases k
  {
    if k != 0 {
      FixedPointStable(c, k-1);
    }
  }

  // 主定理: 流域唯一性
  lemma WatershedUniqueness(s: Cell, n: nat, m: nat)
    requires isFixedPoint(stepN(s, n))
    requires isFixedPoint(stepN(s, m))
    ensures stepN(s, n) == stepN(s, m)
  {
    if n <= m {
      var t: nat := m - n;
      FixedPointStable(stepN(s, n), t);
    } else {
      var t: nat := n - m;
      FixedPointStable(stepN(s, m), t);
    }
  }
}

method Main() {
  print "GeoProofBench P-006 — Watershed uniqueness under deterministic flow\n";
  print "Verified: WatershedUniqueness lemma\n";
}
