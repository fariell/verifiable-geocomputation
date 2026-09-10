/-
  ==========================================================================
   GeoProofBench · P-003 (discrete Laplacian sign at local maxima)
   文件 : formal/lean4/VeriGIS/LocalMaxLaplacian.lean
   命题 : 若 3×3 窗口中心为离散正交局部极大值，则其离散拉普拉斯 ≤ 0
   对偶 : formal/dafny/P003_curvature.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本命题是曲率一致性讨论的引理：在离散局部极大值处，拉普拉斯算子（二阶差分）
  必须非正。这是 Evans (1980) 或 Zevenbergen–Thorne (1987) 离散 Hessian
  的直接推论，不依赖具体的曲率定义（剖面曲率、平面曲率等）。

  注意：这里“局部极大值”仅考虑四个正交邻域（N‑S‑E‑W），不考虑对角邻域。
  这是 DEM 流路分析中的常见约定（D8 流向中的正交优先）。
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.LocalMaxLaplacian

noncomputable section

/-!
  ## 3×3 窗口约定（与 Horn 坡度一致）

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 在离散拉普拉斯中显式出现，权为 -4。
  四个正交邻域：b（北）、d（西）、f（东）、h（南）。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 离散拉普拉斯（二阶中心差分，无量纲）。 -/
def discreteLaplacian (b d e f h : ℝ) : ℝ := (b + d + f + h) - 4 * e

/-- 中心元 e 是四个正交方向上的离散局部极大值。 -/
def isOrthogonalLocalMax (b d e f h : ℝ) : Prop :=
  e ≥ b ∧ e ≥ d ∧ e ≥ f ∧ e ≥ h

-- ==========================================================================
-- 主定理：局部极大值处的拉普拉斯非正
-- ==========================================================================

theorem laplacian_nonpos_at_local_max {b d e f h : ℝ} (hmax : isOrthogonalLocalMax b d e f h) :
    discreteLaplacian b d e f h ≤ 0 := by
  -- 展开定义
  unfold discreteLaplacian isOrthogonalLocalMax at *
  -- 从假设中提取四个不等式
  rcases hmax with ⟨heb, hed, hef, heh⟩
  -- 将不等式转化为 `e - b ≥ 0` 等形式
  have hb : e - b ≥ 0 := by linarith
  have hd : e - d ≥ 0 := by linarith
  have hf : e - f ≥ 0 := by linarith
  have hh : e - h ≥ 0 := by linarith
  -- 计算拉普拉斯
  show (b + d + f + h) - 4 * e ≤ 0
  -- 等价于 4e - (b + d + f + h) ≥ 0
  have : 4 * e - (b + d + f + h) = (e - b) + (e - d) + (e - f) + (e - h) := by ring
  rw [show (b + d + f + h) - 4 * e = -(4 * e - (b + d + f + h)) by ring]
  -- 右边是非负数的和，因此非负
  rw [this]
  have sum_nonneg : 0 ≤ (e - b) + (e - d) + (e - f) + (e - h) := by
    -- 四个非负数之和非负
    have := add_nonneg (add_nonneg (add_nonneg hb hd) hf) hh
    linarith
  linarith [sum_nonneg]

-- ==========================================================================
-- 冒烟测试（验证定义和定理的基本一致性）
-- ==========================================================================

example : discreteLaplacian 1 2 5 3 4 = -9 := by
  unfold discreteLaplacian
  norm_num

example (b d e f h : ℝ) (hmax : isOrthogonalLocalMax b d e f h) :
    discreteLaplacian b d e f h ≤ 0 :=
  laplacian_nonpos_at_local_max hmax

-- 构造一个反例：若非局部极大值，拉普拉斯可正
example : ¬ ∀ b d e f h : ℝ, discreteLaplacian b d e f h ≤ 0 := by
  intro H
  -- 取 b = d = f = h = 0, e = -1（中心是极小值）
  have := H 0 0 (-1) 0 0
  unfold discreteLaplacian at this
  norm_num at this

-- ==========================================================================
-- 与曲率算子的关系（注记）
-- ==========================================================================
/-
  离散拉普拉斯是 Hessian 的迹：Δ = hxx + hyy。
  在 Evans / ZT 离散化中：

      hxx = (d - 2e + f) / w²
      hyy = (b - 2e + h) / w²

  因此 Δ = (b + d - 4e + f + h) / w² = discreteLaplacian / w²。

  由于 w² > 0，符号由 discreteLaplacian 决定。
  所以本定理等价于“局部极大值处 Hessian 的迹非正”。

  这为后续的曲率一致性证明（P‑003 主文件）提供了基础引理。
-/

end -- noncomputable section

end VeriGIS.LocalMaxLaplacian
