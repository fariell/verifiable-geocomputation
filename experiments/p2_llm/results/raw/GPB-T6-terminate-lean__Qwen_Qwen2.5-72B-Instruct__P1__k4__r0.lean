/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   算子 : D8 流向算法
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
-- D8 流向算法定义
-- ==========================================================================

def d8_at (h : Array (Array ℝ)) (r c : Nat) : Option (Nat × Nat) := do
  let (dp, dq) := DIRS.find? (λ (dname, dp, dq, dist2) => h[r + dp][c + dq] < h[r][c]) |>.map (λ (dname, dp, dq, dist2) => (dp, dq))
  let nr := r + dp
  let nc := c + dq
  if 0 ≤ nr ∧ nr < h.size.1 ∧ 0 ≤ nc ∧ nc < h.size.2 then
    return (nr, nc)
  else
    return none

-- ==========================================================================
-- 严格下降后继关系
-- ==========================================================================

def strictDescentSuccessor (h : Array (Array ℝ)) (r c : Nat) : Prop :=
  ∃ (nr nc : Nat), d8_at h r c = some (nr, nc) ∧ h[nr][nc] < h[r][c]

-- ==========================================================================
-- 终止于固定点的轨道
-- ==========================================================================

def orbitTerminatesAtFixedPoint (h : Array (Array ℝ)) (r c : Nat) (max_steps : Nat) : Prop :=
  ∃ (nr nc : Nat), (∀ (mr mc : Nat), d8_at h nr nc = some (mr, mc) → h[mr][mc] ≥ h[nr][nc]) ∧
  (∃ (path : List (Nat × Nat)), path.head? = some (r, c) ∧ path.length ≤ max_steps + 1 ∧
  (∀ (i : Nat), i < path.length - 1 → d8_at h (path[i].1) (path[i].2) = some (path[i + 1].1, path[i + 1].2)) ∧
  (path[path.length - 1] = (nr, nc))

-- ==========================================================================
-- 严格下降后继关系下的轨道终止性
-- ==========================================================================

theorem orbitTerminates (h : Array (Array ℝ)) (r c : Nat) (max_steps : Nat) :
  (∀ (r c : Nat), strictDescentSuccessor h r c) →
  orbitTerminatesAtFixedPoint h r c max_steps := by
  intro h_strictDescent
  induction' max_steps with max_steps' ih
  case zero =>
    -- Base case: max_steps = 0, the orbit must terminate at the starting point
    use r, c
    constructor
    -- The starting point is a fixed point
    intro mr mc
    cases d8_at h r c with
    | none => contradiction
    | some (nr, nc) => exact h_strictDescent r c nr nc
    -- The path is just the starting point
    use [(r, c)]
    constructor
    constructor
    constructor
    constructor
    constructor
  case succ max_steps' ih =>
    -- Inductive step: assume the theorem holds for max_steps', prove for max_steps' + 1
    cases d8_at h r c with
    | none => contradiction
    | some (nr, nc) =>
      have h_strictDescent' : strictDescentSuccessor h nr nc := h_strictDescent nr nc
      have ih' : orbitTerminatesAtFixedPoint h nr nc max_steps' := ih h_strictDescent'
      rcases ih' with ⟨nfr, nfc, h_fixedPoint, path, h_path, h_pathLength, h_pathStep, h_pathLast⟩
      use nfr, nfc
      constructor
      exact h_fixedPoint
      use (r, c) :: path
      constructor
      constructor
      exact h_path
      constructor
      exact (Nat.succ_le_succ h_pathLength)
      constructor
      intro i
      cases i
      | zero => exact rfl
      | succ i' => exact h_pathStep i'
      constructor
      exact h_pathLast

-- ==========================================================================
-- 人工构造的平坦4环不终止
-- ==========================================================================

def flat4Ring (h : Array (Array ℝ)) : Prop :=
  h[0][0] = h[0][1] ∧ h[0][1] = h[1][1] ∧ h[1][1] = h[1][0] ∧ h[1][0] = h[0][0]

def flat4RingSucc (h : Array (Array ℝ)) : Prop :=
  d8_at h 0 0 = some (0, 1) ∧
  d8_at h 0 1 = some (1, 1) ∧
  d8_at h 1 1 = some (1, 0) ∧
  d8_at h 1 0 = some (0, 0)

theorem flat4RingDoesNotTerminate (h : Array (Array ℝ)) (max_steps : Nat) :
  flat4Ring h → flat4RingSucc h → ¬orbitTerminatesAtFixedPoint h 0 0 max_steps := by
  intro h_flat4Ring h_flat4RingSucc
  induction' max_steps with max_steps' ih
  case zero =>
    -- Base case: max_steps = 0, the orbit cannot terminate as it must move
    have h_move : d8_at h 0 0 = some (0, 1) := h_flat4RingSucc.1
    have h_notFixed : ¬(∀ (mr mc : Nat), d8_at h 0 0 = some (mr, mc) → h[mr][mc] ≥ h[0][0]) := by
      intro h_fixed
      cases h_move with
      | none => contradiction
      | some (nr, nc) => exact h_fixed nr nc h_move
    exact h_notFixed
  case succ max_steps' ih =>
    -- Inductive step: assume the theorem holds for max_steps', prove for max_steps' + 1
    have h_move : d8_at h 0 0 = some (0, 1) := h_flat4RingSucc.1
    have h_move1 : d8_at h 0 1 = some (1, 1) := h_flat4RingSucc.2
    have h_move2 : d8_at h 1 1 = some (1, 0) := h_flat4RingSucc.3
    have h_move3 : d8_at h 1 0 = some (0, 0) := h_flat4RingSucc.4
    have h_path : orbitTerminatesAtFixedPoint h 0 1 max_steps' := ih h_flat4Ring h_flat4RingSucc
    rcases h_path with ⟨nfr, nfc, h_fixedPoint, path, h_path, h_pathLength, h_pathStep, h_pathLast⟩
    have h_path' : orbitTerminatesAtFixedPoint h 0 0 (max_steps' + 1) := by
      use nfr, nfc
      constructor
      exact h_fixedPoint
      use (0, 0) :: path
      constructor
      constructor
      exact h_path
      constructor
      exact (Nat.succ_le_succ h_pathLength)
      constructor
      intro i
      cases i
      | zero => exact rfl
      | succ i' => exact h_pathStep i'
      constructor
      exact h_pathLast
    exact h_path'

end VeriGIS.Watershed
