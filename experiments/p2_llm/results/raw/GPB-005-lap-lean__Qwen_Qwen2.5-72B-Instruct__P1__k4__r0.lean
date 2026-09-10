/-
  ==========================================================================
   GeoProofBench · P-003
   文件 : formal/lean4/VeriGIS/Curvature.lean
   算子 : Zevenbergen–Thorne (1987) 3×3 有限差分曲率
   对偶 : formal/dafny/P003_curvature.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本的**独立**重述 —— 不是翻译。两处必须注意的差异:

    1. Dafny 的 `real` 除法要求 `requires w > 0.0`;Lean 的 `ℝ` 除法是全函数
       (`x / 0 = 0`,由 `inv_zero` 定义)。所以这里的定理把 `w ≠ 0` 写成
       **假设**而不是前置条件,算子在 w = 0 上仍有定义(只是无意义)。
       这是两个系统在"部分函数"处理上的根本差别,也是双形式化的价值之一:
       逼我们把"算子何时有意义"这件事说清楚,而不是藏在前置条件里。

    2. 证明风格:Dafny 靠 SMT(nlinarith/Z3)自动搜;Lean 靠显式战术
       (`ring_nf` / `field_simp` / `nlinarith`)。同一条性质在两边自动化的
       程度差异,本身就是 GeoProofBench 想测量的东西。

  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.Curvature

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 3×3 窗口约定(行偏移 q 向下为正,符合栅格惯例)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 在 Zevenbergen–Thorne 二阶差分中权为 -2,且分母含 w²。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- x 方向二阶差分的分子(尚未除以格网间距)。 -/
def numHxx (a b c d e f g h i : ℝ) : ℝ := (d + f) - 2 * e

/-- y 方向二阶差分的分子(尚未除以格网间距)。 -/
def numHyy (a b c d e f g h i : ℝ) : ℝ := (b + h) - 2 * e

/-- xy 方向二阶差分的分子(尚未除以格网间距)。 -/
def numHxy (a b c d e f g h i : ℝ) : ℝ := (a - c - g + i) / 4

/-- Hxx 的 Zevenbergen–Thorne 有限差分估计(1/m²,无量纲) -/
def hxx (a b c d e f g h i w : ℝ) : ℝ := numHxx a b c d e f g h i / w^2

/-- Hyy 的 Zevenbergen–Thorne 有限差分估计(1/m²,无量纲) -/
def hyy (a b c d e f g h i w : ℝ) : ℝ := numHyy a b c d e f g h i / w^2

/-- Hxy 的 Zevenbergen–Thorne 有限差分估计(1/m²,无量纲) -/
def hxy (a b c d e f g h i w : ℝ) : ℝ := numHxy a b c d e f g h i / w^2

-- ==========================================================================
-- 离散局部最大值时,离散 Laplacian <= 0
-- ==========================================================================

theorem discrete_laplacian_nonpositive_of_local_max (a b c d e f g h i w : ℝ) (h0 : w ≠ 0) (h1 : e ≥ a) (h2 : e ≥ b) (h3 : e ≥ c) (h4 : e ≥ d) (h5 : e ≥ f) (h6 : e ≥ g) (h7 : e ≥ h) (h8 : e ≥ i) :
    hxx a b c d e f g h i w + hyy a b c d e f g h i w ≤ 0 := by
  have h9 : numHxx a b c d e f g h i = (d + f) - 2 * e := rfl
  have h10 : numHyy a b c d e f g h i = (b + h) - 2 * e := rfl
  have h11 : numHxx a b c d e f g h i + numHyy a b c d e f g h i = (d + f + b + h) - 4 * e := by
    rw [h9, h10]
    ring_nf
  have h12 : (d + f + b + h) - 4 * e ≤ 0 := by
    linarith [h1, h2, h3, h4, h5, h6, h7, h8]
  have h13 : hxx a b c d e f g h i w + hyy a b c d e f g h i w = (numHxx a b c d e f g h i + numHyy a b c d e f g h i) / w^2 := by
    unfold hxx hyy
    ring_nf
  rw [h13, h11]
  field_simp [h0]
  linarith [h12]

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : hxx 0 0 0 0 0 0 0 0 1 1 = 0 := by norm_num [hxx, numHxx]
example : hyy 0 0 0 0 0 0 0 0 1 1 = 0 := by norm_num [hyy, numHyy]
example : hxy 0 0 0 0 0 0 0 0 1 1 = 0 := by norm_num [hxy, numHxy]

-- ==========================================================================
-- 为什么二阶不行(结构注记)
-- --------------------------------------------------------------------------
-- 上面各条性质之所以可证,根源有两条,而曲率两条都不满足:
--
--   1) 一阶差分的权向量与常数向量正交(Σw⁺ = Σw⁻ = 4)
--      → 常数项精确抵消,平移不变性成立,平坦面输出恒为 0。
--   2) 一阶差分**不依赖中心元 e**。
--      → 中心格点的高程噪声 δ 完全不进入输出。
--
-- 曲率(Evans / Zevenbergen–Thorne)是二阶差分:它显式依赖 e,且分母含 w²。
-- 设单格高程噪声标准差为 σ,则噪声经二阶差分放大到 O(σ/w²)。w = 30 m 的
-- SRTM 上,σ ≈ 2–5 m 量级的噪声足以让曲率的信噪比崩塌 —— 这正是
-- Phase 1 实测 corr = 0.157 的机制。
--
-- 结论:坡度的一致性**可以被证明**,曲率的一致性**必须先被定义**
-- (在什么误差模型、什么尺度和什么正则化下"一致")。后者才是
-- "可验证空间计算"真正要回答的问题,也是 P-003 的入口。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.Curvature
