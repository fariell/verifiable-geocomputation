// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  命题 : GPB-015 流域唯一性(确定性流向 ⇒ 出口至多一个)
//  环境 : Dafny 4.11 · dafny verify P006_watershed.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  层 A:若轨道在 N 步内到达出口,则出口唯一。stepN 对 n 归纳,不递归扫描。
//  层 B:flat 4-环的后继永无不动点(P-006b)。严格下降终止性见
//  P006_terminate_under_strict.dfy(第 6 条)。
//  D8 核 include P-005,不复制 8 路比较。
// ===========================================================================

include "P005_d8.dfy"

module Watershed {

  import D8 = D8Flow

  // ==================================================================
  // 有界展开:succ 的 n 步迭代。对 n 归纳,不让 solver 找不动点。
  // ==================================================================
  function stepN(succ: nat -> nat, c: nat, n: nat): nat
    decreases n
  {
    if n == 0 then c else succ(stepN(succ, c, n - 1))
  }

  lemma OrbitDeterministic(succ: nat -> nat, c: nat, n: nat)
    ensures stepN(succ, c, n) == stepN(succ, c, n)
  {
  }

  lemma StepNAdd(succ: nat -> nat, c: nat, n: nat, k: nat)
    ensures stepN(succ, c, n + k) == stepN(succ, stepN(succ, c, n), k)
    decreases k
  {
    if k == 0 {
    } else {
      StepNAdd(succ, c, n, k - 1);
    }
  }

  lemma StuckIter(succ: nat -> nat, o: nat, k: nat)
    requires succ(o) == o
    ensures stepN(succ, o, k) == o
    decreases k
  {
    if k == 0 {
    } else {
      StuckIter(succ, o, k - 1);
    }
  }

  // 1. D8 输出唯一(函数,复用 P-005 核)
  lemma FlowSuccessorUnique(win: D8.Win, f1: D8.Flow, f2: D8.Flow)
    requires f1 == D8.D8(win) && f2 == D8.D8(win)
    ensures f1 == f2
  {
  }

  lemma ChainMatchesD8West()
    ensures D8.D8(D8.PlaneWin(1.0, 0.0, 0.0, 1.0)) == D8.To(D8.DirW)
  {
    D8.PlaneWest();
  }

  // 西向三格链:0 → 1 → 2,2 为出口(不动点)
  function ChainSucc(c: nat): nat
  {
    if c == 0 then 1 else if c == 1 then 2 else 2
  }

  predicate ChainOutlet(c: nat)
  {
    c >= 2
  }

  lemma ChainOutletStuck(c: nat)
    requires ChainOutlet(c)
    ensures ChainSucc(c) == 2
  {
  }

  // 3. 若 2 步内到出口,则 basin 有定义
  lemma TerminatesImpliesBasin(c: nat)
    requires c <= 2
    ensures ChainOutlet(stepN(ChainSucc, c, 2))
  {
  }

  // 4. 主定理(层 A):同一起点的两个出口必相等
  lemma BasinUnique(succ: nat -> nat, c: nat, n1: nat, n2: nat, o1: nat, o2: nat)
    requires stepN(succ, c, n1) == o1 && succ(o1) == o1
    requires stepN(succ, c, n2) == o2 && succ(o2) == o2
    ensures o1 == o2
  {
    if n1 <= n2 {
      var k := n2 - n1;
      StepNAdd(succ, c, n1, k);
      StuckIter(succ, o1, k);
    } else {
      var k := n1 - n2;
      StepNAdd(succ, c, n2, k);
      StuckIter(succ, o2, k);
    }
  }

  lemma ChainBasinUnique(c: nat, n1: nat, n2: nat, o1: nat, o2: nat)
    requires c <= 2
    requires stepN(ChainSucc, c, n1) == o1 && o1 == 2
    requires stepN(ChainSucc, c, n2) == o2 && o2 == 2
    ensures o1 == o2
  {
    BasinUnique(ChainSucc, c, n1, n2, o1, o2);
  }

  // ==================================================================
  // 5. P-006b:flat 4-环。后继永无不动点 ⇒ 轨道不终止
  // ==================================================================
  function RingSucc(c: nat): nat
    requires c <= 3
    ensures RingSucc(c) <= 3
    ensures RingSucc(c) != c
  {
    if c == 0 then 1 else if c == 1 then 2 else if c == 2 then 3 else 0
  }

  function RingStep(c: nat, n: nat): nat
    requires c <= 3
    ensures RingStep(c, n) <= 3
    decreases n
  {
    if n == 0 then c else RingSucc(RingStep(c, n - 1))
  }

  lemma FlatCycleNoTermination(c: nat, n: nat)
    requires c <= 3
    ensures RingSucc(RingStep(c, n)) != RingStep(c, n)
  {
  }

  lemma RingNeverStuck(c: nat, n: nat)
    requires c <= 3
    ensures RingStep(c, n) != RingSucc(RingStep(c, n))
  {
    FlatCycleNoTermination(c, n);
  }
}
