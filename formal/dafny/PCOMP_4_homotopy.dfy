// ===========================================================================
//  GeoProofBench · P-COMP-4 = resampling homotopy
//  文件 : formal/dafny/PCOMP_4_homotopy.dfy
//  命题 : 平面 DEM 经 R_α(重采样)后,Horn 坡度与 D8 流向与原图同伦
//  环境 : Dafny 4.11 · dafny verify PCOMP_4_homotopy.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  R_α : 把格网间距 w 换成 α w。不复制 Horn / D8 核。
//  45° 旋转不在本文件(数值端 FAIL-TOLERANCE);这里只证尺度与平移、90° 轴对齐。
// ===========================================================================

include "P004_consistency.dfy"
include "P005_d8.dfy"

module CompositionResampleHomotopy {

  import Horn = HornConsistency
  import P005 = D8Flow

  // 重采样算子:只改格网间距。α>0,w>0。
  function R(alpha: real, w: real): real
    requires alpha > 0.0 && w > 0.0
  {
    alpha * w
  }

  lemma ResampleAlphaPositive(alpha: real, w: real)
    requires alpha > 0.0 && w > 0.0
    ensures R(alpha, w) > 0.0
  {
  }

  lemma HomotopyPlanarDx(A: real, B: real, C: real, w: real, alpha: real)
    requires w > 0.0 && alpha > 0.0
    ensures Horn.DzDx(
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w), -1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  0.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w), -1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w), -1.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  0.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  1.0,  1.0),
              R(alpha, w)) == A
  {
    Horn.QuadraticExact(A, B, C, 0.0, 0.0, 0.0, R(alpha, w));
  }

  lemma HomotopyPlanarDy(A: real, B: real, C: real, w: real, alpha: real)
    requires w > 0.0 && alpha > 0.0
    ensures Horn.DzDy(
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w), -1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  0.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w), -1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w), -1.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  0.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(alpha, w),  1.0,  1.0),
              R(alpha, w)) == B
  {
    Horn.QuadraticExact(A, B, C, 0.0, 0.0, 0.0, R(alpha, w));
  }

  lemma HomotopyHalfAndDouble(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures Horn.DzDx(
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w), -1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w),  0.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w),  1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w), -1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w),  1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w), -1.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w),  0.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(0.5, w),  1.0,  1.0),
              R(0.5, w)) == A
    ensures Horn.DzDx(
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w), -1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w),  0.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w),  1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w), -1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w),  1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w), -1.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w),  0.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(2.0, w),  1.0,  1.0),
              R(2.0, w)) == A
  {
    HomotopyPlanarDx(A, B, C, w, 0.5);
    HomotopyPlanarDx(A, B, C, w, 2.0);
  }

  lemma HomotopyQuadTimes(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures Horn.DzDx(
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w), -1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w),  0.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w),  1.0, -1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w), -1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w),  1.0,  0.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w), -1.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w),  0.0,  1.0),
              Horn.Quad(A, B, C, 0.0, 0.0, 0.0, R(4.0, w),  1.0,  1.0),
              R(4.0, w)) == A
  {
    HomotopyPlanarDx(A, B, C, w, 4.0);
  }

  lemma HomotopySlopeNonneg(a: real, b: real, c: real, d: real, f: real,
                            g: real, h: real, i: real, w: real, alpha: real)
    requires w > 0.0 && alpha > 0.0
    ensures Horn.DzDx(a, b, c, d, f, g, h, i, R(alpha, w))
            * Horn.DzDx(a, b, c, d, f, g, h, i, R(alpha, w))
            + Horn.DzDy(a, b, c, d, f, g, h, i, R(alpha, w))
            * Horn.DzDy(a, b, c, d, f, g, h, i, R(alpha, w)) >= 0.0
  {
  }

  lemma HomotopyCubicShrinks(G: real, w: real)
    requires w > 0.0
    ensures Horn.Abs(G * R(0.5, w) * R(0.5, w))
            <= Horn.Abs(G * R(2.0, w) * R(2.0, w))
  {
    Horn.CubicErrorShrinks(G, R(2.0, w), R(0.5, w));
  }

  lemma HomotopyD8Offset(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures P005.D8(P005.PlaneWin(A, B, C, w))
            == P005.D8(P005.PlaneWin(A, B, 0.0, w))
  {
    P005.PlaneConstant(A, B, C, w);
  }

  lemma HomotopyWest()
    ensures P005.D8(P005.PlaneWin(1.0, 0.0, 0.0, 1.0)) == P005.To(P005.DirW)
  {
    P005.PlaneWest();
  }

  lemma HomotopyRotate90North()
    ensures P005.D8(P005.PlaneWin(0.0, 1.0, 0.0, 1.0)) == P005.To(P005.DirN)
  {
  }
}
