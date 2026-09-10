/-
  ==========================================================================
   GeoProofBench · P-021
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D 左出口填坑 (Fill)
   对偶 : formal/dafny/PCOMP_1.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本的**独立**重述 —— 不是翻译。两处必须注意的差异:

    1. 本文件关注的是 1D 左出口填坑算子的非递减性质。
    2. 证明风格:Lean 靠显式战术(`ring_nf` / `field_simp` / `nlinarith`)。

  ==========================================================================
-/

import Mathlib.Data.Array.Basic
import Mathlib.Tactic

namespace VeriGIS.Composition

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 1D 左出口填坑算子定义 -/
def pitFill1D (a : Array ℝ) : Array ℝ := 
  let fill := a.map (fun x => x)
  let visited := a.map (fun _ => false)
  let heap := a.map (fun x => (x, 0))
  let seed (i : Nat) : Unit := 
    if visited[i] then () else
      fill[i] := a[i]
      visited[i] := true
      heap.push (fill[i], i)
  for i in [0 : a.size] do
    seed i
  while !heap.isEmpty do
    let (z, i) := heap.popMin
    for di in [-1, 1] do
      let j := i + di
      if 0 ≤ j ∧ j < a.size ∧ !visited[j] then
        let nz := max a[j] fill[i]
        if nz > fill[j] then
          fill[j] := nz
          visited[j] := true
          heap.push (fill[j], j)
  fill

-- ==========================================================================
-- 非递减性质
-- ==========================================================================

theorem pitFill1D_nondecreasing (a : Array ℝ) (i : Nat) (h : i + 1 < a.size) :
  pitFill1D a[i] ≤ pitFill1D a[i+1] := by
  -- 证明思路:通过填坑算子的定义,逐步展示填坑后的序列是非递减的。
  -- 1. 初始化时,填坑序列与原序列相同,因此满足非递减性质。
  -- 2. 每次从堆中取出最小值,并更新其邻居,确保邻居的值不小于当前值。
  -- 3. 通过归纳法,证明填坑后的序列在每一步都保持非递减性质。
  induction a with x xs ih
  case nil => simp [pitFill1D]
  case cons => 
    simp [pitFill1D, Array.map, Array.push, Array.popMin, Array.isEmpty, Array.size]
    have h0 : 0 < a.size := by simp [a.size]; exact Nat.zero_lt_succ i
    have h1 : i < a.size := by simp [a.size]; exact h
    have h2 : i + 1 < a.size := by simp [a.size]; exact h
    have h3 : pitFill1D (a[i]) ≤ pitFill1D (a[i+1]) := by
      -- 通过填坑算子的定义,逐步展示填坑后的序列是非递减的。
      -- 1. 初始化时,填坑序列与原序列相同,因此满足非递减性质。
      -- 2. 每次从堆中取出最小值,并更新其邻居,确保邻居的值不小于当前值。
      -- 3. 通过归纳法,证明填坑后的序列在每一步都保持非递减性质。
      simp [pitFill1D, Array.map, Array.push, Array.popMin, Array.isEmpty, Array.size]
      apply ih
      exact h1
      exact h2

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : pitFill1D #[0, 1, 2, 3, 4] = #[0, 1, 2, 3, 4] := by
  simp [pitFill1D]

example : pitFill1D #[1, 0, 2, 1, 3] = #[1, 1, 2, 2, 3] := by
  simp [pitFill1D]

end VeriGIS.Composition
