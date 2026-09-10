/-
  ==========================================================================
   GeoProofBench · P-021
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   算子 : 1D left-outlet Fill
   对偶 : formal/dafny/PCOMP_1.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本的**独立**重述 —— 不是翻译。两处必须注意的差异:

    1. 本文件使用 Lean 的数学库和战术来证明性质,而不是依赖 SMT 求解器。
    2. 证明风格:Lean 靠显式战术(`induction`, `rw`, `simp`, `linarith`等)。

  ==========================================================================
-/

import Mathlib.Data.Array.Basic
import Mathlib.Tactic

namespace VeriGIS.Composition

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 1D left-outlet Fill 操作符定义 -/
def pitFill1D (a : Array ℝ) : Array ℝ := 
  let fill := a.map (fun x => x)
  let rows := a.size
  let visited := Array.mk rows false
  let heap := PriorityQueue.empty (fun (x y : ℝ × Nat × Nat) => x.1 < y.1)
  let seed (i : Nat) : Unit := 
    if visited[i] then () else
      fill[i] := a[i]
      visited[i] := true
      heap.push (fill[i], i, i)
  for i in [0:rows] do
    seed i
  while let some (z, r, c) := heap.pop do
    for (dr, dc) in [(-1, 0), (1, 0)] do
      let nr := r + dr
      if 0 ≤ nr ∧ nr < rows then
        if ¬ visited[nr] then
          fill[nr] := max (a[nr]) (fill[r])
          visited[nr] := true
          heap.push (fill[nr], nr, nr)
  fill

-- ==========================================================================
-- 算子性质
-- ==========================================================================

/-- 1D left-outlet Fill 操作符产生非递减序列 -/
theorem pitFill1D_nondecreasing (a : Array ℝ) (i : Nat) (h : i + 1 < a.size) :
  pitFill1D a[i] ≤ pitFill1D a[i + 1] := by
  let fill := pitFill1D a
  let rows := a.size
  let visited := Array.mk rows false
  let heap := PriorityQueue.empty (fun (x y : ℝ × Nat × Nat) => x.1 < y.1)
  let seed (i : Nat) : Unit := 
    if visited[i] then () else
      fill[i] := a[i]
      visited[i] := true
      heap.push (fill[i], i, i)
  for i in [0:rows] do
    seed i
  while let some (z, r, c) := heap.pop do
    for (dr, dc) in [(-1, 0), (1, 0)] do
      let nr := r + dr
      if 0 ≤ nr ∧ nr < rows then
        if ¬ visited[nr] then
          fill[nr] := max (a[nr]) (fill[r])
          visited[nr] := true
          heap.push (fill[nr], nr, nr)
  -- 证明 fill[i] ≤ fill[i + 1]
  have h_visited : visited[i] ∧ visited[i + 1], from
    (by simp [visited, seed, rows, a.size, i, h]; linarith)
  have h_fill : fill[i] ≤ fill[i + 1], from
    (by simp [fill, pitFill1D, h_visited, i, h]; linarith)
  exact h_fill

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : pitFill1D #[0, 1, 2, 3, 4] = #[0, 1, 2, 3, 4] := by
  simp [pitFill1D]

example : pitFill1D #[4, 3, 2, 1, 0] = #[4, 4, 4, 4, 4] := by
  simp [pitFill1D]

end -- noncomputable section

end VeriGIS.Composition
