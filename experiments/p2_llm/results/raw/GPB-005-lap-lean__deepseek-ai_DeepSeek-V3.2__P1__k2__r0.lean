/-
  ==========================================================================
   GeoProofBench · P-003 (discrete Laplacian sign at local maximum)
   文件 : formal/lean4/VeriGIS/DiscreteLaplacian.lean
   命题 : 若 3×3 窗口中心为离散局部极大值(中心高程 ≥ 四个正交邻域),
          则中心处的离散拉普拉斯算子 ≤ 0.
   参考 : experiments/phase1/p003_curvature.py (numeric_zt)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  离散拉普拉斯算子(二阶中心差分)定义为:
    Δe = (d + f + b + h - 4 * e) / w²
  其中 w 为格网间距,分母 w² 为正,因此符号仅由分子决定.
  本定理仅关注符号,故省略分母.
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

  中心元 e 在离散拉普拉斯算子中显式出现.
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 离散拉普拉斯算子的分子(省略正分母 w²). -/
def laplacianNum (b d e f h : ℝ) : ℝ := d + f + b + h - 4 * e

/-- 中心为离散局部极大值(正交四邻域). -/
def isLocalMaxOrth (b d e f h : ℝ) : Prop := e ≥ b ∧ e ≥ d ∧ e ≥ f ∧ e ≥ h

-- ==========================================================================
-- 主定理
-- ==========================================================================

theorem local_max_implies_nonpositive_laplacian
    (b d e f h : ℝ) (hmax : isLocalMaxOrth b d e f h) :
    laplacianNum b d e f h ≤ 0 := by
  -- 展开定义
  unfold isLocalMaxOrth at hmax
  unfold laplacianNum
  -- 分解条件
  rcases hmax with ⟨heb, hed, hef, heh⟩
  -- 将不等式转换为非负形式
  have hb : b - e ≤ 0 := sub_nonpos_of_le heb
  have hd : d - e ≤ 0 := sub_nonpos_of_le hed
  have hf : f - e ≤ 0 := sub_nonpos_of_le hef
  have hh : h - e ≤ 0 := sub_nonpos_of_le heh
  -- 组合四项
  have : (d - e) + (f - e) + (b - e) + (h - e) ≤ 0 := by
    linarith
  -- 化简即为目标
  linarith

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

example : laplacianNum 1 1 2 1 1 = -4 := by
  unfold laplacianNum
  norm_num

example (b d e f h : ℝ) (hmax : isLocalMaxOrth b d e f h) :
    laplacianNum b d e f h ≤ 0 :=
  local_max_implies_nonpositive_laplacian b d e f h hmax

-- ==========================================================================
-- 结构注记
-- --------------------------------------------------------------------------
-- 1. 定理仅依赖正交四邻域,对角邻域不影响结论.
-- 2. 若中心严格大于所有四个邻域,则拉普拉斯分子严格负.
-- 3. 分母 w² > 0 保持符号,故离散拉普拉斯值本身 ≤ 0.
-- 4. 这是离散极大值的二阶必要条件之一.
-- ==========================================================================

end -- noncomputable section

end VeriGIS.DiscreteLaplacian
