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

    1. 本文件使用 Lean 的数学库和战术来证明性质,而不是依赖于 Dafny 的 SMT 自动化。
    2. 证明风格:Lean 靠显式战术(`induction`, `cases`, `simp`, `linarith`等)。

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
  let mut queue := Std.PriorityQueue.empty (fun x y => x < y)
  for i in [0:a.size] do
    if i = 0 then
      queue := queue.push (0, a[i])
    else
      let minNbr := if i > 0 then a[i-1] else a[i]
      if a[i] < minNbr then
        fill := fill.set! i minNbr
        queue := queue.push (i, minNbr)
  while let some (idx, val) := queue.popMin? do
    if idx + 1 < a.size then
      let nextVal := fill[idx + 1]
      let minNbr := if idx + 1 > 0 then fill[idx] else fill[idx + 1]
      if nextVal < minNbr then
        fill := fill.set! (idx + 1) minNbr
        queue := queue.push (idx + 1, minNbr)
  fill

-- ==========================================================================
-- 算子性质
-- ==========================================================================

/-- 1D left-outlet Fill 操作符产生非递减序列 -/
theorem pitFill1D_nondecreasing (a : Array ℝ) (i : Nat) (h : i < a.size - 1) :
  (pitFill1D a)[i] ≤ (pitFill1D a)[i+1] := by
  let fill := pitFill1D a
  induction i with i hi
  case zero =>
    simp [pitFill1D, Array.get, Array.set, Array.map, Array.size]
    linarith
  case succ =>
    simp [pitFill1D, Array.get, Array.set, Array.map, Array.size]
    cases h : i < a.size - 1
    case true =>
      have h1 : (pitFill1D a)[i] ≤ (pitFill1D a)[i+1] := hi
      have h2 : (pitFill1D a)[i+1] ≤ (pitFill1D a)[i+2] := by
        simp [pitFill1D, Array.get, Array.set, Array.map, Array.size]
        linarith
      linarith [h1, h2]
    case false =>
      simp [pitFill1D, Array.get, Array.set, Array.map, Array.size]
      linarith

-- ==========================================================================
-- 冒烟测试(非命题,仅确认算子可计算)
-- ==========================================================================

example : (pitFill1D #[0, 1, 2, 3, 4, 5, 6, 7, 8, 9])[3] = 3 := by
  simp [pitFill1D, Array.get, Array.set, Array.map, Array.size]
  norm_num

example : (pitFill1D #[10, 9, 8, 7, 6, 5, 4, 3, 2, 1])[3] = 10 := by
  simp [pitFill1D, Array.get, Array.set, Array.map, Array.size]
  norm_num

end -- noncomputable section

end VeriGIS.Composition
