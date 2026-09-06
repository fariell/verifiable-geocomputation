/-
  ==========================================================================
   GeoProofBench · P-004
   文件 : formal/lean4/VeriGIS/Consistency.lean
   算子 : Horn 坡度在二次面上精确、三次余项 O(w²) → 0
   对偶 : formal/dafny/P004_consistency.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  Dafny 用单项式把 SMT 钉在多项式恒等上。Lean 多一条真正的 w → 0:
  `Tendsto (fun w ↦ G * w^2) (nhds 0) (nhds 0)`。
  不证任意 C² 曲面;那需要余项公式 + 一致有界三阶导,另开题。

    GPB-019  quadratic_exact  次数 ≤2 无余项
    GPB-019  cubicX_remainder DzDx = G w²
    GPB-019  cubic_error_tendsto_zero
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.HornSlope

namespace VeriGIS.Consistency

open VeriGIS.HornSlope
open Filter Topology

noncomputable section

def quad (A B C D E F w p q : ℝ) : ℝ :=
  A * (p * w) + B * (q * w) + C
    + D * (p * w) ^ 2
    + E * (p * w) * (q * w)
    + F * (q * w) ^ 2

def qTL (A B C D E F w : ℝ) : ℝ := quad A B C D E F w (-1) (-1)
def qTC (A B C D E F w : ℝ) : ℝ := quad A B C D E F w 0 (-1)
def qTR (A B C D E F w : ℝ) : ℝ := quad A B C D E F w 1 (-1)
def qML (A B C D E F w : ℝ) : ℝ := quad A B C D E F w (-1) 0
def qMR (A B C D E F w : ℝ) : ℝ := quad A B C D E F w 1 0
def qBL (A B C D E F w : ℝ) : ℝ := quad A B C D E F w (-1) 1
def qBC (A B C D E F w : ℝ) : ℝ := quad A B C D E F w 0 1
def qBR (A B C D E F w : ℝ) : ℝ := quad A B C D E F w 1 1

def cubicX (G w p : ℝ) : ℝ := G * (p * w) ^ 3

-- ==========================================================================
-- GPB-019 · 二次面精确
-- ==========================================================================

theorem quadratic_exact_dx (A B C D E F w : ℝ) (hw : w ≠ 0) :
    dzdx (qTL A B C D E F w) (qTC A B C D E F w) (qTR A B C D E F w)
         (qML A B C D E F w) (qMR A B C D E F w)
         (qBL A B C D E F w) (qBC A B C D E F w) (qBR A B C D E F w) w = A := by
  unfold dzdx numDx
  simp only [qTL, qTC, qTR, qML, qMR, qBL, qBC, qBR, quad]
  field_simp [eight_mul_ne_zero hw]
  ring

theorem quadratic_exact_dy (A B C D E F w : ℝ) (hw : w ≠ 0) :
    dzdy (qTL A B C D E F w) (qTC A B C D E F w) (qTR A B C D E F w)
         (qML A B C D E F w) (qMR A B C D E F w)
         (qBL A B C D E F w) (qBC A B C D E F w) (qBR A B C D E F w) w = B := by
  unfold dzdy numDy
  simp only [qTL, qTC, qTR, qML, qMR, qBL, qBC, qBR, quad]
  field_simp [eight_mul_ne_zero hw]
  ring

theorem quadratic_exact (A B C D E F w : ℝ) (hw : w ≠ 0) :
    dzdx (qTL A B C D E F w) (qTC A B C D E F w) (qTR A B C D E F w)
         (qML A B C D E F w) (qMR A B C D E F w)
         (qBL A B C D E F w) (qBC A B C D E F w) (qBR A B C D E F w) w = A ∧
    dzdy (qTL A B C D E F w) (qTC A B C D E F w) (qTR A B C D E F w)
         (qML A B C D E F w) (qMR A B C D E F w)
         (qBL A B C D E F w) (qBC A B C D E F w) (qBR A B C D E F w) w = B :=
  ⟨quadratic_exact_dx A B C D E F w hw, quadratic_exact_dy A B C D E F w hw⟩

-- ==========================================================================
-- GPB-019 · 三次余项 G w²,且 w → 0 时 → 0
-- ==========================================================================

theorem cubicX_remainder (G w : ℝ) (hw : w ≠ 0) :
    dzdx (cubicX G w (-1)) 0 (cubicX G w 1)
         (cubicX G w (-1)) (cubicX G w 1)
         (cubicX G w (-1)) 0 (cubicX G w 1) w
      = G * w ^ 2 := by
  unfold dzdx numDx cubicX
  field_simp [eight_mul_ne_zero hw]
  ring

theorem cubic_error_tendsto_zero (G : ℝ) :
    Tendsto (fun w : ℝ => G * w ^ 2) (nhds 0) (nhds 0) := by
  have h : Continuous fun w : ℝ => G * w ^ 2 := by continuity
  simpa using h.tendsto 0

theorem cubic_error_shrinks {G w1 w2 : ℝ} (hw2 : 0 < w2) (hlt : w2 < w1) :
    |G * w2 ^ 2| ≤ |G * w1 ^ 2| := by
  have hsq : w2 ^ 2 ≤ w1 ^ 2 := by nlinarith
  rw [abs_mul, abs_mul, abs_of_nonneg (sq_nonneg w2), abs_of_nonneg (sq_nonneg w1)]
  exact mul_le_mul_of_nonneg_left hsq (abs_nonneg G)

end

end VeriGIS.Consistency
