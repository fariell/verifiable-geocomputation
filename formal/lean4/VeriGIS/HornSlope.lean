/-
  ==========================================================================
   GeoProofBench · P-001
   文件 : formal/lean4/VeriGIS/HornSlope.lean
   算子 : Horn (1981) 3×3 有限差分坡度
   对偶 : formal/dafny/P001_horn_slope.dfy  (Dafny 4.11, 19 verified 0 errors)
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

namespace VeriGIS.HornSlope

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 3×3 窗口约定(行偏移 q 向下为正,符合栅格惯例)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 在 Horn 一阶差分中权为 0,**不出现在算子签名里**。
  这不是省略,而是结构性质 —— 见文件末尾"为什么二阶不行"。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- x 方向一阶差分的分子(尚未除以格网间距)。b、h 在 Horn ∂x 中权为 0。 -/
def numDx (a _b c d f g _h i : ℝ) : ℝ := (c + 2 * f + i) - (a + 2 * d + g)

/-- y 方向一阶差分的分子。d、f 在 Horn ∂y 中权为 0。 -/
def numDy (a b c _d _f g h i : ℝ) : ℝ := (g + 2 * h + i) - (a + 2 * b + c)

/-- ∂z/∂x 的 Horn 有限差分估计(m/m,无量纲) -/
def dzdx (a b c d f g h i w : ℝ) : ℝ := numDx a b c d f g h i / (8 * w)

/-- ∂z/∂y 的 Horn 有限差分估计 -/
def dzdy (a b c d f g h i w : ℝ) : ℝ := numDy a b c d f g h i / (8 * w)

/-- 坡度(梯度模长)的平方。取平方而非开方:避开 `Real.sqrt` 的超越性,
    让性质留在多项式(可判定)域内。"非负"与"为零"在平方层面完全等价。 -/
def slopeSq (a b c d f g h i w : ℝ) : ℝ :=
  (dzdx a b c d f g h i w) ^ 2 + (dzdy a b c d f g h i w) ^ 2

/-- 平面采样:物理坐标 x = p·w,y = q·w 处的真实高程 -/
def plane (A B C w p q : ℝ) : ℝ := A * (p * w) + B * (q * w) + C

/-- 平面上以原点为中心的 3×3 窗口采样(def 而非 abbrev:证明里要 unfold) -/
def pTL (A B C w : ℝ) : ℝ := plane A B C w (-1) (-1)
def pTC (A B C w : ℝ) : ℝ := plane A B C w   0  (-1)
def pTR (A B C w : ℝ) : ℝ := plane A B C w   1  (-1)
def pML (A B C w : ℝ) : ℝ := plane A B C w (-1)  0
def pMR (A B C w : ℝ) : ℝ := plane A B C w   1    0
def pBL (A B C w : ℝ) : ℝ := plane A B C w (-1)  1
def pBC (A B C w : ℝ) : ℝ := plane A B C w   0    1
def pBR (A B C w : ℝ) : ℝ := plane A B C w   1    1

/-- 域上除法的非零前提:8·w ≠ 0(由 w ≠ 0 推出) -/
lemma eight_mul_ne_zero {w : ℝ} (hw : w ≠ 0) : (8 : ℝ) * w ≠ 0 :=
  mul_ne_zero (by norm_num) hw

-- ==========================================================================
-- GPB-001 · 平坦面的坡度恒为零
-- ==========================================================================

/-- 常值高程面(平地)的两个一阶偏导估计均为 0。
    代数根源:正权之和 = 负权之和 = 4 → 常数项精确抵消。 -/
theorem flat_slope_zero (C w : ℝ) :
    dzdx C C C C C C C C w = 0 ∧ dzdy C C C C C C C C w = 0 := by
  unfold dzdx dzdy numDx numDy
  constructor <;> ring_nf

/-- 平坦面的坡度(平方)亦为 0 -/
theorem flat_slopeSq_zero (C w : ℝ) : slopeSq C C C C C C C C w = 0 := by
  rw [slopeSq, (flat_slope_zero C w).1, (flat_slope_zero C w).2]
  norm_num

-- ==========================================================================
-- GPB-001 · 坡度非负(任意高程构型)
-- ==========================================================================

/-- 坡度平方非负。注意这里**不需要** w ≠ 0:ℝ 上除法是全函数,
    即使 w = 0 结论仍成立(只是算子此时无物理意义)。 -/
theorem slopeSq_nonneg (a b c d f g h i w : ℝ) : 0 ≤ slopeSq a b c d f g h i w := by
  unfold slopeSq
  nlinarith [sq_nonneg (dzdx a b c d f g h i w), sq_nonneg (dzdy a b c d f g h i w)]

-- ==========================================================================
-- GPB-002 + GPB-019(一阶部分)· 平面上的精确性
--
-- 设真实地表为平面 z(x,y) = A·x + B·y + C,以间距 w 采样成 3×3 窗口。
-- 则 Horn 有限差分**精确**恢复 A 与 B —— 不是"渐近一致",是恒等。
--
-- 这条是 P-001 最硬的一条:它说明一阶算子的一致性不是经验巧合。
-- (GPB-019 的完整陈述还要求 w → 0 时高次余项 → 0,见 P-004。)
-- ==========================================================================

/-- 平面上精确恢复 ∂z/∂x = A -/
theorem planar_exact_dx (A B C w : ℝ) (hw : w ≠ 0) :
    dzdx (pTL A B C w) (pTC A B C w) (pTR A B C w)
         (pML A B C w) (pMR A B C w)
         (pBL A B C w) (pBC A B C w) (pBR A B C w) w = A := by
  unfold dzdx numDx
  simp only [pTL, pTC, pTR, pML, pMR, pBL, pBC, pBR, plane]
  field_simp [eight_mul_ne_zero hw]
  ring

/-- 平面上精确恢复 ∂z/∂y = B -/
theorem planar_exact_dy (A B C w : ℝ) (hw : w ≠ 0) :
    dzdy (pTL A B C w) (pTC A B C w) (pTR A B C w)
         (pML A B C w) (pMR A B C w)
         (pBL A B C w) (pBC A B C w) (pBR A B C w) w = B := by
  unfold dzdy numDy
  simp only [pTL, pTC, pTR, pML, pMR, pBL, pBC, pBR, plane]
  field_simp [eight_mul_ne_zero hw]
  ring

/-- 合并陈述:平面上的梯度被精确恢复 -/
theorem planar_exact (A B C w : ℝ) (hw : w ≠ 0) :
    dzdx (pTL A B C w) (pTC A B C w) (pTR A B C w)
         (pML A B C w) (pMR A B C w)
         (pBL A B C w) (pBC A B C w) (pBR A B C w) w = A ∧
    dzdy (pTL A B C w) (pTC A B C w) (pTR A B C w)
         (pML A B C w) (pMR A B C w)
         (pBL A B C w) (pBC A B C w) (pBR A B C w) w = B :=
  ⟨planar_exact_dx A B C w hw, planar_exact_dy A B C w hw⟩

-- ==========================================================================
-- 平移不变性 · 整体高程基准移动不改变坡度
-- (这是"坡度算子只依赖高程**差**"的形式化表述,也是垂直基准转换
--  —— 大地高 ↔ 正常高 —— 不影响坡度的理论依据)
-- ==========================================================================

theorem translation_invariant_dx (a b c d f g h i w K : ℝ) :
    dzdx (a + K) (b + K) (c + K) (d + K) (f + K) (g + K) (h + K) (i + K) w =
      dzdx a b c d f g h i w := by
  unfold dzdx numDx
  ring_nf

theorem translation_invariant_dy (a b c d f g h i w K : ℝ) :
    dzdy (a + K) (b + K) (c + K) (d + K) (f + K) (g + K) (h + K) (i + K) w =
      dzdy a b c d f g h i w := by
  unfold dzdy numDy
  ring_nf

-- ==========================================================================
-- 镜像反对称性 · 左右镜像使 ∂z/∂x 变号,上下镜像使 ∂z/∂y 变号
-- (地形算子在坐标反射下的行为,是"算子是否与坐标系约定无关"的
--   第一块试金石;坡向算子的手性 bug 大多栽在这里)
-- ==========================================================================

theorem mirror_dx_antisym (a b c d f g h i w : ℝ) :
    dzdx c b a f d i h g w = -dzdx a b c d f g h i w := by
  unfold dzdx numDx
  ring_nf

theorem mirror_dy_antisym (a b c d f g h i w : ℝ) :
    dzdy g h i d f a b c w = -dzdy a b c d f g h i w := by
  unfold dzdy numDy
  ring_nf

-- ==========================================================================
-- 尺度线性 · 高程整体缩放 k 倍,梯度缩放 k 倍
-- (单位换算 m → ft 不改变算子结构,只作用于输出)
-- ==========================================================================

theorem scale_linear_dx (a b c d f g h i w k : ℝ) :
    dzdx (k * a) (k * b) (k * c) (k * d) (k * f) (k * g) (k * h) (k * i) w =
      k * dzdx a b c d f g h i w := by
  unfold dzdx numDx
  ring_nf

theorem scale_linear_dy (a b c d f g h i w k : ℝ) :
    dzdy (k * a) (k * b) (k * c) (k * d) (k * f) (k * g) (k * h) (k * i) w =
      k * dzdy a b c d f g h i w := by
  unfold dzdy numDy
  ring_nf

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : dzdx 0 0 0 0 0 0 0 0 1 = 0 := by norm_num [dzdx, numDx]
example : slopeSq 0 0 0 0 0 0 0 0 1 = 0 := by norm_num [slopeSq, dzdx, dzdy, numDx, numDy]

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

end VeriGIS.HornSlope
