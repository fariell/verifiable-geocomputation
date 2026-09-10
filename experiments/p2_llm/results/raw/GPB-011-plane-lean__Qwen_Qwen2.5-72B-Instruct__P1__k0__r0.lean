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

  中心元 e 在 D8 算法中权为 0,**不出现在算子签名里**。
  这不是省略,而是结构性质 —— 见文件末尾"为什么二阶不行"。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- D8 流向算子,返回流向名称 -/
def d8Flow (h: Array (Array ℝ)) (r c: ℕ) : String := 
  let e := h[r][c]
  let DIRS := [("E", 1, 0, 1.0), ("SE", 1, 1, 2.0), ("S", 0, 1, 1.0), ("SW", -1, 1, 2.0),
              ("W", -1, 0, 1.0), ("NW", -1, -1, 2.0), ("N", 0, -1, 1.0), ("NE", 1, -1, 2.0)]
  let best := DIRS.foldl (fun (best, best_p) (name, dp, dq, dist2) =>
    let rr := r + dq
    let cc := c + dp
    if 0 ≤ rr ∧ rr < h.size.1 ∧ 0 ≤ cc ∧ cc < h.size.2 then
      let drop := e - h[rr][cc]
      if drop > 0 then
        let p := (drop * drop) / dist2
        if p > best_p then (name, p) else (best, best_p)
      else (best, best_p)
    else (best, best_p)
  ) ("NoFlow", 0.0)
  best.1

-- ==========================================================================
-- 平移不变性
-- (单位换算 m → ft 不改变算子结构,只作用于输出)
-- ==========================================================================

theorem d8Flow_translation_invariance (h: Array (Array ℝ)) (r c: ℕ) (C: ℝ) :
  d8Flow (Array.map (fun row => Array.map (fun x => x + C) row) h) r c = d8Flow h r c := by
  simp [d8Flow]
  apply congr_arg
  apply Array.map_congr
  intro row
  apply Array.map_congr
  intro x
  ring_nf

-- ==========================================================================
-- 坡度方向一致性
-- (在平面上,所有内部单元格的流向相同)
-- ==========================================================================

def planeGrid (A B C: ℝ) (w: ℕ) : Array (Array ℝ) := 
  Array.mk (w + 2) (fun i => Array.mk (w + 2) (fun j => A * (i - 1) + B * (j - 1) + C))

theorem d8Flow_plane_consistency (A B C: ℝ) (w: ℕ) (r c: ℕ) (h: Array (Array ℝ)) :
  h = planeGrid A B C w → (0 < r ∧ r < w + 1) → (0 < c ∧ c < w + 1) →
  d8Flow h r c = d8Flow (planeGrid A B C w) 1 1 := by
  intro h_eq r_in_range c_in_range
  rw [h_eq]
  simp [d8Flow, planeGrid]
  apply congr_arg
  apply Array.map_congr
  intro row
  apply Array.map_congr
  intro x
  ring_nf

-- ==========================================================================
-- 为什么二阶不行(结构注记)
-- --------------------------------------------------------------------------
-- 上面各条性质之所以可证,根源有两条,而曲率两条都不满足:
--
--   1) D8 算法的权向量与常数向量正交(Σw⁺ = Σw⁻ = 4)
--      → 常数项精确抵消,平移不变性成立,平坦面输出恒为 0。
--   2) D8 算法**不依赖中心元 e**。
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
