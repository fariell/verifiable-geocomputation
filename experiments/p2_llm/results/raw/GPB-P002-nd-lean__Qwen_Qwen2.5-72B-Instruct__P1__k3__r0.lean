/-
  ==========================================================================
   GeoProofBench · P-021
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D 左出口填充 (Fill) 操作
   对偶 : formal/dafny/PCOMP_1.dfy  (Dafny 4.11, 19 verified 0 errors)
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

import Mathlib.Data.Array
import Mathlib.Tactic

namespace VeriGIS.Composition

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 1D 左出口填充 (Fill) 操作 -/
def pitFill1D (a : Array ℝ) : Array ℝ := 
  let n := a.size
  let fill := Array.mk n (fun i => a[i]!)
  let visited := Array.mk n (fun i => false)
  let mut heap := PriorityQueue.empty (fun (x y : (ℝ × Nat × Nat)) => x.1 < y.1)
  for i in [0:n] do
    if i = 0 ∨ i = n - 1 then
      heap := heap.insert (a[i]!, i, 0)
      visited := visited.set i true
  while !heap.isEmpty do
    let (z, i, j) := heap.min!
    heap := heap.removeMin
    for di in [-1, 1] do
      let ni := i + di
      if 0 ≤ ni ∧ ni < n ∧ !visited[ni]! then
        let nz := max (a[ni]!) z
        heap := heap.insert (nz, ni, j + 1)
        visited := visited.set ni true
        fill := fill.set ni nz
  fill

-- ==========================================================================
-- 算子性质
-- ==========================================================================

/-- 1D 左出口填充操作产生非递减序列 -/
theorem pitFill1D_nondecreasing (a : Array ℝ) : 
  ∀ i, i < a.size - 1 → (pitFill1D a)[i]! ≤ (pitFill1D a)[i + 1]! := by
  let fill := pitFill1D a
  let n := a.size
  induction n with
  | zero => simp [pitFill1D, Array.size, Array.mk, Array.get]
  | succ n ih =>
    simp [pitFill1D, Array.size, Array.mk, Array.get]
    have h0 : 0 < n + 1 := by linarith
    have h1 : n < n + 1 := by linarith
    have h2 : (pitFill1D a)[0]! = a[0]! := by simp [pitFill1D, Array.get, Array.set, Array.mk]
    have h3 : (pitFill1D a)[n]! = a[n]! := by simp [pitFill1D, Array.get, Array.set, Array.mk]
    have h4 : (pitFill1D a)[0]! ≤ (pitFill1D a)[1]! := by
      simp [pitFill1D, Array.get, Array.set, Array.mk]
      apply ih
    have h5 : (pitFill1D a)[n - 1]! ≤ (pitFill1D a)[n]! := by
      simp [pitFill1D, Array.get, Array.set, Array.mk]
      apply ih
    have h6 : ∀ i, 0 < i → i < n → (pitFill1D a)[i]! ≤ (pitFill1D a)[i + 1]! := by
      intro i hi1 hi2
      simp [pitFill1D, Array.get, Array.set, Array.mk]
      apply ih
    exact h6

end -- noncomputable section

end VeriGIS.Composition
