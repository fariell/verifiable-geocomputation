/-
  ==========================================================================
   GeoProofBench · P-003
   文件 : formal/lean4/VeriGIS/Curvature.lean
   算子 : Zevenbergen & Thorne (1987) 3×3 Hessian
   对偶 : formal/dafny/P003_curvature.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  独立重述,不是翻译。Dafny 把 9 个采样点写成命名函数 Qa…Qi,靠 SMT 消二次式;
  Lean 直接 unfold `quad` 后 `field_simp; ring`。两边都只证 Hessian,不证
  剖面曲率在驻点的符号(0/0 + GIS 符号公约分裂)。

  覆盖:
    GPB-007  二次面 / 旋转抛物面顶点 Hessian 精确
    GPB-005  的可证核:离散局部极大 ⇒ Laplacian ≤ 0
    中心扰动 -2δ/w²
    Phase 1 错误模板互换 Hxx/Hyy
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.Curvature

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下),与 `HornSlope` / Dafny P-001 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1,  0)     e        f( 1,  0)
      g(-1,  1)   h( 0,  1)   i( 1,  1)
-/

def numHxx (d e f : ℝ) : ℝ := d - 2 * e + f
def numHyy (b e h : ℝ) : ℝ := b - 2 * e + h
def numHxy (a c g i : ℝ) : ℝ := a - c - g + i

def hxx (d e f w : ℝ) : ℝ := numHxx d e f / w ^ 2
def hyy (b e h w : ℝ) : ℝ := numHyy b e h / w ^ 2
def hxy (a c g i w : ℝ) : ℝ := numHxy a c g i / (4 * w ^ 2)

def laplacian (b d e f h w : ℝ) : ℝ := hxx d e f w + hyy b e h w

/-- Phase 1 `experiment.py` 把左列二阶差分标成 d2zdx2。 -/
def phase1WrongHxx (a d g w : ℝ) : ℝ := (a - 2 * d + g) / w ^ 2
def phase1WrongHyy (a b c w : ℝ) : ℝ := (a - 2 * b + c) / w ^ 2

def quad (A B Cxy Dx Ey F0 w p q : ℝ) : ℝ :=
  A * (p * w) ^ 2 + B * (q * w) ^ 2 + Cxy * (p * w) * (q * w)
    + Dx * (p * w) + Ey * (q * w) + F0

lemma sq_ne_zero {w : ℝ} (hw : w ≠ 0) : w ^ 2 ≠ 0 :=
  pow_ne_zero 2 hw

lemma four_sq_ne_zero {w : ℝ} (hw : w ≠ 0) : (4 : ℝ) * w ^ 2 ≠ 0 :=
  mul_ne_zero (by norm_num) (sq_ne_zero hw)

-- ==========================================================================
-- GPB-007 · 二次面上 Hessian 精确
-- ==========================================================================

theorem quadratic_hxx
    (A B Cxy Dx Ey F0 w : ℝ) (hw : w ≠ 0) :
    hxx (quad A B Cxy Dx Ey F0 w (-1) 0)
        (quad A B Cxy Dx Ey F0 w 0 0)
        (quad A B Cxy Dx Ey F0 w 1 0) w = 2 * A := by
  unfold hxx numHxx quad
  field_simp [sq_ne_zero hw]
  ring

theorem quadratic_hyy
    (A B Cxy Dx Ey F0 w : ℝ) (hw : w ≠ 0) :
    hyy (quad A B Cxy Dx Ey F0 w 0 (-1))
        (quad A B Cxy Dx Ey F0 w 0 0)
        (quad A B Cxy Dx Ey F0 w 0 1) w = 2 * B := by
  unfold hyy numHyy quad
  field_simp [sq_ne_zero hw]
  ring

theorem quadratic_hxy
    (A B Cxy Dx Ey F0 w : ℝ) (hw : w ≠ 0) :
    hxy (quad A B Cxy Dx Ey F0 w (-1) (-1))
        (quad A B Cxy Dx Ey F0 w 1 (-1))
        (quad A B Cxy Dx Ey F0 w (-1) 1)
        (quad A B Cxy Dx Ey F0 w 1 1) w = Cxy := by
  unfold hxy numHxy quad
  field_simp [four_sq_ne_zero hw]
  ring

theorem paraboloid_apex (k F0 w : ℝ) (hw : w ≠ 0) :
    hxx (quad (-k) (-k) 0 0 0 F0 w (-1) 0)
        (quad (-k) (-k) 0 0 0 F0 w 0 0)
        (quad (-k) (-k) 0 0 0 F0 w 1 0) w = -2 * k ∧
    hyy (quad (-k) (-k) 0 0 0 F0 w 0 (-1))
        (quad (-k) (-k) 0 0 0 F0 w 0 0)
        (quad (-k) (-k) 0 0 0 F0 w 0 1) w = -2 * k ∧
    hxy (quad (-k) (-k) 0 0 0 F0 w (-1) (-1))
        (quad (-k) (-k) 0 0 0 F0 w 1 (-1))
        (quad (-k) (-k) 0 0 0 F0 w (-1) 1)
        (quad (-k) (-k) 0 0 0 F0 w 1 1) w = 0 := by
  refine ⟨?_, ?_, ?_⟩
  · simpa using quadratic_hxx (-k) (-k) 0 0 0 F0 w hw
  · simpa using quadratic_hyy (-k) (-k) 0 0 0 F0 w hw
  · simpa using quadratic_hxy (-k) (-k) 0 0 0 F0 w hw

theorem plane_hessian_zero (Dx Ey F0 w : ℝ) (hw : w ≠ 0) :
    hxx (quad 0 0 0 Dx Ey F0 w (-1) 0)
        (quad 0 0 0 Dx Ey F0 w 0 0)
        (quad 0 0 0 Dx Ey F0 w 1 0) w = 0 ∧
    hyy (quad 0 0 0 Dx Ey F0 w 0 (-1))
        (quad 0 0 0 Dx Ey F0 w 0 0)
        (quad 0 0 0 Dx Ey F0 w 0 1) w = 0 ∧
    hxy (quad 0 0 0 Dx Ey F0 w (-1) (-1))
        (quad 0 0 0 Dx Ey F0 w 1 (-1))
        (quad 0 0 0 Dx Ey F0 w (-1) 1)
        (quad 0 0 0 Dx Ey F0 w 1 1) w = 0 := by
  refine ⟨?_, ?_, ?_⟩
  · simpa using quadratic_hxx 0 0 0 Dx Ey F0 w hw
  · simpa using quadratic_hyy 0 0 0 Dx Ey F0 w hw
  · simpa using quadratic_hxy 0 0 0 Dx Ey F0 w hw

-- ==========================================================================
-- GPB-005 核 · 离散局部极大 ⇒ Laplacian ≤ 0
-- ==========================================================================

theorem laplacian_nonpos_of_discrete_max
    (b d e f h w : ℝ) (hw : w ≠ 0)
    (hb : e ≥ b) (hd : e ≥ d) (hf : e ≥ f) (hh : e ≥ h) :
    laplacian b d e f h w ≤ 0 := by
  have hw2 : (0 : ℝ) < w ^ 2 := sq_pos_of_ne_zero hw
  unfold laplacian hxx hyy numHxx numHyy
  rw [div_add_div_same]
  have : d - 2 * e + f + (b - 2 * e + h) = b + d + f + h - 4 * e := by ring
  rw [this]
  exact div_nonpos_of_nonpos_of_nonneg (by nlinarith [hb, hd, hf, hh]) hw2.le

-- ==========================================================================
-- 中心扰动与平移
-- ==========================================================================

theorem center_perturb_hxx (d e f w δ : ℝ) (hw : w ≠ 0) :
    hxx d (e + δ) f w = hxx d e f w - 2 * δ / w ^ 2 := by
  unfold hxx numHxx
  field_simp [sq_ne_zero hw]
  ring

theorem translation_hxx (d e f w K : ℝ) :
    hxx (d + K) (e + K) (f + K) w = hxx d e f w := by
  unfold hxx numHxx
  ring

-- ==========================================================================
-- Phase 1 错误模板互换坐标轴
-- ==========================================================================

theorem phase1_wrong_hxx_is_hyy
    (A B Cxy Dx Ey F0 w : ℝ) (hw : w ≠ 0) :
    phase1WrongHxx
      (quad A B Cxy Dx Ey F0 w (-1) (-1))
      (quad A B Cxy Dx Ey F0 w (-1) 0)
      (quad A B Cxy Dx Ey F0 w (-1) 1) w = 2 * B := by
  unfold phase1WrongHxx quad
  field_simp [sq_ne_zero hw]
  ring

theorem phase1_wrong_hyy_is_hxx
    (A B Cxy Dx Ey F0 w : ℝ) (hw : w ≠ 0) :
    phase1WrongHyy
      (quad A B Cxy Dx Ey F0 w (-1) (-1))
      (quad A B Cxy Dx Ey F0 w 0 (-1))
      (quad A B Cxy Dx Ey F0 w 1 (-1)) w = 2 * A := by
  unfold phase1WrongHyy quad
  field_simp [sq_ne_zero hw]
  ring

end
end VeriGIS.Curvature
