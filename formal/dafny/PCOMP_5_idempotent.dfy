// ===========================================================================
//  GeoProofBench · P-COMP-5 = 填洼元性质(幂等 + 调度无关)
//  文件 : formal/dafny/PCOMP_5_idempotent.dfy
//  命题 : Fill ∘ Fill = Fill; 双亲抬升 max 交换; 四条 1D 实例与 Lean/Python 同值
//  环境 : Dafny 4.11 · dafny verify PCOMP_5_idempotent.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  include P-002 / P-002-bis,不复制 Fill / RaiseNbr 核。
//  不 include P-001(文件级 Main 冲突)。网格尺寸不出现在定理里。
// ===========================================================================

include "P002_pit_filling_2d.dfy"

module CompositionIdempotent {

  import PF = PitFilling
  import P002 = PitFilling2D

  lemma FillIdem(a: seq<int>)
    ensures PF.Fill(PF.Fill(a)) == PF.Fill(a)
  {
    PF.FillIdempotent(a);
  }

  lemma FillFixOnNonDec(a: seq<int>)
    requires PF.NonDecreasing(a)
    ensures PF.Fill(a) == a
  {
    PF.FillFixpoint(a);
  }

  lemma MaxComm(x: int, y: int)
    ensures P002.Max(x, y) == P002.Max(y, x)
  {
  }

  lemma ParentSchedule(orig: int, p1: int, p2: int)
    ensures P002.Max(P002.Max(orig, p1), p2)
            == P002.Max(P002.Max(orig, p2), p1)
  {
    MaxComm(p1, p2);
    MaxComm(orig, p1);
    MaxComm(orig, p2);
  }

  lemma HashPlane()
    ensures PF.Fill([5, 5, 5, 5]) == [5, 5, 5, 5]
  {
    PF.FillFixpoint([5, 5, 5, 5]);
  }

  lemma HashPit()
    ensures PF.Fill([3, 1, 4]) == [3, 3, 4]
  {
    PF.ExamplePitFilled();
  }

  lemma HashSlope()
    ensures PF.Fill([0, 1, 2, 3]) == [0, 1, 2, 3]
  {
    PF.FillFixpoint([0, 1, 2, 3]);
  }

  lemma HashCascade()
    ensures PF.Fill([3, 1, 0]) == [3, 3, 3]
  {
    var a := [3, 1, 0];
    assert PF.Raise(a, 1) == [3, 3, 0];
    assert PF.Raise([3, 3, 0], 2) == [3, 3, 3];
    calc {
      PF.Fill(a);
      == PF.FillFrom(a, 1);
      == PF.FillFrom(PF.Raise(a, 1), 2);
      == PF.FillFrom([3, 3, 0], 2);
      == PF.FillFrom(PF.Raise([3, 3, 0], 2), 3);
      == PF.FillFrom([3, 3, 3], 3);
      == [3, 3, 3];
    }
  }

  lemma TwicePit()
    ensures PF.Fill(PF.Fill([3, 1, 4])) == PF.Fill([3, 1, 4])
  {
    FillIdem([3, 1, 4]);
  }

  lemma TwiceCascade()
    ensures PF.Fill(PF.Fill([3, 1, 0])) == [3, 3, 3]
  {
    HashCascade();
    FillIdem([3, 1, 0]);
  }

  lemma FillNonDec(a: seq<int>)
    ensures PF.NonDecreasing(PF.Fill(a))
  {
    PF.FillCorrect(a);
  }

  lemma FillGeOrig(a: seq<int>)
    ensures forall j :: 0 <= j < |a| ==> PF.Fill(a)[j] >= a[j]
  {
    PF.FillCorrect(a);
  }

  lemma StripIsFill(a: seq<int>)
    ensures P002.FillStrip(a) == PF.Fill(a)
  {
    P002.FillStripEq1D(a);
  }

  lemma CenterPitRaise()
  {
    P002.ExampleCenterPit();
  }
}
