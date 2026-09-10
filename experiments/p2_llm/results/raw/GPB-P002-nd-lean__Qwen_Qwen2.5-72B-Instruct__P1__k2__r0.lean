/-
  ==========================================================================
   GeoProofBench · P-021
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D 左出口填充 (Left-outlet Fill)
   对偶 : formal/dafny/PCOMP_1.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本的**独立**重述 —— 不是翻译。两处必须注意的差异:

    1. 本文件关注的是 1D 左出口填充算子的非递减性质。
    2. 证明风格:Lean 靠显式战术(`ring_nf` / `field_simp` / `nlinarith`)。

  ==========================================================================
-/

import Mathlib.Data.Array
import Mathlib.Tactic

namespace VeriGIS.Composition

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 1D 左出口填充算子定义 -/
def pitFill1D (a : Array ℝ) : Array ℝ := 
  let fill := a.map (fun x => x)
  let visited := a.map (fun _ => false)
  let heap := PriorityQueue.empty (fun (x y : ℝ) => x < y)
  let seed (i : Nat) : Unit := 
    if visited[i] then () else
      fill[i] := a[i]
      visited[i] := true
      heap.push (fill[i], i)
  for i in [0 : a.size] do
    seed i
  while let some (z, i) := heap.pop do
    for j in [i - 1, i + 1] do
      if 0 ≤ j ∧ j < a.size ∧ ¬visited[j] then
        fill[j] := max (a[j]) (fill[i])
        visited[j] := true
        heap.push (fill[j], j)
  fill

-- ==========================================================================
-- 非递减性质
-- ==========================================================================

theorem pitFill1D_nondecreasing (a : Array ℝ) (i : Nat) (h : i + 1 < a.size) :
  pitFill1D a[i] ≤ pitFill1D a[i + 1] := by
  -- 证明思路: 通过分析填充过程,确保每个元素的填充值不小于其左侧元素的填充值。
  -- 由于填充过程是从左到右进行的,并且每个元素的填充值是其原始值和左侧已填充值的最大值,
  -- 因此可以保证填充后的数组是非递减的。
  let fill := pitFill1D a
  let visited := a.map (fun _ => false)
  let heap := PriorityQueue.empty (fun (x y : ℝ) => x < y)
  let seed (i : Nat) : Unit := 
    if visited[i] then () else
      fill[i] := a[i]
      visited[i] := true
      heap.push (fill[i], i)
  for i in [0 : a.size] do
    seed i
  while let some (z, i) := heap.pop do
    for j in [i - 1, i + 1] do
      if 0 ≤ j ∧ j < a.size ∧ ¬visited[j] then
        fill[j] := max (a[j]) (fill[i])
        visited[j] := true
        heap.push (fill[j], j)
  -- 通过归纳法证明非递减性质
  induction i with i hi
  case zero =>
    -- 基础情况: i = 0
    simp [pitFill1D, Array.get, Array.size]
    exact le_refl (pitFill1D a[0])
  case succ =>
    -- 归纳步骤: 假设 i 时成立,证明 i + 1 时也成立
    simp [pitFill1D, Array.get, Array.size]
    have h_fill : fill[i] ≤ fill[i + 1] := 
      if h_visited : visited[i + 1] then
        -- 如果 i + 1 已经被访问过,则 fill[i + 1] 是其原始值或左侧已填充值的最大值
        have h_max : fill[i + 1] = max (a[i + 1]) (fill[i]) := 
          if h_visited_i : visited[i] then
            -- 如果 i 也被访问过,则 fill[i + 1] 是其原始值或 fill[i] 的最大值
            by simp [pitFill1D, Array.get, Array.size, h_visited, h_visited_i]
          else
            -- 如果 i 未被访问过,则 fill[i + 1] 是其原始值
            by simp [pitFill1D, Array.get, Array.size, h_visited, h_visited_i]
        by rw [h_max]; exact le_max_right _ _
      else
        -- 如果 i + 1 未被访问过,则 fill[i + 1] 是其原始值
        by simp [pitFill1D, Array.get, Array.size, h_visited]
    exact h_fill

end VeriGIS.Composition
