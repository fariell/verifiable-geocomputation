// ===========================================================================
//  GeoProofBench · P-COMP-2 = P-002 ∘ P-005平面恒定 ∘ P-006
//  文件 : formal/dafny/PCOMP_2.dfy
//  命题 : 全平面(0 起伏 / 行扰动)填洼后,每格轨道终止于唯一出口
//  环境 : Dafny 4.11 · dafny verify PCOMP_2.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  include 与 P-COMP-1 相同的三模块(+ T6),不复制 Fill / D8 / stepN 核。
//  网格尺寸不出现在定理里:256² 是数值 driver 的实例,形式化对任意 c:nat。
// ===========================================================================

include "P002_pit_filling_2d.dfy"
include "P006_terminate_under_strict.dfy"

module CompositionPitThenWatershedPlane {

  import PF = PitFilling
  import P002 = PitFilling2D
  import P005 = D8Flow
  import P006 = Watershed
  import T6 = TerminateUnderStrict

  // ------------------------------------------------------------------
  // 0 起伏:常数窗口 Uphill ⇒ NoFlow(流向恒定的退化情况)
  // ------------------------------------------------------------------
  lemma FlatWindowUphill()
    ensures P005.Uphill(P005.Win(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0))
  {
  }

  lemma FlatWindowNoFlow()
    ensures P005.D8(P005.Win(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0))
            == P005.NoFlow
  {
    FlatWindowUphill();
    P005.PitNoFlow(P005.Win(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0));
  }

  lemma FlatWindowNoFlowC12()
    ensures P005.D8(P005.Win(12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0))
            == P005.NoFlow
  {
    P005.PitNoFlow(P005.Win(12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0));
  }

  // ------------------------------------------------------------------
  // P-005 平面恒定:平移不变 + 西向实例(行扰动的 1D 模型)
  // ------------------------------------------------------------------
  lemma PlaneFlowIndependentOfOffset(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures P005.D8(P005.PlaneWin(A, B, C, w))
            == P005.D8(P005.PlaneWin(A, B, 0.0, w))
  {
    P005.PlaneConstant(A, B, C, w);
  }

  lemma PlaneWestConstant()
    ensures P005.D8(P005.PlaneWin(1.0, 0.0, 0.0, 1.0)) == P005.To(P005.DirW)
  {
    P005.PlaneWest();
  }

  lemma PlaneWestOffsetC0()
    ensures P005.D8(P005.PlaneWin(1.0, 0.0, 0.0, 1.0)) == P005.To(P005.DirW)
  {
    PlaneFlowIndependentOfOffset(1.0, 0.0, 0.0, 1.0);
    P005.PlaneWest();
  }

  lemma D8PreservesDescent(win: P005.Win)
    ensures P005.D8(win).NoFlow? ||
            (P005.D8(win).To? && P005.Nbr(P005.D8(win).d, win) < win.e)
  {
    P005.FlowDescent(win);
  }

  // ------------------------------------------------------------------
  // 0 起伏 1D:常数带非降 ⇒ Fill 恒等(填洼闭包)
  // ------------------------------------------------------------------
  lemma FlatStripFillIdentity()
    ensures PF.Fill([5, 5, 5, 5]) == [5, 5, 5, 5]
  {
    PF.FillFixpoint([5, 5, 5, 5]);
  }

  lemma MonotoneStripFillIdentity(a: seq<int>)
    requires PF.NonDecreasing(a)
    ensures PF.Fill(a) == a
  {
    PF.FillFixpoint(a);
  }

  lemma RowSlopeStripFillIdentity()
    ensures PF.NonDecreasing([0, 1, 2, 3])
    ensures PF.Fill([0, 1, 2, 3]) == [0, 1, 2, 3]
  {
    PF.FillFixpoint([0, 1, 2, 3]);
  }

  lemma NoPitImpliesDescent(a: seq<int>, k: int)
    requires 1 <= k < |a|
    ensures PF.Fill(a)[k - 1] <= PF.Fill(a)[k]
  {
    PF.FillCorrect(a);
  }

  // ------------------------------------------------------------------
  // 西向 / 行扰动的 1D 后继 = T6.HeightSucc(不复制核)
  // 形式化不依赖 256:任意 c:nat 都终止;数值端取 c=255 当 256-cell
  // ------------------------------------------------------------------
  lemma WestPlaneSuccIsDescent()
    ensures T6.StrictDescent(T6.HeightSucc)
  {
    T6.HeightSuccIsDescent();
  }

  lemma WestPlaneEveryCellTerminates(c: nat)
    ensures exists n: nat :: n <= c &&
              T6.HeightSucc(P006.stepN(T6.HeightSucc, c, n))
              == P006.stepN(T6.HeightSucc, c, n)
  {
    T6.HeightSuccIsDescent();
    T6.TerminatesUnderStrictDescent(T6.HeightSucc, c);
  }

  lemma WestPlane256Terminates()
    ensures exists n: nat :: n <= 255 &&
              T6.HeightSucc(P006.stepN(T6.HeightSucc, 255, n))
              == P006.stepN(T6.HeightSucc, 255, n)
  {
    WestPlaneEveryCellTerminates(255);
  }

  lemma WestPlaneBoundEq(c: nat)
    ensures T6.Bound(T6.HeightSucc, c) == c
  {
    T6.HeightSuccIsDescent();
    T6.HeightBoundEq(c);
  }

  lemma WestPlaneOutletUnique(c: nat, n1: nat, n2: nat, o1: nat, o2: nat)
    requires P006.stepN(T6.HeightSucc, c, n1) == o1 && T6.HeightSucc(o1) == o1
    requires P006.stepN(T6.HeightSucc, c, n2) == o2 && T6.HeightSucc(o2) == o2
    ensures o1 == o2
  {
    P006.BasinUnique(T6.HeightSucc, c, n1, n2, o1, o2);
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

  lemma PlaneClosureUniqueFromDescent(succ: nat -> nat, c: nat,
                                       n1: nat, n2: nat, o1: nat, o2: nat)
    requires T6.StrictDescent(succ)
    requires P006.stepN(succ, c, n1) == o1 && succ(o1) == o1
    requires P006.stepN(succ, c, n2) == o2 && succ(o2) == o2
    ensures o1 == o2
  {
    P006.BasinUnique(succ, c, n1, n2, o1, o2);
  }
}
