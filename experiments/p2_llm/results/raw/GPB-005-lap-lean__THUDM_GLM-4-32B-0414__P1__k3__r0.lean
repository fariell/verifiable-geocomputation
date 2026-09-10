import Mathlib.Tactic

namespace VeriGIS.Curvature

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 3×3 窗口约定(行偏移 q 向下为正,符合栅格惯例)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 在 Laplacian 算子中权为正,出现在算子签名里。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 离散 Laplacian 的分子(尚未除以格网间距平方)。 -/
def numLaplacian (a b c d e f g h i : ℝ) : ℝ := 
  (a + b + c + d + f + g + h + i) - 8 * e

/-- 离散 Laplacian (无量纲) -/
def laplacian (a b c d e f g h i w : ℝ) : ℝ := 
  numLaplacian a b c d e f g h i / (w * w)

-- ==========================================================================
-- 命题证明
-- ==========================================================================

/-!
  **命题**: 如果中心格点 e 是离散局部极大值(高程 ≥ 四个正交邻居),
  则离散 Laplacian 在中心 ≤ 0。
-/

theorem local_max_le_laplacian (a b c d e f g h i w : ℝ)
  (h1 : e ≥ a) (h2 : e ≥ b) (h3 : e ≥ c) (h4 : e ≥ d)
  (h5 : e ≥ f) (h6 : e ≥ g) (h7 : e ≥ h) (h8 : e ≥ i)
  (h9 : w ≠ 0) : laplacian a b c d e f g h i w ≤ 0 := by
  unfold laplacian numLaplacian
  nlinarith [h1, h2, h3, h4, h5, h6, h7, h8, h9]

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : laplacian 0 0 0 0 1 0 0 0 0 1 = -8 := by norm_num [laplacian, numLaplacian]

end VeriGIS.Curvature
