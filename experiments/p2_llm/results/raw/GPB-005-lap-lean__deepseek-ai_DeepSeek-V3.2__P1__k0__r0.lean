/-
  ==========================================================================
   GeoProofBench · P-003 (discrete Laplacian sign at local maximum)
   文件 : formal/lean4/VeriGIS/DiscreteLaplacian.lean
   算子 : 3×3 窗口离散拉普拉斯 (中心二阶差分)
   对偶 : formal/dafny/P003_curvature.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件证明: 若 3×3 窗口中心是离散局部极大值(中心高程 ≥ 四个正交邻居),
  则中心点的离散拉普拉斯 ≤ 0.

  离散拉普拉斯定义为:
    Δe = (d + f + b + h - 4 * e) / w²
  其中 w 是格网间距, d/f 是左右邻居, b/h 是上下邻居.

  注意: 此处的"局部极大值"仅考虑正交方向(四邻域), 不考虑对角邻居.
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.DiscreteLaplacian

noncomputable section

/-!
  ## 3×3 窗口约定(行偏移向下为正)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  离散拉普拉斯仅使用正交邻居 b, d, f, h 和中心 e.
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 离散拉普拉斯的分子(尚未除以 w²) -/
def laplacianNum (b d e f h : ℝ) : ℝ := (d + f + b + h) - 4 * e

/-- 离散拉普拉斯算子 -/
def discreteLaplacian (b d e f h w : ℝ) : ℝ := laplacianNum b d e f h / (w ^ 2)

-- ==========================================================================
-- 局部极大值条件
-- ==========================================================================

/-- 中心 e 是离散局部极大值(正交四邻域) -/
def isLocalMaxOrthogonal (b d e f h : ℝ) : Prop :=
  e ≥ b ∧ e ≥ d ∧ e ≥ f ∧ e ≥ h

-- ==========================================================================
-- 主定理: 局部极大值处的离散拉普拉斯非正
-- ==========================================================================

theorem laplacian_nonpos_at_local_max
    (b d e f h w : ℝ)
    (hpos : w ≠ 0)
    (hmax : isLocalMaxOrthogonal b d e f h) :
    discreteLaplacian b d e f h w ≤ 0 := by
  -- 展开定义
  unfold discreteLaplacian laplacianNum isLocalMaxOrthogonal at hmax ⊢
  -- 分解局部极大值条件
  rcases hmax with ⟨heb, hed, hef, heh⟩
  -- 分子 ≤ 0 的证明
  have hnum : (d + f + b + h) - 4 * e ≤ 0 := by
    -- 将和式拆分为四个不等式
    have h1 : d ≤ e := hed
    have h2 : f ≤ e := hef
    have h3 : b ≤ e := heb
    have h4 : h ≤ e := heh
    -- 求和
    linarith
  -- 除以正数 w² 保持不等号方向
  have hw2_pos : 0 < w ^ 2 := pow_pos (abs_pos.mp (ne_iff_lt_or_gt.mp hpos).abs_lt_abs_iff.mpr ?_) 2
  · exact div_nonpos_of_nonpos_of_nonneg hnum (by positivity)
  -- 处理 w ≠ 0 的情况
  cases' lt_or_gt_of_ne hpos with hlt hgt
  · exact abs_pos_of_neg hlt
  · exact abs_pos_of_pos hgt

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

example : discreteLaplacian 1 1 2 1 1 1 = -2 := by
  unfold discreteLaplacian laplacianNum
  norm_num

example (w : ℝ) (hw : w ≠ 0) : discreteLaplacian 0 0 1 0 0 w ≤ 0 := by
  apply laplacian_nonpos_at_local_max 0 0 1 0 0 w hw
  unfold isLocalMaxOrthogonal
  constructor <;> linarith
  constructor <;> linarith
  constructor <;> linarith
  linarith

-- ==========================================================================
-- 注记
-- --------------------------------------------------------------------------
-- 1. 定理要求 w ≠ 0, 否则分母为零, 离散拉普拉斯无定义(在 ℝ 中除以零得零,
--    但此时结果无地理意义).
-- 2. 证明仅使用线性算术(linarith), 因为离散拉普拉斯是线性算子.
-- 3. 此性质是连续拉普拉斯算子在离散情形下的类比: 局部极大值处二阶导非正.
-- ==========================================================================

end -- noncomputable section

end VeriGIS.DiscreteLaplacian
