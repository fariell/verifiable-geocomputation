// ===========================================================================
//  GeoProofBench · P-003
//  文件 : formal/dafny/P003_curvature.dfy
//  算子 : Zevenbergen & Thorne (1987) / Evans (1980) 3x3 二阶差分(Hessian)
//  覆盖 : GPB-007(二次凸包上精确)、GPB-005 的可证核(离散极大 → Laplacian≤0)、
//         中心元 e 的 1/w² 噪声放大、Phase 1 错误模板把 Hxx/Hyy 互换
//  环境 : Dafny 4.11 · 验证命令 dafny verify P003_curvature.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么曲率不能抄 P-001 的"渐近一致"
//  ------------------------------------
//  Phase 1 在合成 DEM 上测到 profile curvature corr ≈ 0.157,坡度 corr > 0.999。
//  GPB-020("离散剖面曲率在 w→0 时收敛到解析值")不能当第一引理——入口实验
//  已经表明它在 1 m 网格上不成立,且 dx=0.5 时 corr 会跳到 ~0.9(尺度依赖)。
//
//  本文件只证**代数上为真**的核:
//    1. 二次面 z = A x² + B y² + C xy + Dx + Ey + F 上,ZT Hessian **恒等**
//       恢复 (2A, 2B, C)。这是 GPB-007 的离散版,对偶于 P-001 的 PlanarExact。
//    2. 离散局部极大(中心不低于四邻) ⇒ Laplacian ≤ 0。不碰剖面曲率在驻点
//       的 0/0,也不采用 GIS 里互相打架的符号约定。
//    3. 中心高程扰动 δ 使 Hxx 改变 -2δ/w² —— 这是 corr=0.157 的噪声机制。
//    4. Phase 1 `experiment.py` 的"Hxx"模板在二次面上精确恢复的是 2B 不是
//       2A:轴被换了。0.157 不全是"二阶病态",有一部分是模板写反。
//
//  不证:GPB-020 的一般 C² 收敛;剖面曲率在梯度为零处的符号。
//
// ===========================================================================

module ZTCurvature {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(与 P-001 相同:p 向右,q 向下)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Zevenbergen–Thorne 二次拟合给出:
  //   ∂²z/∂x² = (d - 2e + f) / w²     (中行,含中心 e)
  //   ∂²z/∂y² = (b - 2e + h) / w²     (中列,含中心 e)
  //   ∂²z/∂x∂y = (a - c - g + i) / (4 w²)
  // ------------------------------------------------------------------

  function NumHxx(d: real, e: real, f: real): real
  { d - 2.0 * e + f }

  function NumHyy(b: real, e: real, h: real): real
  { b - 2.0 * e + h }

  function NumHxy(a: real, c: real, g: real, i: real): real
  { a - c - g + i }

  // 写成两次 /w,不写 / (w*w):SMT 从 w>0 推不出 w*w≠0(非线性),
  // 但能从 w>0 推出单次除法合法。与 P-001 的 / (8*w) 同一套路。
  function Hxx(d: real, e: real, f: real, w: real): real
    requires w > 0.0
  { (NumHxx(d, e, f) / w) / w }

  function Hyy(b: real, e: real, h: real, w: real): real
    requires w > 0.0
  { (NumHyy(b, e, h) / w) / w }

  function Hxy(a: real, c: real, g: real, i: real, w: real): real
    requires w > 0.0
  { (NumHxy(a, c, g, i) / (4.0 * w)) / w }

  function Laplacian(b: real, d: real, e: real, f: real, h: real, w: real): real
    requires w > 0.0
  { Hxx(d, e, f, w) + Hyy(b, e, h, w) }

  // Phase 1 experiment.py 误把左列二阶 y 差分叫做 d2zdx2。
  function Phase1WrongHxx(a: real, d: real, g: real, w: real): real
    requires w > 0.0
  { ((a - 2.0 * d + g) / w) / w }

  function Phase1WrongHyy(a: real, b: real, c: real, w: real): real
    requires w > 0.0
  { ((a - 2.0 * b + c) / w) / w }

  lemma DivCancel(x: real, y: real)
    requires y != 0.0
    ensures (x * y) / y == x
  { }

  lemma MulAssocR(x: real, w: real)
    ensures x * (w * w) == (x * w) * w
  { }

  lemma NegWSq(w: real)
    ensures ((-1.0) * w) * ((-1.0) * w) == w * w
  { }

  lemma MulNeg1(x: real, w: real)
    ensures x * ((-1.0) * w) == -(x * w)
  { }

  lemma DivTwice(x: real, w: real)
    requires w > 0.0
    ensures ((x * (w * w)) / w) / w == x
  {
    MulAssocR(x, w);
    assert x * (w * w) == (x * w) * w;
    assert (x * (w * w)) / w == ((x * w) * w) / w;
    DivCancel(x * w, w);
    assert ((x * w) * w) / w == x * w;
    assert (x * (w * w)) / w == x * w;
    DivCancel(x, w);
    assert (x * w) / w == x;
    assert ((x * (w * w)) / w) / w == (x * w) / w;
  }

  lemma HxxFromNum(d: real, e: real, f: real, w: real, x: real)
    requires w > 0.0
    requires NumHxx(d, e, f) == x * (w * w)
    ensures Hxx(d, e, f, w) == x
  {
    calc {
      Hxx(d, e, f, w);
      == (NumHxx(d, e, f) / w) / w;
      == ((x * (w * w)) / w) / w;
      == { DivTwice(x, w); }
      x;
    }
  }

  lemma HyyFromNum(b: real, e: real, h: real, w: real, x: real)
    requires w > 0.0
    requires NumHyy(b, e, h) == x * (w * w)
    ensures Hyy(b, e, h, w) == x
  {
    calc {
      Hyy(b, e, h, w);
      == (NumHyy(b, e, h) / w) / w;
      == ((x * (w * w)) / w) / w;
      == { DivTwice(x, w); }
      x;
    }
  }

  lemma HxyFromNum(a: real, c: real, g: real, i: real, w: real, Cxy: real)
    requires w > 0.0
    requires NumHxy(a, c, g, i) == (Cxy * w) * (4.0 * w)
    ensures Hxy(a, c, g, i, w) == Cxy
  {
    calc {
      (Cxy * w) * (4.0 * w) / (4.0 * w);
      == { DivCancel(Cxy * w, 4.0 * w); }
      Cxy * w;
    }
    calc {
      Hxy(a, c, g, i, w);
      == (NumHxy(a, c, g, i) / (4.0 * w)) / w;
      == (((Cxy * w) * (4.0 * w)) / (4.0 * w)) / w;
      == (Cxy * w) / w;
      == { DivCancel(Cxy, w); }
      Cxy;
    }
  }

  lemma WrongHxxFromNum(a: real, d: real, g: real, w: real, x: real)
    requires w > 0.0
    requires a - 2.0 * d + g == x * (w * w)
    ensures Phase1WrongHxx(a, d, g, w) == x
  {
    calc {
      Phase1WrongHxx(a, d, g, w);
      == ((a - 2.0 * d + g) / w) / w;
      == ((x * (w * w)) / w) / w;
      == { DivTwice(x, w); }
      x;
    }
  }

  lemma WrongHyyFromNum(a: real, b: real, c: real, w: real, x: real)
    requires w > 0.0
    requires a - 2.0 * b + c == x * (w * w)
    ensures Phase1WrongHyy(a, b, c, w) == x
  {
    calc {
      Phase1WrongHyy(a, b, c, w);
      == ((a - 2.0 * b + c) / w) / w;
      == ((x * (w * w)) / w) / w;
      == { DivTwice(x, w); }
      x;
    }
  }

  lemma DivAdd(x: real, y: real, w: real)
    requires w > 0.0
    ensures x / w + y / w == (x + y) / w
  { }

  lemma DivSub(x: real, y: real, w: real)
    requires w > 0.0
    ensures (x - y) / w == x / w - y / w
  { }

  lemma DivNonpos(x: real, w: real)
    requires w > 0.0
    requires x <= 0.0
    ensures x / w <= 0.0
  { }

  // 二次面 z = A x² + B y² + Cxy xy + Dx x + Ey y + F0,采样于 (p w, q w)
  function Quad(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real,
                w: real, p: real, q: real): real
  {
    A * (p * p) * (w * w) + B * (q * q) * (w * w) + Cxy * (p * q) * (w * w)
      + Dx * (p * w) + Ey * (q * w) + F0
  }

  function Qa(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w, -1.0, -1.0) }
  function Qb(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w,  0.0, -1.0) }
  function Qc(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w,  1.0, -1.0) }
  function Qd(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w, -1.0,  0.0) }
  function Qe(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w,  0.0,  0.0) }
  function Qf(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w,  1.0,  0.0) }
  function Qg(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w, -1.0,  1.0) }
  function Qh(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w,  0.0,  1.0) }
  function Qi(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real): real
  { Quad(A, B, Cxy, Dx, Ey, F0, w,  1.0,  1.0) }

  lemma ExpandE(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qe(A,B,Cxy,Dx,Ey,F0,w) == F0
  {
    assert 0.0 * 0.0 == 0.0;
    assert 0.0 * w == 0.0;
  }

  lemma ExpandD(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qd(A,B,Cxy,Dx,Ey,F0,w) == A * (w * w) - Dx * w + F0
  {
    assert (-1.0) * (-1.0) == 1.0;
    assert (-1.0) * 0.0 == 0.0;
    assert 0.0 * 0.0 == 0.0;
    NegWSq(w);
    MulNeg1(Dx, w);
  }

  lemma ExpandF(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qf(A,B,Cxy,Dx,Ey,F0,w) == A * (w * w) + Dx * w + F0
  {
    assert 1.0 * 1.0 == 1.0;
    assert 1.0 * 0.0 == 0.0;
    assert 0.0 * 0.0 == 0.0;
    assert 1.0 * w == w;
  }

  lemma ExpandB(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qb(A,B,Cxy,Dx,Ey,F0,w) == B * (w * w) - Ey * w + F0
  {
    assert 0.0 * 0.0 == 0.0;
    assert 0.0 * (-1.0) == 0.0;
    assert (-1.0) * (-1.0) == 1.0;
    NegWSq(w);
    MulNeg1(Ey, w);
  }

  lemma ExpandH(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qh(A,B,Cxy,Dx,Ey,F0,w) == B * (w * w) + Ey * w + F0
  {
    assert 0.0 * 0.0 == 0.0;
    assert 0.0 * 1.0 == 0.0;
    assert 1.0 * 1.0 == 1.0;
    assert 1.0 * w == w;
  }

  lemma ExpandA(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qa(A,B,Cxy,Dx,Ey,F0,w)
            == (A + B + Cxy) * (w * w) - Dx * w - Ey * w + F0
  {
    assert (-1.0) * (-1.0) == 1.0;
    NegWSq(w);
    MulNeg1(Dx, w);
    MulNeg1(Ey, w);
  }

  lemma ExpandC(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qc(A,B,Cxy,Dx,Ey,F0,w)
            == (A + B - Cxy) * (w * w) + Dx * w - Ey * w + F0
  {
    assert 1.0 * 1.0 == 1.0;
    assert 1.0 * (-1.0) == -1.0;
    assert (-1.0) * (-1.0) == 1.0;
    NegWSq(w);
    MulNeg1(Ey, w);
  }

  lemma ExpandG(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qg(A,B,Cxy,Dx,Ey,F0,w)
            == (A + B - Cxy) * (w * w) - Dx * w + Ey * w + F0
  {
    assert (-1.0) * (-1.0) == 1.0;
    assert (-1.0) * 1.0 == -1.0;
    assert 1.0 * 1.0 == 1.0;
    NegWSq(w);
    MulNeg1(Dx, w);
  }

  lemma ExpandI(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    ensures Qi(A,B,Cxy,Dx,Ey,F0,w)
            == (A + B + Cxy) * (w * w) + Dx * w + Ey * w + F0
  {
    assert 1.0 * 1.0 == 1.0;
  }

  // ==================================================================
  // GPB-007 · 二次面上 Hessian 精确(不是渐近,是恒等)
  // 旋转抛物面 h = F0 - k (x²+y²) 是特例 A=B=-k, Cxy=0 → Hxx=Hyy=-2k
  // ==================================================================
  lemma QuadraticExact(A: real, B: real, Cxy: real, Dx: real, Ey: real, F0: real, w: real)
    requires w > 0.0
    ensures Hxx(Qd(A,B,Cxy,Dx,Ey,F0,w), Qe(A,B,Cxy,Dx,Ey,F0,w), Qf(A,B,Cxy,Dx,Ey,F0,w), w)
            == 2.0 * A
    ensures Hyy(Qb(A,B,Cxy,Dx,Ey,F0,w), Qe(A,B,Cxy,Dx,Ey,F0,w), Qh(A,B,Cxy,Dx,Ey,F0,w), w)
            == 2.0 * B
    ensures Hxy(Qa(A,B,Cxy,Dx,Ey,F0,w), Qc(A,B,Cxy,Dx,Ey,F0,w),
                Qg(A,B,Cxy,Dx,Ey,F0,w), Qi(A,B,Cxy,Dx,Ey,F0,w), w)
            == Cxy
  {
    ExpandD(A,B,Cxy,Dx,Ey,F0,w);
    ExpandE(A,B,Cxy,Dx,Ey,F0,w);
    ExpandF(A,B,Cxy,Dx,Ey,F0,w);
    ExpandB(A,B,Cxy,Dx,Ey,F0,w);
    ExpandH(A,B,Cxy,Dx,Ey,F0,w);
    ExpandA(A,B,Cxy,Dx,Ey,F0,w);
    ExpandC(A,B,Cxy,Dx,Ey,F0,w);
    ExpandG(A,B,Cxy,Dx,Ey,F0,w);
    ExpandI(A,B,Cxy,Dx,Ey,F0,w);

    assert NumHxx(Qd(A,B,Cxy,Dx,Ey,F0,w), Qe(A,B,Cxy,Dx,Ey,F0,w), Qf(A,B,Cxy,Dx,Ey,F0,w))
           == (2.0 * A) * (w * w);
    assert NumHyy(Qb(A,B,Cxy,Dx,Ey,F0,w), Qe(A,B,Cxy,Dx,Ey,F0,w), Qh(A,B,Cxy,Dx,Ey,F0,w))
           == (2.0 * B) * (w * w);
    assert NumHxy(Qa(A,B,Cxy,Dx,Ey,F0,w), Qc(A,B,Cxy,Dx,Ey,F0,w),
                  Qg(A,B,Cxy,Dx,Ey,F0,w), Qi(A,B,Cxy,Dx,Ey,F0,w))
           == (Cxy * w) * (4.0 * w);

    HxxFromNum(Qd(A,B,Cxy,Dx,Ey,F0,w), Qe(A,B,Cxy,Dx,Ey,F0,w), Qf(A,B,Cxy,Dx,Ey,F0,w),
               w, 2.0 * A);
    HyyFromNum(Qb(A,B,Cxy,Dx,Ey,F0,w), Qe(A,B,Cxy,Dx,Ey,F0,w), Qh(A,B,Cxy,Dx,Ey,F0,w),
               w, 2.0 * B);
    HxyFromNum(Qa(A,B,Cxy,Dx,Ey,F0,w), Qc(A,B,Cxy,Dx,Ey,F0,w),
               Qg(A,B,Cxy,Dx,Ey,F0,w), Qi(A,B,Cxy,Dx,Ey,F0,w), w, Cxy);
  }

  lemma ParaboloidApex(k: real, F0: real, w: real)
    requires w > 0.0
    ensures Hxx(Qd(-k,-k,0.0,0.0,0.0,F0,w), Qe(-k,-k,0.0,0.0,0.0,F0,w),
                Qf(-k,-k,0.0,0.0,0.0,F0,w), w) == -2.0 * k
    ensures Hyy(Qb(-k,-k,0.0,0.0,0.0,F0,w), Qe(-k,-k,0.0,0.0,0.0,F0,w),
                Qh(-k,-k,0.0,0.0,0.0,F0,w), w) == -2.0 * k
    ensures Hxy(Qa(-k,-k,0.0,0.0,0.0,F0,w), Qc(-k,-k,0.0,0.0,0.0,F0,w),
                Qg(-k,-k,0.0,0.0,0.0,F0,w), Qi(-k,-k,0.0,0.0,0.0,F0,w), w) == 0.0
  {
    QuadraticExact(-k, -k, 0.0, 0.0, 0.0, F0, w);
  }

  lemma PlaneHessianZero(Dx: real, Ey: real, F0: real, w: real)
    requires w > 0.0
    ensures Hxx(Qd(0.0,0.0,0.0,Dx,Ey,F0,w), Qe(0.0,0.0,0.0,Dx,Ey,F0,w),
                Qf(0.0,0.0,0.0,Dx,Ey,F0,w), w) == 0.0
    ensures Hyy(Qb(0.0,0.0,0.0,Dx,Ey,F0,w), Qe(0.0,0.0,0.0,Dx,Ey,F0,w),
                Qh(0.0,0.0,0.0,Dx,Ey,F0,w), w) == 0.0
    ensures Hxy(Qa(0.0,0.0,0.0,Dx,Ey,F0,w), Qc(0.0,0.0,0.0,Dx,Ey,F0,w),
                Qg(0.0,0.0,0.0,Dx,Ey,F0,w), Qi(0.0,0.0,0.0,Dx,Ey,F0,w), w) == 0.0
  {
    QuadraticExact(0.0, 0.0, 0.0, Dx, Ey, F0, w);
  }

  // ==================================================================
  // GPB-005 的可证核 · 离散局部极大 ⇒ Laplacian ≤ 0
  // 剖面曲率在驻点是 0/0,本引理只谈 Hessian 迹。
  // ==================================================================
  lemma LaplacianAtDiscreteMax(b: real, d: real, e: real, f: real, h: real, w: real)
    requires w > 0.0
    requires e >= b && e >= d && e >= f && e >= h
    ensures Laplacian(b, d, e, f, h, w) <= 0.0
  {
    assert NumHxx(d, e, f) + NumHyy(b, e, h) == (b + d + f + h) - 4.0 * e;
    assert (b + d + f + h) - 4.0 * e <= 0.0;
    calc {
      Laplacian(b, d, e, f, h, w);
      == Hxx(d, e, f, w) + Hyy(b, e, h, w);
      == (NumHxx(d, e, f) / w) / w + (NumHyy(b, e, h) / w) / w;
      == { DivAdd(NumHxx(d, e, f) / w, NumHyy(b, e, h) / w, w); }
      ((NumHxx(d, e, f) / w) + (NumHyy(b, e, h) / w)) / w;
      == { DivAdd(NumHxx(d, e, f), NumHyy(b, e, h), w); }
      ((NumHxx(d, e, f) + NumHyy(b, e, h)) / w) / w;
    }
    assert ((NumHxx(d, e, f) + NumHyy(b, e, h)) / w) / w
           == (((b + d + f + h) - 4.0 * e) / w) / w;
    DivNonpos((b + d + f + h) - 4.0 * e, w);
    DivNonpos(((b + d + f + h) - 4.0 * e) / w, w);
  }

  // ==================================================================
  // 中心元噪声: e ↦ e+δ 使 Hxx 改变 -2δ/w²
  // ==================================================================
  lemma CenterPerturbHxx(d: real, e: real, f: real, w: real, delta: real)
    requires w > 0.0
    ensures Hxx(d, e + delta, f, w) == Hxx(d, e, f, w) - ((2.0 * delta) / w) / w
  {
    assert NumHxx(d, e + delta, f) == NumHxx(d, e, f) - 2.0 * delta;
    calc {
      Hxx(d, e + delta, f, w);
      == (NumHxx(d, e + delta, f) / w) / w;
      == ((NumHxx(d, e, f) - 2.0 * delta) / w) / w;
      == { DivSub(NumHxx(d, e, f), 2.0 * delta, w); }
      (NumHxx(d, e, f) / w - (2.0 * delta) / w) / w;
      == { DivSub(NumHxx(d, e, f) / w, (2.0 * delta) / w, w); }
      (NumHxx(d, e, f) / w) / w - ((2.0 * delta) / w) / w;
      == Hxx(d, e, f, w) - ((2.0 * delta) / w) / w;
    }
  }

  lemma TranslationInvariant(a: real, b: real, c: real, d: real, e: real,
                             f: real, g: real, h: real, i: real, w: real, K: real)
    requires w > 0.0
    ensures Hxx(d + K, e + K, f + K, w) == Hxx(d, e, f, w)
    ensures Hyy(b + K, e + K, h + K, w) == Hyy(b, e, h, w)
    ensures Hxy(a + K, c + K, g + K, i + K, w) == Hxy(a, c, g, i, w)
  {
    assert NumHxx(d + K, e + K, f + K) == NumHxx(d, e, f);
    assert NumHyy(b + K, e + K, h + K) == NumHyy(b, e, h);
    assert NumHxy(a + K, c + K, g + K, i + K) == NumHxy(a, c, g, i);
  }

  // ==================================================================
  // Phase 1 错误模板:左列二阶差分在二次面上恢复的是 2B(=Hyy),不是 2A
  // ==================================================================
  lemma Phase1StencilSwapsAxes(A: real, B: real, Cxy: real, Dx: real, Ey: real,
                               F0: real, w: real)
    requires w > 0.0
    ensures Phase1WrongHxx(Qa(A,B,Cxy,Dx,Ey,F0,w), Qd(A,B,Cxy,Dx,Ey,F0,w),
                           Qg(A,B,Cxy,Dx,Ey,F0,w), w) == 2.0 * B
    ensures Phase1WrongHyy(Qa(A,B,Cxy,Dx,Ey,F0,w), Qb(A,B,Cxy,Dx,Ey,F0,w),
                           Qc(A,B,Cxy,Dx,Ey,F0,w), w) == 2.0 * A
  {
    ExpandA(A,B,Cxy,Dx,Ey,F0,w);
    ExpandD(A,B,Cxy,Dx,Ey,F0,w);
    ExpandG(A,B,Cxy,Dx,Ey,F0,w);
    ExpandB(A,B,Cxy,Dx,Ey,F0,w);
    ExpandC(A,B,Cxy,Dx,Ey,F0,w);
    assert Qa(A,B,Cxy,Dx,Ey,F0,w) - 2.0 * Qd(A,B,Cxy,Dx,Ey,F0,w)
           + Qg(A,B,Cxy,Dx,Ey,F0,w) == (2.0 * B) * (w * w);
    assert Qa(A,B,Cxy,Dx,Ey,F0,w) - 2.0 * Qb(A,B,Cxy,Dx,Ey,F0,w)
           + Qc(A,B,Cxy,Dx,Ey,F0,w) == (2.0 * A) * (w * w);
    WrongHxxFromNum(Qa(A,B,Cxy,Dx,Ey,F0,w), Qd(A,B,Cxy,Dx,Ey,F0,w),
                    Qg(A,B,Cxy,Dx,Ey,F0,w), w, 2.0 * B);
    WrongHyyFromNum(Qa(A,B,Cxy,Dx,Ey,F0,w), Qb(A,B,Cxy,Dx,Ey,F0,w),
                    Qc(A,B,Cxy,Dx,Ey,F0,w), w, 2.0 * A);
  }
}

method Main() {
  print "GeoProofBench P-003 — ZT Hessian: quadratic exact + Laplacian + stencil swap\n";
  print "全部由编译期验证:dafny verify P003_curvature.dfy\n";
}
