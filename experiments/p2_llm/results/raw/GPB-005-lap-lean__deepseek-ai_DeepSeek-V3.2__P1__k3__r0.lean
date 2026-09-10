/-
  ==========================================================================
   GeoProofBench · P-003 (discrete Laplacian sign at local maximum)
   文件 : formal/lean4/VeriGIS/DiscreteLaplacian.lean
   命题 : 若 3×3 窗口中心为离散局部极大值(中心高程 ≥ 四个正交邻域),
          则中心处的离散拉普拉斯 ≤ 0.
   参考 : experiments/phase1/p003_curvature.py (numeric_zt)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本命题是曲率一致性讨论的前置引理: 在离散二阶差分(拉普拉斯)的语境下,
  局部极大值必然对应非正的拉普拉斯值。这是连续情形的离散类比:
    若 f 在 x₀ 处局部极大, 则 Δf(x₀) ≤ 0.

  注意: 这里使用 Zevenbergen–Thorne (1987) 的离散拉普拉斯定义,
  即 hxx + hyy, 其中 hxx = (d - 2e + f)/w², hyy = (b - 2e + h)/w².
  该定义在 formal/dafny/P003_curvature.dfy 中已验证为二阶差分格式。
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.DiscreteLaplacian

noncomputable section

/-!
  ## 3×3 窗口约定(与 Horn 坡度相同)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  离散拉普拉斯显式依赖中心元 e, 这与一阶差分不同。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- x 方向的二阶差分分子(未除间距平方)。 -/
def numDxx (d e f : ℝ) : ℝ := d - 2 * e + f

/-- y 方向的二阶差分分子(未除间距平方)。 -/
def numDyy (b e h : ℝ) : ℝ := b - 2 * e + h

/-- 离散拉普拉斯分子(未除间距平方)。 -/
def numLaplacian (b d e f h : ℝ) : ℝ := numDxx d e f + numDyy b e h

/-- 离散拉普拉斯值(无量纲, 假设 w ≠ 0)。 -/
def discreteLaplacian (b d e f h w : ℝ) : ℝ := numLaplacian b d e f h / (w * w)

-- ==========================================================================
-- 局部极大值条件
-- ==========================================================================

/-- 中心元 e 在四个正交方向(北、南、东、西)上为局部极大值。 -/
def isOrthogonalLocalMax (b d e f h : ℝ) : Prop :=
  e ≥ b ∧ e ≥ d ∧ e ≥ f ∧ e ≥ h

-- ==========================================================================
-- 主定理: 局部极大值 ⇒ 拉普拉斯 ≤ 0
-- ==========================================================================

theorem local_max_implies_nonpositive_laplacian
    (b d e f h w : ℝ) (hw : w ≠ 0) (hmax : isOrthogonalLocalMax b d e f h) :
    discreteLaplacian b d e f h w ≤ 0 := by
  -- 展开定义
  unfold discreteLaplacian numLaplacian numDxx numDyy isOrthogonalLocalMax at *
  -- 分解局部极大条件
  rcases hmax with ⟨heb, hed, hef, heh⟩
  -- 分子非正的证明
  have hnum_nonpos : (d - 2 * e + f) + (b - 2 * e + h) ≤ 0 := by
    -- 整理为 (d - e) + (f - e) + (b - e) + (h - e) ≤ 0
    ring_nf
    -- 每一项都 ≤ 0
    have h1 : d - e ≤ 0 := by linarith
    have h2 : f - e ≤ 0 := by linarith
    have h3 : b - e ≤ 0 := by linarith
    have h4 : h - e ≤ 0 := by linarith
    linarith
  -- 分母为正
  have hdenom_pos : 0 < w * w := by
    exact mul_self_pos.mpr hw
  -- 组合得到最终结论
  exact (div_nonpos_of_nonpos_of_nonneg hnum_nonpos (by linarith))

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

example : discreteLaplacian 1 1 2 1 1 1 = 0 := by
  unfold discreteLaplacian numLaplacian numDxx numDyy
  norm_num

example (w : ℝ) (hw : w ≠ 0) : discreteLaplacian 0 0 1 0 0 w ≤ 0 := by
  apply local_max_implies_nonpositive_laplacian _ _ _ _ _ _ hw
  unfold isOrthogonalLocalMax
  constructor <;> linarith

-- ==========================================================================
-- 注记: 为什么这是曲率一致性的必要引理
-- --------------------------------------------------------------------------
-- 在连续情形, 若 f 在 x₀ 处局部极大, 则 Hessian 矩阵半负定, 故迹(拉普拉斯) ≤ 0.
-- 离散版本要求同样的符号性质成立, 否则二阶差分格式无法保持极值点的基本分析性质。
--
-- 本引理在 P-003 的完整验证链中用于:
--   1. 确认 ZT 离散 Hessian 在局部极值点给出正确符号。
--   2. 作为反例构造的基础: 若某个"曲率"算子在局部极大点给出正拉普拉斯,
--      则该算子必然不是正确的二阶差分近似。
--
-- 注意: 这里只考虑了正交邻域(4-邻域)。在实际地形分析中, 有时会考虑
-- 8-邻域定义, 但正交邻域是更保守且符合"局部极大"直观的定义。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.DiscreteLaplacian
