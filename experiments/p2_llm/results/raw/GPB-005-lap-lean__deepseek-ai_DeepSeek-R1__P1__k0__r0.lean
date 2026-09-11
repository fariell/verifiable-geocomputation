/-
  ==========================================================================
   GeoProofBench · Discrete Local Maximum and Laplacian Sign
   算子 : 5-point discrete Laplacian (orthogonal neighbors only)
   环境 : Lean 4.18.0 + mathlib
  ==========================================================================

  本文件证明: 若 3x3 窗口中心为离散局部极大值(中心高程≥四个正交邻域),
  则中心点的离散拉普拉斯算子 ≤0.

  离散拉普拉斯算子定义(5点模板):
      ∇²h = (west + east + north + south) - 4 * center

  注: 此定义对应网格间距 dx=dy=1 的情形. 对于任意网格间距, 拉普拉斯算子需除以 dx²,
      但符号不变(因 dx²>0), 故结论仍成立.
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.LocalMaxLaplacian

noncomputable section

/-!
  ## 3×3 窗口约定(行偏移向下为正)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)   e( 0, 0)   f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  正交邻域: b(north), d(west), f(east), h(south)
  中心元: e
-/

/-- 离散拉普拉斯算子(5点模板) -/
def discreteLaplacian (a b c d e f g h i : ℝ) : ℝ := 
  (b + d + f + h) - 4 * e

/--
  定理: 若中心为局部极大值(≥所有正交邻域), 则离散拉普拉斯算子非正
-/
theorem local_max_imp_nonpos_laplacian (a b c d e f g h i : ℝ)
    (h_north : e ≥ b)  -- 中心 ≥ 北邻
    (h_south : e ≥ h)  -- 中心 ≥ 南邻
    (h_west : e ≥ d)   -- 中心 ≥ 西邻
    (h_east : e ≥ f) : -- 中心 ≥ 东邻
    discreteLaplacian a b c d e f g h i ≤ 0 := by
  -- 展开拉普拉斯算子定义
  unfold discreteLaplacian
  -- 将目标重写为邻域与中心的差值之和
  have target_eq : (b + d + f + h) - 4 * e = (b - e) + (d - e) + (f - e) + (h - e) := by ring
  rw [target_eq]
  -- 每个差值项 ≤0 (由局部极大值假设)
  have h1 : b - e ≤ 0 := sub_nonpos.mpr h_north
  have h2 : d - e ≤ 0 := sub_nonpos.mpr h_west
  have h3 : f - e ≤ 0 := sub_nonpos.mpr h_east
  have h4 : h - e ≤ 0 := sub_nonpos.mpr h_south
  -- 四个非正数之和仍非正
  linarith

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

/-- 平坦地形: 拉普拉斯=0 -/
example : discreteLaplacian 1 1 1 1 1 1 1 1 1 = 0 := by norm_num [discreteLaplacian]

/-- 局部极大值: 拉普拉斯=-4 -/
example : discreteLaplacian 0 1 0 1 5 1 0 1 0 = -4 := by norm_num [discreteLaplacian]

/-- 非极大值: 拉普拉斯=1 (不满足定理条件) -/
example : discreteLaplacian 0 2 0 2 1 2 0 2 0 = 1 := by norm_num [discreteLaplacian]

end -- noncomputable section

end VeriGIS.LocalMaxLaplacian
