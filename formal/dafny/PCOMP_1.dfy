// ===========================================================================
//  GeoProofBench · P-COMP-1 = P-002 ∘ P-006
//  文件 : formal/dafny/PCOMP_1.dfy
//  命题 : 填洼后流域唯一(层 A 复用 BasinUnique,只证前提 (i)~(iv))
//  环境 : Dafny 4.11 · dafny verify PCOMP_1.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  include 三模块(+ 第 6 条 Bound),不复制 Fill / D8 / stepN 核。
//  种子层没有整幅 2D pitFill2D 或格网 basin;本文件按 PROP_CHAIN §2.4
//  把已证引理接到组合接口上。
// ===========================================================================

include "P002_pit_filling_2d.dfy"
include "P006_terminate_under_strict.dfy"

module CompositionPitThenWatershed {

  import PF = PitFilling
  import P002 = PitFilling2D
  import P005 = D8Flow
  import P006 = Watershed
  import T6 = TerminateUnderStrict

  // ------------------------------------------------------------------
  // (i) 填洼后每格有一个不高的邻接:1D Fill 非降 ⇒ 西邻 ≤ 自身
  // ------------------------------------------------------------------
  lemma NoPitImpliesDescent(a: seq<int>, k: int)
    requires 1 <= k < |a|
    ensures PF.Fill(a)[k - 1] <= PF.Fill(a)[k]
  {
    PF.FillCorrect(a);
  }

  lemma NoPitImpliesDescent2D(orig: P002.Grid, fill: P002.Grid,
                              pr: int, pc: int, nr: int, nc: int)
    requires P002.Rect(orig) && P002.Rect(fill) && P002.SameShape(orig, fill)
    requires P002.InGrid(orig, pr, pc) && P002.InGrid(orig, nr, nc)
    requires P002.Adjacent4(pr, pc, nr, nc)
    ensures P002.At(P002.RaiseNbr(orig, fill, pr, pc, nr, nc), nr, nc)
            >= P002.At(P002.RaiseNbr(orig, fill, pr, pc, nr, nc), pr, pc)
  {
    P002.RaiseNbrProcessedFrozen(orig, fill, pr, pc, nr, nc);
    P002.RaiseNbrMonotone(orig, fill, pr, pc, nr, nc);
    var f2 := P002.RaiseNbr(orig, fill, pr, pc, nr, nc);
    var nv := P002.Max(P002.At(orig, nr, nc), P002.At(fill, pr, pc));
    if nv > P002.At(fill, nr, nc) {
      assert P002.At(f2, nr, nc) == nv;
      assert P002.At(f2, pr, pc) == P002.At(fill, pr, pc);
      assert nv >= P002.At(fill, pr, pc);
    } else {
      assert f2 == fill;
      assert P002.At(fill, nr, nc) >= nv;
      assert nv >= P002.At(fill, pr, pc);
    }
  }

  // ------------------------------------------------------------------
  // (ii) P-005 FlowDescent:选出方向 ⇒ 邻格严格低于中心
  // ------------------------------------------------------------------
  lemma D8PreservesDescent(win: P005.Win)
    ensures P005.D8(win).NoFlow? ||
            (P005.D8(win).To? && P005.Nbr(P005.D8(win).d, win) < win.e)
  {
    P005.FlowDescent(win);
  }

  // ------------------------------------------------------------------
  // (iii) 轨道长度上界:严格下降走 T6.Bound;否则有限链走鸽笼
  // ------------------------------------------------------------------
  lemma OrbitLengthBound(succ: nat -> nat, c: nat)
    requires T6.StrictDescent(succ)
    ensures exists n: nat :: n <= c &&
              succ(P006.stepN(succ, c, n)) == P006.stepN(succ, c, n)
  {
    T6.TerminatesUnderStrictDescent(succ, c);
  }

  lemma OrbitLengthBoundPigeon(c: nat)
    requires c <= 2
    ensures P006.ChainOutlet(P006.stepN(P006.ChainSucc, c, 2))
  {
    P006.TerminatesImpliesBasin(c);
  }

  // ------------------------------------------------------------------
  // (iv) 出口集合非空:洼地窗口 NoFlow;链上 2 是不动点
  // ------------------------------------------------------------------
  lemma BoundaryNonEmpty()
    ensures P005.D8(P005.Win(1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0))
            == P005.NoFlow
  {
    P005.ExamplePit();
  }

  lemma BoundaryNonEmptyChain()
    ensures P006.ChainSucc(2) == 2
  {
  }

  // ------------------------------------------------------------------
  // (v) 主定理:终止前提下出口唯一 = P-006 BasinUnique,不重写
  // ------------------------------------------------------------------
  lemma FillThenWatershed(succ: nat -> nat, c: nat, n1: nat, n2: nat,
                          o1: nat, o2: nat)
    requires P006.stepN(succ, c, n1) == o1 && succ(o1) == o1
    requires P006.stepN(succ, c, n2) == o2 && succ(o2) == o2
    ensures o1 == o2
  {
    P006.BasinUnique(succ, c, n1, n2, o1, o2);
  }

  lemma FillThenWatershedFromDescent(succ: nat -> nat, c: nat)
    requires T6.StrictDescent(succ)
    ensures exists o: nat :: succ(o) == o &&
              exists n: nat :: n <= c && P006.stepN(succ, c, n) == o
  {
    T6.BoundLe(succ, c);
    T6.BoundIsFix(succ, c);
    var n := T6.Bound(succ, c);
    var o := P006.stepN(succ, c, n);
    assert n <= c;
    assert succ(o) == o;
  }

  lemma FillThenWatershedUniqueFromDescent(succ: nat -> nat, c: nat,
                                            n1: nat, n2: nat, o1: nat, o2: nat)
    requires T6.StrictDescent(succ)
    requires P006.stepN(succ, c, n1) == o1 && succ(o1) == o1
    requires P006.stepN(succ, c, n2) == o2 && succ(o2) == o2
    ensures o1 == o2
  {
    P006.BasinUnique(succ, c, n1, n2, o1, o2);
  }

  lemma ExampleFilledStripThenUnique()
    ensures PF.Fill([3, 1, 4]) == [3, 3, 4]
    ensures PF.Fill([3, 1, 4])[0] <= PF.Fill([3, 1, 4])[1]
    ensures PF.Fill([3, 1, 4])[1] <= PF.Fill([3, 1, 4])[2]
  {
    PF.ExamplePitFilled();
    NoPitImpliesDescent([3, 1, 4], 1);
    NoPitImpliesDescent([3, 1, 4], 2);
  }
}
