// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡下降流向(8 邻,对角 dist2 ∈ {1,2})
//  覆盖 : GPB-010 洼地无流向 / GPB-011 平面上流向恒定
//  环境 : Dafny 4.11 · dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  不用递归扫描(BestFrom 移位引理会 SMT 超时)。8 路分数比较与 Lean 同形。
//  并列时扫描序更早者胜:E, SE, S, SW, W, NW, N, NE。
// ===========================================================================

module D8Flow {

  datatype Dir = DirE | DirSE | DirS | DirSW | DirW | DirNW | DirN | DirNE
  datatype Flow = NoFlow | To(d: Dir)

  datatype Win = Win(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real)

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

  function Score(e: real, z: real, dist2: real): real
    requires dist2 > 0.0
  {
    var drop := e - z;
    if drop <= 0.0 then 0.0 else (drop * drop) / dist2
  }

  predicate Uphill(win: Win)
  {
    win.a >= win.e && win.b >= win.e && win.c >= win.e &&
    win.d >= win.e && win.f >= win.e &&
    win.g >= win.e && win.h >= win.e && win.i >= win.e
  }

  function D8(win: Win): Flow
  {
    var pE  := Score(win.e, win.f, 1.0);
    var pSE := Score(win.e, win.i, 2.0);
    var pS  := Score(win.e, win.h, 1.0);
    var pSW := Score(win.e, win.g, 2.0);
    var pW  := Score(win.e, win.d, 1.0);
    var pNW := Score(win.e, win.a, 2.0);
    var pN  := Score(win.e, win.b, 1.0);
    var pNE := Score(win.e, win.c, 2.0);
    if pE > 0.0 && pSE <= pE && pS <= pE && pSW <= pE && pW <= pE && pNW <= pE && pN <= pE && pNE <= pE then
      To(DirE)
    else if pSE > 0.0 && pE < pSE && pS <= pSE && pSW <= pSE && pW <= pSE && pNW <= pSE && pN <= pSE && pNE <= pSE then
      To(DirSE)
    else if pS > 0.0 && pE < pS && pSE < pS && pSW <= pS && pW <= pS && pNW <= pS && pN <= pS && pNE <= pS then
      To(DirS)
    else if pSW > 0.0 && pE < pSW && pSE < pSW && pS < pSW && pW <= pSW && pNW <= pSW && pN <= pSW && pNE <= pSW then
      To(DirSW)
    else if pW > 0.0 && pE < pW && pSE < pW && pS < pW && pSW < pW && pNW <= pW && pN <= pW && pNE <= pW then
      To(DirW)
    else if pNW > 0.0 && pE < pNW && pSE < pNW && pS < pNW && pSW < pNW && pW < pNW && pN <= pNW && pNE <= pNW then
      To(DirNW)
    else if pN > 0.0 && pE < pN && pSE < pN && pS < pN && pSW < pN && pW < pN && pNW < pN && pNE <= pN then
      To(DirN)
    else if pNE > 0.0 && pE < pNE && pSE < pNE && pS < pNE && pSW < pNE && pW < pNE && pNW < pNE && pN < pNE then
      To(DirNE)
    else
      NoFlow
  }

  lemma ScoreNonpos(e: real, z: real, dist2: real)
    requires dist2 > 0.0 && z >= e
    ensures Score(e, z, dist2) == 0.0
  { }

  lemma ScorePosDrop(e: real, z: real, dist2: real)
    requires dist2 > 0.0
    ensures Score(e, z, dist2) > 0.0 ==> e > z
  { }

  lemma ScoreAddConst(e: real, z: real, K: real, dist2: real)
    requires dist2 > 0.0
    ensures Score(e + K, z + K, dist2) == Score(e, z, dist2)
  {
    assert (e + K) - (z + K) == e - z;
  }

  // ==================================================================
  // GPB-010
  // ==================================================================
  lemma PitNoFlow(win: Win)
    requires Uphill(win)
    ensures D8(win) == NoFlow
  {
    ScoreNonpos(win.e, win.a, 2.0);
    ScoreNonpos(win.e, win.b, 1.0);
    ScoreNonpos(win.e, win.c, 2.0);
    ScoreNonpos(win.e, win.d, 1.0);
    ScoreNonpos(win.e, win.f, 1.0);
    ScoreNonpos(win.e, win.g, 2.0);
    ScoreNonpos(win.e, win.h, 1.0);
    ScoreNonpos(win.e, win.i, 2.0);
  }

  lemma ExamplePit()
    ensures D8(Win(1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0)) == NoFlow
  {
    PitNoFlow(Win(1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0));
  }

  lemma FlowDescent(win: Win)
    ensures D8(win).NoFlow? || (D8(win).To? && Nbr(D8(win).d, win) < win.e)
  {
    ScorePosDrop(win.e, win.f, 1.0);
    ScorePosDrop(win.e, win.i, 2.0);
    ScorePosDrop(win.e, win.h, 1.0);
    ScorePosDrop(win.e, win.g, 2.0);
    ScorePosDrop(win.e, win.d, 1.0);
    ScorePosDrop(win.e, win.a, 2.0);
    ScorePosDrop(win.e, win.b, 1.0);
    ScorePosDrop(win.e, win.c, 2.0);
  }

  // ==================================================================
  // GPB-011
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

  lemma PlaneConstant(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures D8(PlaneWin(A, B, C, w)) == D8(PlaneWin(A, B, 0.0, w))
  {
    var wC := PlaneWin(A, B, C, w);
    var w0 := PlaneWin(A, B, 0.0, w);
    assert wC.e == C && w0.e == 0.0;
    assert wC.f == A * w + C && w0.f == A * w;
    assert wC.i == A * w + B * w + C && w0.i == A * w + B * w;
    assert wC.h == B * w + C && w0.h == B * w;
    assert wC.g == A * (-w) + B * w + C && w0.g == A * (-w) + B * w;
    assert wC.d == A * (-w) + C && w0.d == A * (-w);
    assert wC.a == A * (-w) + B * (-w) + C && w0.a == A * (-w) + B * (-w);
    assert wC.b == B * (-w) + C && w0.b == B * (-w);
    assert wC.c == A * w + B * (-w) + C && w0.c == A * w + B * (-w);
    ScoreAddConst(0.0, A * w, C, 1.0);
    ScoreAddConst(0.0, A * w + B * w, C, 2.0);
    ScoreAddConst(0.0, B * w, C, 1.0);
    ScoreAddConst(0.0, A * (-w) + B * w, C, 2.0);
    ScoreAddConst(0.0, A * (-w), C, 1.0);
    ScoreAddConst(0.0, A * (-w) + B * (-w), C, 2.0);
    ScoreAddConst(0.0, B * (-w), C, 1.0);
    ScoreAddConst(0.0, A * w + B * (-w), C, 2.0);
  }

  // 一般 A,w 上 SMT 不能把 x*x>0 传到 Score(...)>0(与 P-003 的 w*w 同类)。
  // 八方位核与 Lean 一样落在具体平面 A=1,w=1;平移不变仍对一般 A,B,C,w。
  lemma PlaneWest()
    ensures D8(PlaneWin(1.0, 0.0, 0.0, 1.0)) == To(DirW)
  { }

  lemma PlaneNorthwest()
    ensures D8(PlaneWin(1.0, 1.0, 0.0, 1.0)) == To(DirNW)
  { }
}
