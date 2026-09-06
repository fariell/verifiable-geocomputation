/-
  ==========================================================================
   GeoProofBench · P-COMP-3 = ¬(P-003 ⇒ P-004)
   文件 : formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean
   命题 : ZT Hessian 与 Horn 二次斜率不是同一函数族
   对偶 : formal/dafny/PCOMP_3.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

    平面 z = Dx · x 上:ZT Hessian = 0,Horn 斜率 = Dx ≠ 0。
    这是组合命题的边界 witness,不是 P-003 / P-004 的 bug。
    不复制 Curvature / Consistency 核;只引用已证定理。
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.Curvature
import VeriGIS.Consistency
import VeriGIS.HornSlope

namespace VeriGIS.Composition

noncomputable section

structure Witness where
  w : ℝ
  Dx : ℝ
  hw : w ≠ 0
  hDx : Dx ≠ 0

/-- Examples : zt ≠ horn. 同一平面上 Hessian 0,斜率 Dx。 -/
def exampleWitness : Witness :=
  ⟨1, (21 : ℝ) / 100, by norm_num, by norm_num⟩

theorem zt_not_horn (wit : Witness) :
    Curvature.hxx
      (Curvature.quad 0 0 0 wit.Dx 0 0 wit.w (-1) 0)
      (Curvature.quad 0 0 0 wit.Dx 0 0 wit.w 0 0)
      (Curvature.quad 0 0 0 wit.Dx 0 0 wit.w 1 0) wit.w = 0 ∧
    HornSlope.dzdx
      (Consistency.qTL wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qTC wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qTR wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qML wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qMR wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qBL wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qBC wit.Dx 0 0 0 0 0 wit.w)
      (Consistency.qBR wit.Dx 0 0 0 0 0 wit.w) wit.w = wit.Dx ∧
    (0 : ℝ) ≠ wit.Dx := by
  refine ⟨?_, ?_, wit.hDx.symm⟩
  · exact (Curvature.plane_hessian_zero wit.Dx 0 0 wit.w wit.hw).1
  · simpa using Consistency.quadratic_exact_dx wit.Dx 0 0 0 0 0 wit.w wit.hw

theorem examples_zt_ne_horn :
    Curvature.hxx
      (Curvature.quad 0 0 0 exampleWitness.Dx 0 0 exampleWitness.w (-1) 0)
      (Curvature.quad 0 0 0 exampleWitness.Dx 0 0 exampleWitness.w 0 0)
      (Curvature.quad 0 0 0 exampleWitness.Dx 0 0 exampleWitness.w 1 0)
      exampleWitness.w
      ≠
    HornSlope.dzdx
      (Consistency.qTL exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qTC exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qTR exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qML exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qMR exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qBL exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qBC exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      (Consistency.qBR exampleWitness.Dx 0 0 0 0 0 exampleWitness.w)
      exampleWitness.w := by
  have h := zt_not_horn exampleWitness
  rw [h.1, h.2.1]
  exact h.2.2

theorem both_have_slope_ge_zero
    (a b c d f g h i w : ℝ) :
    0 ≤ HornSlope.slopeSq a b c d f g h i w :=
  HornSlope.slopeSq_nonneg a b c d f g h i w

end

end VeriGIS.Composition
