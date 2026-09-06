// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡下降流向(8 邻,对角距离² = 2)
//  覆盖 : GPB-010 洼地无流向 / GPB-011 平面上流向恒定
//  环境 : Dafny 4.11 · dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  约定(与 P-001 相同:p 向右,q 向下):
//      a(-1,-1) b(0,-1) c(1,-1)
//      d(-1, 0)   e     f(1, 0)
//      g(-1, 1) h(0, 1) i(1, 1)
//
//  流向:在 drop = e - z_nbr > 0 的邻居里取 drop/dist 最大者。
//  比较用 (drop² / dist²),dist² ∈ {w², 2 w²},约掉 w² 后 dist2 ∈ {1,2}。
//  不用 √2,SMT 友好。并列时取扫描顺序里更早的方向(确定性)。
//  扫描序:E, SE, S, SW, W, NW, N, NE。
//
//  不证:任意 DEM 上全局无环(平坦处 D8 可以转圈,那是填洼之后的事);
//  也不证流域唯一(GPB-015)。
// ===========================================================================

module D8Flow {

  datatype Dir = DirE | DirSE | DirS | DirSW | DirW | DirNW | DirN | DirNE
  datatype Flow = NoFlow | To(d: Dir)

  datatype Win = Win(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real)

  function Dist2(dir: Dir): real
  {
    match dir
      case DirE | DirS | DirW | DirN => 1.0
      case DirSE | DirSW | DirNW | DirNE => 2.0
  }

  function Nbr(dir: Dir, win: Win): real
  {
    match dir
      case DirE  => win.f
      case DirSE => win.i
      case DirS  => win.h
      case DirSW => win.g
      case DirW  => win.d
      case DirNW => win.a
      case DirN  => win.b
      case DirNE => win.c
  }

  function DirAt(k: nat): Dir
    requires k < 8
  {
    if k == 0 then DirE
    else if k == 1 then DirSE
    else if k == 2 then DirS
    else if k == 3 then DirSW
    else if k == 4 then DirW
    else if k == 5 then DirNW
    else if k == 6 then DirN
    else DirNE
  }

  predicate Uphill(win: Win)
  {
    win.a >= win.e && win.b >= win.e && win.c >= win.e &&
    win.d >= win.e && win.f >= win.e &&
    win.g >= win.e && win.h >= win.e && win.i >= win.e
  }

  lemma NbrUphill(dir: Dir, win: Win)
    requires Uphill(win)
    ensures Nbr(dir, win) >= win.e
  {
  }

  function BestFrom(k: nat, win: Win, best: Flow, bestP: real): Flow
    requires k <= 8
    decreases 8 - k
  {
    if k == 8 then best
    else
      var dir := DirAt(k);
      var drop := win.e - Nbr(dir, win);
      if drop <= 0.0 then
        BestFrom(k + 1, win, best, bestP)
      else
        var p := (drop * drop) / Dist2(dir);
        if best.NoFlow? || p > bestP then
          BestFrom(k + 1, win, To(dir), p)
        else
          BestFrom(k + 1, win, best, bestP)
  }

  function D8(win: Win): Flow
  {
    BestFrom(0, win, NoFlow, 0.0)
  }

  // ==================================================================
  // GPB-010 · 局部洼地(八邻都不低于中心)⇒ 无流向
  // ==================================================================
  lemma BestFromUphill(k: nat, win: Win)
    requires k <= 8
    requires Uphill(win)
    ensures BestFrom(k, win, NoFlow, 0.0) == NoFlow
    decreases 8 - k
  {
    if k == 8 {
    } else {
      NbrUphill(DirAt(k), win);
      assert win.e - Nbr(DirAt(k), win) <= 0.0;
      BestFromUphill(k + 1, win);
    }
  }

  lemma PitNoFlow(win: Win)
    requires Uphill(win)
    ensures D8(win) == NoFlow
  {
    BestFromUphill(0, win);
  }

  lemma ExamplePit()
    ensures D8(Win(1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0)) == NoFlow
  {
    PitNoFlow(Win(1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0));
  }

  // ==================================================================
  // 流向闭合核:一旦选出方向,该邻格严格低于中心(严格下降 ⇒ 非平坦环)
  // ==================================================================
  lemma BestFromDescent(k: nat, win: Win, best: Flow, bestP: real)
    requires k <= 8
    requires best.NoFlow? || (best.To? && Nbr(best.d, win) < win.e)
    ensures var f := BestFrom(k, win, best, bestP);
            f.NoFlow? || (f.To? && Nbr(f.d, win) < win.e)
    decreases 8 - k
  {
    if k == 8 {
    } else {
      var dir := DirAt(k);
      var drop := win.e - Nbr(dir, win);
      if drop <= 0.0 {
        BestFromDescent(k + 1, win, best, bestP);
      } else {
        var p := (drop * drop) / Dist2(dir);
        if best.NoFlow? || p > bestP {
          assert Nbr(dir, win) < win.e;
          BestFromDescent(k + 1, win, To(dir), p);
        } else {
          BestFromDescent(k + 1, win, best, bestP);
        }
      }
    }
  }

  lemma FlowDescent(win: Win)
    ensures D8(win).NoFlow? || (D8(win).To? && Nbr(D8(win).d, win) < win.e)
  {
    BestFromDescent(0, win, NoFlow, 0.0);
  }

  // ==================================================================
  // GPB-011 · 平面 z = A x + B y + C 上窗口只差一个常数,流向相同
  // ==================================================================
  function PlaneWin(A: real, B: real, C: real, w: real): Win
    requires w > 0.0
  {
    Win(
      A * (-w) + B * (-w) + C,
      B * (-w) + C,
      A * w + B * (-w) + C,
      A * (-w) + C,
      C,
      A * w + C,
      A * (-w) + B * w + C,
      B * w + C,
      A * w + B * w + C)
  }

  lemma PlaneDrop(A: real, B: real, C: real, w: real, dir: Dir)
    requires w > 0.0
    ensures PlaneWin(A, B, C, w).e - Nbr(dir, PlaneWin(A, B, C, w))
            == PlaneWin(A, B, 0.0, w).e - Nbr(dir, PlaneWin(A, B, 0.0, w))
  {
  }

  lemma BestFromPlaneShift(k: nat, A: real, B: real, C: real, w: real,
                           best: Flow, bestP: real)
    requires w > 0.0
    requires k <= 8
    ensures BestFrom(k, PlaneWin(A, B, C, w), best, bestP)
            == BestFrom(k, PlaneWin(A, B, 0.0, w), best, bestP)
    decreases 8 - k
  {
    if k == 8 {
    } else {
      var dir := DirAt(k);
      var winC := PlaneWin(A, B, C, w);
      var win0 := PlaneWin(A, B, 0.0, w);
      PlaneDrop(A, B, C, w, dir);
      var dropC := winC.e - Nbr(dir, winC);
      var drop0 := win0.e - Nbr(dir, win0);
      assert dropC == drop0;
      if dropC <= 0.0 {
        BestFromPlaneShift(k + 1, A, B, C, w, best, bestP);
      } else {
        var p := (dropC * dropC) / Dist2(dir);
        if best.NoFlow? || p > bestP {
          BestFromPlaneShift(k + 1, A, B, C, w, To(dir), p);
        } else {
          BestFromPlaneShift(k + 1, A, B, C, w, best, bestP);
        }
      }
    }
  }

  lemma PlaneConstant(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures D8(PlaneWin(A, B, C, w)) == D8(PlaneWin(A, B, 0.0, w))
  {
    BestFromPlaneShift(0, A, B, C, w, NoFlow, 0.0);
  }

  // A>0, B=0:升高向东,流向西(唯一,对角距离更长)
  lemma PlaneWest(A: real, w: real)
    requires A > 0.0 && w > 0.0
    ensures D8(PlaneWin(A, 0.0, 0.0, w)) == To(DirW)
  {
    var win := PlaneWin(A, 0.0, 0.0, w);
    var pW := (A * w) * (A * w) / 1.0;
    var pD := (A * w) * (A * w) / 2.0;
    assert pW > pD;
    assert win.e - Nbr(DirE, win) < 0.0;
    assert win.e - Nbr(DirSE, win) < 0.0;
    assert win.e - Nbr(DirS, win) == 0.0;
    assert win.e - Nbr(DirSW, win) == A * w;
    assert win.e - Nbr(DirW, win) == A * w;
    assert win.e - Nbr(DirNW, win) == A * w;
    assert win.e - Nbr(DirN, win) == 0.0;
    assert win.e - Nbr(DirNE, win) < 0.0;
    assert BestFrom(0, win, NoFlow, 0.0) == BestFrom(3, win, NoFlow, 0.0);
    assert BestFrom(3, win, NoFlow, 0.0) == BestFrom(4, win, To(DirSW), pD);
    assert BestFrom(4, win, To(DirSW), pD) == BestFrom(5, win, To(DirW), pW);
    assert BestFrom(5, win, To(DirW), pW) == BestFrom(8, win, To(DirW), pW);
    assert BestFrom(8, win, To(DirW), pW) == To(DirW);
  }

  lemma PlaneNorthwest(A: real, w: real)
    requires A > 0.0 && w > 0.0
    ensures D8(PlaneWin(A, A, 0.0, w)) == To(DirNW)
  {
    var win := PlaneWin(A, A, 0.0, w);
    var pNW := (2.0 * A * w) * (2.0 * A * w) / 2.0;
    var pCard := (A * w) * (A * w) / 1.0;
    assert pNW > pCard;
    assert win.e - Nbr(DirE, win) < 0.0;
    assert win.e - Nbr(DirSE, win) < 0.0;
    assert win.e - Nbr(DirS, win) < 0.0;
    assert win.e - Nbr(DirSW, win) == 0.0;
    assert win.e - Nbr(DirW, win) == A * w;
    assert win.e - Nbr(DirNW, win) == 2.0 * A * w;
    assert win.e - Nbr(DirN, win) == A * w;
    assert win.e - Nbr(DirNE, win) == 0.0;
    assert BestFrom(0, win, NoFlow, 0.0) == BestFrom(4, win, NoFlow, 0.0);
    assert BestFrom(4, win, NoFlow, 0.0) == BestFrom(5, win, To(DirW), pCard);
    assert BestFrom(5, win, To(DirW), pCard) == BestFrom(6, win, To(DirNW), pNW);
    assert BestFrom(6, win, To(DirNW), pNW) == BestFrom(8, win, To(DirNW), pNW);
    assert BestFrom(8, win, To(DirNW), pNW) == To(DirNW);
  }
}
