// ===========================================================================
//  GeoProofBench · P-006 第 6 条
//  文件 : formal/dafny/P006_terminate_under_strict.dfy
//  命题 : 严格下降(高程嵌进 nat) ⇒ D8 轨道有限步到达不动点
//  环境 : Dafny 4.11 · dafny verify P006_terminate_under_strict.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  不扫描不动点。Bound 对当前高程 c 做 decreases,后继要么卡住要么 c 变小。
//  stepN 核来自 P-006,不复制。P-COMP-1 §2.4 (iii) 引用 Bound。
// ===========================================================================

include "P006_watershed.dfy"

module TerminateUnderStrict {

  import W = Watershed

  predicate StrictDescent(succ: nat -> nat)
  {
    forall x: nat :: succ(x) <= x
  }

  // 到达不动点的步数上界。succ(c)>=c 在 StrictDescent 下即卡住。
  function Bound(succ: nat -> nat, c: nat): nat
    requires StrictDescent(succ)
    decreases c
  {
    if succ(c) >= c then 0 else 1 + Bound(succ, succ(c))
  }

  lemma BoundLe(succ: nat -> nat, c: nat)
    requires StrictDescent(succ)
    ensures Bound(succ, c) <= c
    decreases c
  {
    if succ(c) >= c {
    } else {
      BoundLe(succ, succ(c));
      assert Bound(succ, succ(c)) <= succ(c);
      assert succ(c) < c;
    }
  }

  lemma BoundIsFix(succ: nat -> nat, c: nat)
    requires StrictDescent(succ)
    ensures succ(W.stepN(succ, c, Bound(succ, c))) == W.stepN(succ, c, Bound(succ, c))
    decreases c
  {
    if succ(c) >= c {
      assert succ(c) == c;
      assert W.stepN(succ, c, 0) == c;
    } else {
      BoundIsFix(succ, succ(c));
      var k := Bound(succ, succ(c));
      assert Bound(succ, c) == 1 + k;
      assert W.stepN(succ, c, 1) == succ(c);
      W.StepNAdd(succ, c, 1, k);
      assert W.stepN(succ, c, 1 + k) == W.stepN(succ, W.stepN(succ, c, 1), k);
      assert W.stepN(succ, c, 1 + k) == W.stepN(succ, succ(c), k);
    }
  }

  lemma TerminatesUnderStrictDescent(succ: nat -> nat, c: nat)
    requires StrictDescent(succ)
    ensures exists n: nat :: n <= c && succ(W.stepN(succ, c, n)) == W.stepN(succ, c, n)
  {
    BoundLe(succ, c);
    BoundIsFix(succ, c);
    var n := Bound(succ, c);
    assert n <= c;
    assert succ(W.stepN(succ, c, n)) == W.stepN(succ, c, n);
  }

  // 高程后继: n ↦ n-1,0 卡住。Bound = 起点本身。
  function HeightSucc(c: nat): nat
  {
    if c == 0 then 0 else c - 1
  }

  lemma HeightSuccIsDescent()
    ensures StrictDescent(HeightSucc)
  {
  }

  lemma HeightBoundEq(c: nat)
    requires StrictDescent(HeightSucc)
    ensures Bound(HeightSucc, c) == c
    decreases c
  {
    if c == 0 {
      assert HeightSucc(0) == 0;
    } else {
      assert HeightSucc(c) == c - 1;
      HeightBoundEq(c - 1);
    }
  }

  lemma HeightTerminates(c: nat)
    requires StrictDescent(HeightSucc)
    ensures HeightSucc(W.stepN(HeightSucc, c, Bound(HeightSucc, c))) ==
            W.stepN(HeightSucc, c, Bound(HeightSucc, c))
  {
    HeightBoundEq(c);
    BoundIsFix(HeightSucc, c);
  }
}
