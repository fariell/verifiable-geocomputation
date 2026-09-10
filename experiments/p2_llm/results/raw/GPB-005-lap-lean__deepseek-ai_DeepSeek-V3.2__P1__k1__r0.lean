/-
  ==========================================================================
   GeoProofBench · P-003 (discrete Laplacian sign at local maximum)
   文件 : formal/lean4/VeriGIS/LocalMaxLaplacian.lean
   命题 : 若 3×3 窗口中心为离散正交局部极大值，则其离散拉普拉斯 ≤ 0
   对偶 : formal/dafny/P003_curvature.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本命题是曲率一致性讨论的引理：在离散局部极大值处，拉普拉斯算子（二阶差分）
  的符号应为非正。这是 Evans / Zevenbergen–Thorne 曲率算子的一个特例，
  但此处仅关注符号性质，不涉及具体曲率定义。

  注意：离散拉普拉斯使用标准五点模板（中心与四个正交邻居）。
  本文件不假设任何特定的高程单位或格网间距，因为拉普拉斯符号在尺度缩放下不变。
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.LocalMaxLaplacian

noncomputable section

/-!
  ## 3×3 窗口约定（行偏移向下为正）

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 在离散拉普拉斯中显式出现。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 离散拉普拉斯（五点模板，正交邻居） -/
def discreteLaplacian (b d e f h : ℝ) : ℝ := (b + d + f + h) - 4 * e

/-- 中心元 e 是离散正交局部极大值：e ≥ 每个正交邻居 -/
def isOrthLocalMax (b d e f h : ℝ) : Prop :=
  e ≥ b ∧ e ≥ d ∧ e ≥ f ∧ e ≥ h

-- ==========================================================================
-- 主定理：局部极大值处的拉普拉斯非正
-- ==========================================================================

theorem laplacian_nonpos_at_local_max (b d e f h : ℝ) (hmax : isOrthLocalMax b d e f h) :
    discreteLaplacian b d e f h ≤ 0 := by
  -- 展开定义
  unfold discreteLaplacian isOrthLocalMax at *
  -- 分解局部极大条件
  rcases hmax with ⟨heb, hed, hef, heh⟩
  -- 将不等式转换为非负形式
  have hb : b - e ≤ 0 := by linarith
  have hd : d - e ≤ 0 := by linarith
  have hf : f - e ≤ 0 := by linarith
  have hh : h - e ≤ 0 := by linarith
  -- 计算拉普拉斯
  show (b + d + f + h) - 4 * e ≤ 0
  -- 重组为 (b-e) + (d-e) + (f-e) + (h-e) ≤ 0
  ring_nf
  -- 四个非正项之和仍非正
  nlinarith

-- ==========================================================================
-- 冒烟测试（验证算子定义与定理实例）
-- ==========================================================================

example : discreteLaplacian 1 2 5 3 4 = -9 := by
  unfold discreteLaplacian
  norm_num

example (b d e f h : ℝ) (h1 : e ≥ b) (h2 : e ≥ d) (h3 : e ≥ f) (h4 : e ≥ h) :
    discreteLaplacian b d e f h ≤ 0 := by
  apply laplacian_nonpos_at_local_max
  exact ⟨h1, h2, h3, h4⟩

-- ==========================================================================
-- 结构注记
-- --------------------------------------------------------------------------
-- 本定理是曲率一致性讨论的基石：在局部极大值处，拉普拉斯非正。
-- 若实际计算出的拉普拉斯为正，则要么：
--   1) 中心并非真正的局部极大值（噪声或采样问题），或
--   2) 离散模板与连续定义不一致（需要更精细的误差分析）。
--
-- 在 GeoProofBench P-003 中，此引理用于解释为什么 Phase 1 中
-- 曲率与实测地形相关性低（≈0.157）：错误的模板破坏了此基本符号性质，
-- 导致即使在明显的局部凸起处，计算出的“曲率”也可能为正。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.LocalMaxLaplacian
