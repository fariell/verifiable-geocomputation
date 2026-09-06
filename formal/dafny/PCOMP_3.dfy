// ===========================================================================
//  GeoProofBench · P-COMP-3 = ¬(P-003 ⇒ P-004)
//  文件 : formal/dafny/PCOMP_3.dfy
//  命题 : ZT Hessian 与 Horn 二次斜率不是同一函数族(否定式 witness)
//  环境 : Dafny 4.11 · dafny verify PCOMP_3.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  include P-003 / P-004 / P-001,不复制 Hessian / Horn / slope 核。
//  平面 z = Dx·x 上:ZT Hessian = 0,Horn 斜率 = Dx ≠ 0。
//  同一 DEM,两侧输出不等 ⇒ 无可形式化的互推。
// ===========================================================================

include "P003_curvature.dfy"
include "P004_consistency.dfy"

module CompositionZTNotHorn {

  import ZT = ZTCurvature
  import Horn = HornConsistency

  // NonEntailed : Witness —— 同一窗口上两侧结果并排放。
  datatype Witness = Witness(w: real, Dx: real)
  type NonEntailed = Witness

  predicate Valid(wit: Witness)
  {
    wit.w > 0.0 && wit.Dx != 0.0
  }

  lemma ztNotHorn(wit: Witness)
    requires Valid(wit)
    ensures ZT.Hxx(ZT.Qd(0.0, 0.0, 0.0, wit.Dx, 0.0, 0.0, wit.w),
                   ZT.Qe(0.0, 0.0, 0.0, wit.Dx, 0.0, 0.0, wit.w),
                   ZT.Qf(0.0, 0.0, 0.0, wit.Dx, 0.0, 0.0, wit.w), wit.w) == 0.0
    ensures Horn.DzDx(
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w, -1.0, -1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  0.0, -1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  1.0, -1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w, -1.0,  0.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  1.0,  0.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w, -1.0,  1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  0.0,  1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  1.0,  1.0),
              wit.w) == wit.Dx
    ensures ZT.Hxx(ZT.Qd(0.0, 0.0, 0.0, wit.Dx, 0.0, 0.0, wit.w),
                   ZT.Qe(0.0, 0.0, 0.0, wit.Dx, 0.0, 0.0, wit.w),
                   ZT.Qf(0.0, 0.0, 0.0, wit.Dx, 0.0, 0.0, wit.w), wit.w)
            != Horn.DzDx(
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w, -1.0, -1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  0.0, -1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  1.0, -1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w, -1.0,  0.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  1.0,  0.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w, -1.0,  1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  0.0,  1.0),
              Horn.Quad(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w,  1.0,  1.0),
              wit.w)
  {
    ZT.PlaneHessianZero(wit.Dx, 0.0, 0.0, wit.w);
    Horn.QuadraticExact(wit.Dx, 0.0, 0.0, 0.0, 0.0, 0.0, wit.w);
  }

  lemma negResult()
    ensures Valid(Witness(1.0, 0.21))
  {
    var wit := Witness(1.0, 0.21);
    ztNotHorn(wit);
  }

  lemma bothHaveSlopeGeZero(a: real, b: real, c: real, d: real, f: real,
                            g: real, h: real, i: real, w: real)
    requires w > 0.0
    ensures Horn.DzDx(a, b, c, d, f, g, h, i, w)
            * Horn.DzDx(a, b, c, d, f, g, h, i, w)
            + Horn.DzDy(a, b, c, d, f, g, h, i, w)
            * Horn.DzDy(a, b, c, d, f, g, h, i, w) >= 0.0
  {
  }
}
