/-
  ==========================================================================
   GeoProofBench · P-COMP-1 (algebraic part: 1D fill nondecreasing)
   文件 : formal/lean4/VeriGIS/Composition/FillNonDecreasing.lean
   算子 : 1D left-outlet pit filling
   对偶 : 
   环境 : Lean 4 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件形式化验证 1D 左出口填洼算子的核心代数性质: 输出序列单调非降。
  算子定义:
    Fill(a)[0] = a[0]
    Fill(a)[i] = max(a[i], Fill(a)[i-1])  对于 i > 0

  定理: 对于任意实数序列 a, 填洼结果序列是非降的, 即
        ∀ i, Fill(a)[i] ≤ Fill(a)[i+1]   (当索引有效时)

  注: 本证明独立于 2D 填洼实现, 聚焦 1D 代数性质。
  ==========================================================================
-/

import Mathlib.Data.List.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic

namespace VeriGIS.Fill

noncomputable section  -- ℝ 上的 max 操作

/-!
  ## 1D 左出口填洼算子定义
  约定: 序列索引从左(0)向右递增, 出口在左端(索引0)
-/

/-- 填洼核: 从初始值 c 开始向右传播的填洼序列 -/
def fillGo (c : ℝ) : List ℝ → List ℝ
  | [] => []
  | y::ys => 
      let m := max y c
      m :: fillGo m ys

/-- 完整填洼序列: 首元素固定, 后续由 fillGo 生成 -/
def fill (a : List ℝ) : List ℝ :=
  match a with
  | [] => []
  | x::xs => x :: fillGo x xs

/-!
  ## 非降序列谓词
  定义: 序列 l 是非降的当且仅当 ∀ i, i+1 < l.length → l[i] ≤ l[i+1]
-/
def NonDecreasing (l : List ℝ) : Prop :=
  ∀ (i : ℕ) (hi : i + 1 < l.length), 
    l.get ⟨i, by omega⟩ ≤ l.get ⟨i+1, by omega⟩

/-!
  ## 核心引理: fillGo 生成序列的非降性
  对任意初始值 c 和序列 b, 序列 (c :: fillGo c b) 是非降的
-/
theorem nondec_go (c : ℝ) (b : List ℝ) : 
    NonDecreasing (c :: fillGo c b) := by
  induction b generalizing c with
  | nil =>  -- 空序列: [c] 无相邻对, 平凡成立
    intro i hi
    have : i + 1 < 1 := hi
    linarith
  | cons y ys ih =>  -- 归纳步骤: b = y::ys
    intro i hi
    simp [fillGo]  -- 展开定义: 序列 = [c, max y c] ++ fillGo (max y c) ys
    cases i with
    | zero =>  -- 首对元素: c 和 max y c
      apply le_max_right
    | succ i =>  -- 后续元素对
      -- 应用归纳假设: 对初始值 (max y c) 和序列 ys
      apply ih (max y c) i
      -- 验证索引条件: i+1 < 1 + (fillGo (max y c) ys).length
      have : i + 1 + 1 < 1 + 1 + (fillGo (max y c) ys).length := by
        simpa using hi
      omega

/-!
  ## 主定理: 填洼结果序列是非降的
-/
theorem fill_nondec (a : List ℝ) : 
    NonDecreasing (fill a) := by
  cases a with
  | nil =>  -- 空输入: 无元素, 平凡成立
    intro i hi
    have : i + 1 < 0 := hi
    linarith
  | cons x xs =>  -- 非空序列
    unfold fill
    exact nondec_go x xs

end -- noncomputable section

end VeriGIS.Fill
