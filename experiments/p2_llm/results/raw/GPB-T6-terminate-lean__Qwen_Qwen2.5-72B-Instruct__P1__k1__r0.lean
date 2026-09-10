/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   算子 : Watershed under D8 flow
   对偶 : formal/dafny/P006_watershed.dfy  (Dafny 4.11, 19 verified 0 errors)
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

namespace VeriGIS.Watershed

-- ==========================================================================
-- D8 流向定义
-- ==========================================================================

/-- D8 流向定义,返回下一个流向的坐标。 -/
def d8At (h : Array (Array ℝ)) (r c : Nat) : Option (Nat × Nat) := do
  let (dp, dq) := DIRS.find? (λ (dname, dp, dq, dist2) => dname == d8AtName h r c) |>.get!
  let nr := r + dq
  let nc := c + dp
  if 0 ≤ nr ∧ nr < h.size.1 ∧ 0 ≤ nc ∧ nc < h.size.2 then
    return (nr, nc)
  else
    return none

/-- D8 流向名称定义,返回流向的名称。 -/
def d8AtName (h : Array (Array ℝ)) (r c : Nat) : String := 
  let neighbors := [(r-1, c-1), (r-1, c), (r-1, c+1), (r, c+1), (r+1, c+1), (r+1, c), (r+1, c-1), (r, c-1)]
  let slopes := neighbors.map (λ (nr, nc) => if 0 ≤ nr ∧ nr < h.size.1 ∧ 0 ≤ nc ∧ nc < h.size.2 then h[nr][nc] - h[r][c] else 0)
  let minSlope := slopes.min
  let minIndex := slopes.indexOf minSlope
  DIRS[minIndex].1

-- ==========================================================================
-- 严格下降后继
-- ==========================================================================

/-- 严格下降后继定义,返回下一个严格下降的坐标。 -/
def strictDescentSucc (h : Array (Array ℝ)) (r c : Nat) : Option (Nat × Nat) := do
  let (nr, nc) := d8At h r c |>.get!
  if h[nr][nc] < h[r][c] then
    return (nr, nc)
  else
    return none

-- ==========================================================================
-- 终止于固定点
-- ==========================================================================

/-- 每个轨道最终终止于一个固定点。 -/
theorem orbitTerminatesAtFixedPoint (h : Array (Array ℝ)) (r c : Nat) (max_steps : Nat) :
  ∃ (fixedPoint : Nat × Nat), (∀ (n : Nat), n < max_steps → (strictDescentSucc h r c).recOn (λ (nr, nc) => strictDescentSucc h nr nc) (λ _ => (r, c)) n = fixedPoint := by
  -- 使用归纳法证明
  induction max_steps with max_steps ih
  -- 基础情况: max_steps = 0
  case zero => 
    use (r, c)
    intro n h
    rw [ih]
    simp
  -- 归纳步骤: max_steps > 0
  case succ =>
    have h_next := strictDescentSucc h r c
    cases h_next with
    -- 如果没有严格下降的后继,则 (r, c) 本身是固定点
    case none =>
      use (r, c)
      intro n h
      simp
    -- 如果有严格下降的后继,则递归调用归纳假设
    case some (nr, nc) =>
      have ih' := ih (nr, nc)
      use (nr, nc)
      intro n h
      rw [ih']
      simp

-- ==========================================================================
-- 人工构造的平坦 4-环
-- ==========================================================================

/-- 人工构造的平坦 4-环,轨道不会终止。 -/
def flat4Ring (h : Array (Array ℝ)) (r c : Nat) (max_steps : Nat) : Option (Nat × Nat) := do
  let path := [(r, c)]
  for _ in [0:max_steps] do
    let (nr, nc) := RING_SUCC[(r, c)] |>.get!
    if (nr, nc) = (r, c) then
      return (nr, nc)
    else
      path := path.push (nr, nc)
      if path.size ≠ path.toSet.size then
        return (nr, nc)
  return none

/-- 人工构造的平坦 4-环,轨道不会终止。 -/
theorem flat4RingDoesNotTerminate (h : Array (Array ℝ)) (r c : Nat) (max_steps : Nat) :
  ¬ (∃ (fixedPoint : Nat × Nat), (∀ (n : Nat), n < max_steps → (flat4Ring h r c).recOn (λ (nr, nc) => flat4Ring h nr nc) (λ _ => (r, c)) n = fixedPoint) := by
  -- 构造一个反例
  let h := Array.ofFn (λ _ => Array.ofFn (λ _ => 0))
  let r := 0
  let c := 0
  let max_steps := 4
  have h_path := flat4Ring h r c max_steps
  cases h_path with
  case none =>
    -- 如果路径为空,则不存在固定点
    intro h_fixed
    cases h_fixed with
    case exists (fixedPoint, h_fixedPoint) =>
      have h_path_fixed := h_fixedPoint 0
      contradiction
  case some (nr, nc) =>
    -- 如果路径不为空,则检查路径是否包含重复点
    have h_path := flat4Ring h r c max_steps
    cases h with
    case some (path, h_path) =>
      have h_path_size := path.size
      have h_path_set_size := path.toSet.size
      have h_path_size_ne_set_size : h_path_size ≠ h_path_set_size := by
        simp
        norm_num
      contradiction

end -- noncomputable section

end VeriGIS.Watershed
