// ===========================================================================
//  GeoProofBench · P-004
//  文件 : formal/dafny/P004_consistency.dfy
//  算子 : Horn (1981) 3x3 坡度在 w→0 下的代数核
//  覆盖 : GPB-019 完整版的可证部分
//         — 二次面精确(次数 ≤2)
//         — 三次单项式余项 = G w²(因而随 w 缩小)
//  环境 : Dafny 4.11 · dafny verify P004_consistency.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  P-001 只证了平面上恒等。GPB-019 全文是"网格间距 → 0 时一致"。
//  一般 C^∞ 的 Filter.Tendsto 不进 SMT。本文件证两条真命题:
//    1. 二次面 z = A x + B y + C + D x² + E xy + F y² 上,Horn 在窗口
//       中心仍精确恢复 (A, B)。(次数 ≤2 无余项)
//    2. 三次 z = G x³ 上,DzDx = G w²(真值在原点为 0)。|误差|随 w 缩小。
//  Wolfram 给出一般 Taylor:HornDx - hx = O(w²),首项含 hxxx。
//
//  不证:任意 C² 曲面的一致(那是 Lean 的 tendsto,且只对这个余项族);
//  也不把 GPB-020 曲率收敛写进来。
// ===========================================================================

module HornConsistency {

  function NumDx(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (c + 2.0 * f + i) - (a + 2.0 * d + g) }

  function NumDy(a: real, b: real, c: real, d: real, f: real,
                 g: real, h: real, i: real): real
  { (g + 2.0 * h + i) - (a + 2.0 * b + c) }

  function DzDx(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumDx(a, b, c, d, f, g, h, i) / (8.0 * w) }

  function DzDy(a: real, b: real, c: real, d: real, f: real,
                g: real, h: real, i: real, w: real): real
    requires w > 0.0
  { NumDy(a, b, c, d, f, g, h, i) / (8.0 * w) }

  lemma DivCancel(x: real, y: real)
    requires y != 0.0
    ensures (x * y) / y == x
  { }

  function Abs(x: real): real
  { if x >= 0.0 then x else -x }

  lemma NumDxAdd(
      a1: real, b1: real, c1: real, d1: real, f1: real, g1: real, h1: real, i1: real,
      a2: real, b2: real, c2: real, d2: real, f2: real, g2: real, h2: real, i2: real)
    ensures NumDx(a1 + a2, b1 + b2, c1 + c2, d1 + d2, f1 + f2, g1 + g2, h1 + h2, i1 + i2)
            == NumDx(a1, b1, c1, d1, f1, g1, h1, i1)
               + NumDx(a2, b2, c2, d2, f2, g2, h2, i2)
  { }

  lemma NumDyAdd(
      a1: real, b1: real, c1: real, d1: real, f1: real, g1: real, h1: real, i1: real,
      a2: real, b2: real, c2: real, d2: real, f2: real, g2: real, h2: real, i2: real)
    ensures NumDy(a1 + a2, b1 + b2, c1 + c2, d1 + d2, f1 + f2, g1 + g2, h1 + h2, i1 + i2)
            == NumDy(a1, b1, c1, d1, f1, g1, h1, i1)
               + NumDy(a2, b2, c2, d2, f2, g2, h2, i2)
  { }

  // z = A x + B y + C + D x² + E xy + F y²,x = p w,y = q w
  function Quad(A: real, B: real, C: real, D: real, E: real, F: real,
                w: real, p: real, q: real): real
  {
    A * (p * w) + B * (q * w) + C
    + D * (p * w) * (p * w)
    + E * (p * w) * (q * w)
    + F * (q * w) * (q * w)
  }

  function CubicX(G: real, w: real, p: real): real
  {
    G * (p * w) * (p * w) * (p * w)
  }

  function CubicY(G: real, w: real, q: real): real
  {
    G * (q * w) * (q * w) * (q * w)
  }

  // ------------------------------------------------------------------
  // 单项式:x² / xy / y² 对 NumDx、NumDy 的贡献为 0
  // ------------------------------------------------------------------
  lemma MonomialX2NumDx(D: real, w: real)
    requires w > 0.0
    ensures NumDx(D * w * w, 0.0, D * w * w,
                  D * w * w, D * w * w,
                  D * w * w, 0.0, D * w * w) == 0.0
  {
    assert D * w * w + 2.0 * (D * w * w) + D * w * w == 4.0 * D * w * w;
  }

  lemma MonomialX2NumDy(D: real, w: real)
    requires w > 0.0
    ensures NumDy(D * w * w, 0.0, D * w * w,
                  D * w * w, D * w * w,
                  D * w * w, 0.0, D * w * w) == 0.0
  { }

  lemma MonomialXYNumDx(E: real, w: real)
    requires w > 0.0
    ensures NumDx(E * w * w, 0.0, -E * w * w,
                  0.0, 0.0,
                  -E * w * w, 0.0, E * w * w) == 0.0
  { }

  lemma MonomialXYNumDy(E: real, w: real)
    requires w > 0.0
    ensures NumDy(E * w * w, 0.0, -E * w * w,
                  0.0, 0.0,
                  -E * w * w, 0.0, E * w * w) == 0.0
  { }

  lemma MonomialY2NumDx(F: real, w: real)
    requires w > 0.0
    ensures NumDx(F * w * w, F * w * w, F * w * w,
                  0.0, 0.0,
                  F * w * w, F * w * w, F * w * w) == 0.0
  { }

  lemma MonomialY2NumDy(F: real, w: real)
    requires w > 0.0
    ensures NumDy(F * w * w, F * w * w, F * w * w,
                  0.0, 0.0,
                  F * w * w, F * w * w, F * w * w) == 0.0
  { }

  lemma PlaneNumDx(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures NumDx(
              A * (-w) + B * (-w) + C,
              B * (-w) + C,
              A * w + B * (-w) + C,
              A * (-w) + C,
              A * w + C,
              A * (-w) + B * w + C,
              B * w + C,
              A * w + B * w + C) == A * (8.0 * w)
  { }

  lemma PlaneNumDy(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures NumDy(
              A * (-w) + B * (-w) + C,
              B * (-w) + C,
              A * w + B * (-w) + C,
              A * (-w) + C,
              A * w + C,
              A * (-w) + B * w + C,
              B * w + C,
              A * w + B * w + C) == B * (8.0 * w)
  { }

  // ==================================================================
  // GPB-019 · 二次面上精确恢复梯度
  // ==================================================================
  lemma QuadraticExact(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures DzDx(
              Quad(A, B, C, D, E, F, w, -1.0, -1.0),
              Quad(A, B, C, D, E, F, w,  0.0, -1.0),
              Quad(A, B, C, D, E, F, w,  1.0, -1.0),
              Quad(A, B, C, D, E, F, w, -1.0,  0.0),
              Quad(A, B, C, D, E, F, w,  1.0,  0.0),
              Quad(A, B, C, D, E, F, w, -1.0,  1.0),
              Quad(A, B, C, D, E, F, w,  0.0,  1.0),
              Quad(A, B, C, D, E, F, w,  1.0,  1.0), w) == A
    ensures DzDy(
              Quad(A, B, C, D, E, F, w, -1.0, -1.0),
              Quad(A, B, C, D, E, F, w,  0.0, -1.0),
              Quad(A, B, C, D, E, F, w,  1.0, -1.0),
              Quad(A, B, C, D, E, F, w, -1.0,  0.0),
              Quad(A, B, C, D, E, F, w,  1.0,  0.0),
              Quad(A, B, C, D, E, F, w, -1.0,  1.0),
              Quad(A, B, C, D, E, F, w,  0.0,  1.0),
              Quad(A, B, C, D, E, F, w,  1.0,  1.0), w) == B
  {
    var a := Quad(A, B, C, D, E, F, w, -1.0, -1.0);
    var b := Quad(A, B, C, D, E, F, w,  0.0, -1.0);
    var c := Quad(A, B, C, D, E, F, w,  1.0, -1.0);
    var d := Quad(A, B, C, D, E, F, w, -1.0,  0.0);
    var f := Quad(A, B, C, D, E, F, w,  1.0,  0.0);
    var g := Quad(A, B, C, D, E, F, w, -1.0,  1.0);
    var h := Quad(A, B, C, D, E, F, w,  0.0,  1.0);
    var i := Quad(A, B, C, D, E, F, w,  1.0,  1.0);

    var pa := A * (-w) + B * (-w) + C;
    var pb := B * (-w) + C;
    var pc := A * w + B * (-w) + C;
    var pd := A * (-w) + C;
    var pf := A * w + C;
    var pg := A * (-w) + B * w + C;
    var ph := B * w + C;
    var pi := A * w + B * w + C;
    var Da := D * w * w; var Db := 0.0; var Dc := D * w * w;
    var Dd := D * w * w; var Df := D * w * w;
    var Dg := D * w * w; var Dh := 0.0; var Di := D * w * w;
    var Ea := E * w * w; var Eb := 0.0; var Ec := -E * w * w;
    var Ed := 0.0; var Ef := 0.0;
    var Eg := -E * w * w; var Eh := 0.0; var Ei := E * w * w;
    var Fa := F * w * w; var Fb := F * w * w; var Fc := F * w * w;
    var Fd := 0.0; var Ff := 0.0;
    var Fg := F * w * w; var Fh := F * w * w; var Fi := F * w * w;

    assert a == pa + Da + Ea + Fa;
    assert b == pb + Db + Eb + Fb;
    assert c == pc + Dc + Ec + Fc;
    assert d == pd + Dd + Ed + Fd;
    assert f == pf + Df + Ef + Ff;
    assert g == pg + Dg + Eg + Fg;
    assert h == ph + Dh + Eh + Fh;
    assert i == pi + Di + Ei + Fi;

    PlaneNumDx(A, B, C, w);
    PlaneNumDy(A, B, C, w);
    MonomialX2NumDx(D, w);
    MonomialX2NumDy(D, w);
    MonomialXYNumDx(E, w);
    MonomialXYNumDy(E, w);
    MonomialY2NumDx(F, w);
    MonomialY2NumDy(F, w);
    NumDxAdd(pa, pb, pc, pd, pf, pg, ph, pi, Da, Db, Dc, Dd, Df, Dg, Dh, Di);
    NumDyAdd(pa, pb, pc, pd, pf, pg, ph, pi, Da, Db, Dc, Dd, Df, Dg, Dh, Di);
    NumDxAdd(pa + Da, pb + Db, pc + Dc, pd + Dd, pf + Df, pg + Dg, ph + Dh, pi + Di,
             Ea, Eb, Ec, Ed, Ef, Eg, Eh, Ei);
    NumDyAdd(pa + Da, pb + Db, pc + Dc, pd + Dd, pf + Df, pg + Dg, ph + Dh, pi + Di,
             Ea, Eb, Ec, Ed, Ef, Eg, Eh, Ei);
    NumDxAdd(pa + Da + Ea, pb + Db + Eb, pc + Dc + Ec, pd + Dd + Ed,
             pf + Df + Ef, pg + Dg + Eg, ph + Dh + Eh, pi + Di + Ei,
             Fa, Fb, Fc, Fd, Ff, Fg, Fh, Fi);
    NumDyAdd(pa + Da + Ea, pb + Db + Eb, pc + Dc + Ec, pd + Dd + Ed,
             pf + Df + Ef, pg + Dg + Eg, ph + Dh + Eh, pi + Di + Ei,
             Fa, Fb, Fc, Fd, Ff, Fg, Fh, Fi);

    assert NumDx(a, b, c, d, f, g, h, i) == A * (8.0 * w);
    assert NumDy(a, b, c, d, f, g, h, i) == B * (8.0 * w);

    calc {
      DzDx(a, b, c, d, f, g, h, i, w);
      == (A * (8.0 * w)) / (8.0 * w);
      == { DivCancel(A, 8.0 * w); } A;
    }
    calc {
      DzDy(a, b, c, d, f, g, h, i, w);
      == (B * (8.0 * w)) / (8.0 * w);
      == { DivCancel(B, 8.0 * w); } B;
    }
  }

  // ==================================================================
  // GPB-019 · 三次余项 G w²(原点真值 0)
  // ==================================================================
  lemma CubicXRemainder(G: real, w: real)
    requires w > 0.0
    ensures DzDx(
              CubicX(G, w, -1.0), 0.0, CubicX(G, w, 1.0),
              CubicX(G, w, -1.0), CubicX(G, w, 1.0),
              CubicX(G, w, -1.0), 0.0, CubicX(G, w, 1.0), w)
            == G * w * w
  {
    var a := CubicX(G, w, -1.0);
    var c := CubicX(G, w, 1.0);
    var d := CubicX(G, w, -1.0);
    var f := CubicX(G, w, 1.0);
    var g := CubicX(G, w, -1.0);
    var i := CubicX(G, w, 1.0);
    assert a == -G * w * w * w;
    assert c == G * w * w * w;
    assert NumDx(a, 0.0, c, d, f, g, 0.0, i) == 8.0 * G * w * w * w;
    calc {
      DzDx(a, 0.0, c, d, f, g, 0.0, i, w);
      == (8.0 * G * w * w * w) / (8.0 * w);
      == { DivCancel(G * w * w, 8.0 * w); } G * w * w;
    }
  }

  lemma CubicYRemainder(G: real, w: real)
    requires w > 0.0
    ensures DzDy(
              CubicY(G, w, -1.0), CubicY(G, w, -1.0), CubicY(G, w, -1.0),
              0.0, 0.0,
              CubicY(G, w, 1.0), CubicY(G, w, 1.0), CubicY(G, w, 1.0), w)
            == G * w * w
  {
    var a := CubicY(G, w, -1.0);
    var b := CubicY(G, w, -1.0);
    var c := CubicY(G, w, -1.0);
    var g := CubicY(G, w, 1.0);
    var h := CubicY(G, w, 1.0);
    var i := CubicY(G, w, 1.0);
    assert a == -G * w * w * w;
    assert g == G * w * w * w;
    assert NumDy(a, b, c, 0.0, 0.0, g, h, i) == 8.0 * G * w * w * w;
    calc {
      DzDy(a, b, c, 0.0, 0.0, g, h, i, w);
      == (8.0 * G * w * w * w) / (8.0 * w);
      == { DivCancel(G * w * w, 8.0 * w); } G * w * w;
    }
  }

  lemma AbsMulPos(G: real, w: real)
    requires w > 0.0
    ensures Abs(G * w * w) == Abs(G) * (w * w)
  { }

  lemma CubicErrorShrinks(G: real, w1: real, w2: real)
    requires 0.0 < w2 < w1
    ensures Abs(G * w2 * w2) <= Abs(G * w1 * w1)
  {
    AbsMulPos(G, w1);
    AbsMulPos(G, w2);
    assert w2 * w2 < w1 * w1;
    assert Abs(G) * (w2 * w2) <= Abs(G) * (w1 * w1);
  }
}
