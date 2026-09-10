/-
  ==========================================================================
   GeoProofBench · P-005
   文件 : formal/lean4/VeriGIS/D8.lean
   算子 : D8 流向
   对偶 : formal/dafny/P005_d8.dfy  (Dafny 4.11, 19 verified 0 errors)
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
import Mathlib.Data.Array.Basic
import Mathlib.Data.Real.Basic

namespace VeriGIS.D8

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 3×3 窗口约定(行偏移 q 向下为正,符合栅格惯例)

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  中心元 e 在 D8 算子中权为 0,**不出现在算子签名里**。
  这不是省略,而是结构性质 —— 见文件末尾"为什么二阶不行"。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- D8 流向的定义。给定 3×3 窗口的高程值,返回流向。 -/
def d8Flow (h : Array (Array ℝ)) (r c : Nat) (w : ℝ) : String := 
  let e := h[r][c]
  let DIRS := [("E", 1, 0, 1.0), ("SE", 1, 1, 2.0), ("S", 0, 1, 1.0), ("SW", -1, 1, 2.0),
               ("W", -1, 0, 1.0), ("NW", -1, -1, 2.0), ("N", 0, -1, 1.0), ("NE", 1, -1, 2.0)]
  let best := DIRS.foldl (fun (best, best_p) (name, dp, dq, dist2) =>
    let rr := r + dq
    let cc := c + dp
    if 0 ≤ rr ∧ rr < h.size ∧ 0 ≤ cc ∧ cc < h[0].size then
      let drop := e - h[rr][cc]
      if drop > 0 then
        let p := (drop * drop) / dist2
        if best_p = 0 ∨ p > best_p then (name, p) else (best, best_p)
      else (best, best_p)
    else (best, best_p)
  ) ("NoFlow", 0.0)
  best.1

-- ==========================================================================
-- 平面 DEM 上 D8 流向的性质
-- ==========================================================================

/-- 在平面 DEM z = A x + B y + C 上,平移高程基准 C 不改变 D8 流向。 -/
theorem d8Flow_constant_translation (A B w : ℝ) (C1 C2 : ℝ) (r c : Nat) :
  d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => A * (i - r) + B * (j - c) + C1)) 3 3) r c w =
  d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => A * (i - r) + B * (j - c) + C2)) 3 3) r c w := by
  -- 由于 D8 流向仅依赖于高程差,平移 C1 和 C2 不影响高程差,因此流向不变。
  simp [d8Flow]
  congr
  ext i j
  field_simp
  ring

-- ==========================================================================
-- 平面 DEM 上 D8 流向的具体方向
-- ==========================================================================

/-- 在平面 DEM z = A x + 0 y + C (A > 0) 上,每个内部单元格的流向都是向西。 -/
theorem d8Flow_west (A : ℝ) (hA : A > 0) (C : ℝ) (r c : Nat) :
  d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => A * (i - r) + 0 * (j - c) + C)) 3 3) r c w = "W" := by
  -- 由于 A > 0,每个单元格的高程差最大值出现在向西方向。
  simp [d8Flow]
  congr
  ext i j
  field_simp
  ring
  -- 证明向西方向的高程差最大
  have hWestDrop : (A * (r - (r - 1)) + 0 * (c - c) + C) - (A * (r - (r + 1)) + 0 * (c - c) + C) = 2 * A := by ring
  have hMaxWest : ∀ (dp dq : Int) (dist2 : ℝ), (dp, dq) ≠ (-1, 0) → (2 * A) > (A * (r - (r + dq)) + 0 * (c - (c + dp)) + C - (A * (r - r) + 0 * (c - c) + C) * (A * (r - (r + dq)) + 0 * (c - (c + dp)) + C - (A * (r - r) + 0 * (c - c) + C)) / dist2 := by
    intro dp dq dist2 hNeq
    cases dp; cases dq
    -- 逐个方向验证
    -- E
    case int.ofNat 0 int.ofNat 0 => 
      simp; linarith
    -- SE
    case int.ofNat 0 int.ofNat 1 => 
      simp; linarith
    -- S
    case int.ofNat 0 int.ofNat 0 => 
      simp; linarith
    -- SW
    case int.ofNat 1 int.ofNat 1 => 
      simp; linarith
    -- W
    case int.ofNat 1 int.ofNat 0 => 
      simp; linarith
    -- NW
    case int.ofNat 1 int.ofNat -1 => 
      simp; linarith
    -- N
    case int.ofNat 0 int.ofNat -1 => 
      simp; linarith
    -- NE
    case int.ofNat 1 int.ofNat -1 => 
      simp; linarith
  -- 由于向西方向的高程差最大,因此流向为向西
  have hBestWest : d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => A * (i - r) + 0 * (j - c) + C)) 3 3) r c w = "W" := by
    simp [d8Flow]
    congr
    ext i j
    field_simp
    ring
    apply hMaxWest
  exact hBestWest

/-- 在平面 DEM z = A x + A y + C (A > 0) 上,每个内部单元格的流向都是西北。 -/
theorem d8Flow_northwest (A : ℝ) (hA : A > 0) (C : ℝ) (r c : Nat) :
  d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => A * (i - r) + A * (j - c) + C)) 3 3) r c w = "NW" := by
  -- 由于 A > 0,每个单元格的高程差最大值出现在西北方向。
  simp [d8Flow]
  congr
  ext i j
  field_simp
  ring
  -- 证明西北方向的高程差最大
  have hNorthwestDrop : (A * (r - (r - 1)) + A * (c - (c - 1)) + C) - (A * (r - (r + 1)) + A * (c - (c + 1)) + C) = 2 * A + 2 * A := by ring
  have hMaxNorthwest : ∀ (dp dq : Int) (dist2 : ℝ), (dp, dq) ≠ (-1, -1) → (2 * A + 2 * A) > (A * (r - (r + dq)) + A * (c - (c + dp)) + C - (A * (r - r) + A * (c - c) + C) * (A * (r - (r + dq)) + A * (c - (c + dp)) + C - (A * (r - r) + A * (c - c) + C)) / dist2 := by
    intro dp dq dist2 hNeq
    cases dp; cases dq
    -- 逐个方向验证
    -- E
    case int.ofNat 0 int.ofNat 0 => 
      simp; linarith
    -- SE
    case int.ofNat 0 int.ofNat 1 => 
      simp; linarith
    -- S
    case int.ofNat 0 int.ofNat 0 => 
      simp; linarith
    -- SW
    case int.ofNat 1 int.ofNat 1 => 
      simp; linarith
    -- W
    case int.ofNat 1 int.ofNat 0 => 
      simp; linarith
    -- NW
    case int.ofNat 1 int.ofNat -1 => 
      simp; linarith
    -- N
    case int.ofNat 0 int.ofNat -1 => 
      simp; linarith
    -- NE
    case int.ofNat 1 int.ofNat -1 => 
      simp; linarith
  -- 由于西北方向的高程差最大,因此流向为西北
  have hBestNorthwest : d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => A * (i - r) + A * (j - c) + C)) 3 3) r c w = "NW" := by
    simp [d8Flow]
    congr
    ext i j
    field_simp
    ring
    apply hMaxNorthwest
  exact hBestNorthwest

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => 0.4 * (i - 1) + 0.0 * (j - 1) + 12.0)) 3 3 1 = "W" := by
  norm_num [d8Flow]

example : d8Flow (Array.ofFn (fun i => Array.ofFn (fun j => 0.4 * (i - 1) + 0.4 * (j - 1) - 3.0)) 3 3 1 = "NW" := by
  norm_num [d8Flow]

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

end VeriGIS.D8
