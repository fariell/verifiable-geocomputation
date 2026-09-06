/-
  ==========================================================================
   GeoProofBench · P-006 第 6 条
   文件 : formal/lean4/VeriGIS/P006Terminate.lean
   命题 : 严格下降(高程嵌进 ℕ) ⇒ 轨道有限步到达不动点
   对偶 : formal/dafny/P006_terminate_under_strict.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

    良基关系是 `Nat.lt_wfRel`(`<` on ℕ)。不递归搜索不动点。
    P-COMP-1 §2.4 (iii) 引用 `terminates_under_strict_descent`。
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.Watershed

namespace VeriGIS.P006Terminate

open VeriGIS.Watershed

def StrictDescent (succ : ℕ → ℕ) : Prop :=
  ∀ n, succ n ≤ n

lemma stepN_succ_head (succ : ℕ → ℕ) (c k : ℕ) :
    stepN succ (k + 1) c = stepN succ k (succ c) := by
  calc
    stepN succ (k + 1) c = stepN succ (1 + k) c := by rw [Nat.add_comm]
    _ = stepN succ k (stepN succ 1 c) := stepN_add succ c 1 k
    _ = stepN succ k (succ c) := by simp [stepN]

/-- 高程作为 `ℕ` 度量时,每步不增且非不动点则严格变小 ⇒ 轨道终止。 -/
theorem terminates_under_strict_descent
    (succ : ℕ → ℕ) (h : StrictDescent succ) (c : ℕ) :
    ∃ n ≤ c, succ (stepN succ n c) = stepN succ n c := by
  have wf : WellFounded (α := ℕ) (· < ·) := Nat.lt_wfRel.wf
  apply wf.induction
    (C := fun c => ∃ n ≤ c, succ (stepN succ n c) = stepN succ n c) c
  intro c ih
  by_cases hs : succ c = c
  · refine ⟨0, Nat.zero_le c, ?_⟩
    simp [stepN, hs]
  · have hlt : succ c < c := Nat.lt_of_le_of_ne (h c) hs
    obtain ⟨k, hk_le, hk⟩ := ih (succ c) hlt
    refine ⟨k + 1, ?le, ?fix⟩
    · have hk1 : k + 1 ≤ succ c + 1 := Nat.add_le_add_right hk_le 1
      have hs1 : succ c + 1 ≤ c := Nat.succ_le_of_lt hlt
      omega
    · rw [stepN_succ_head, hk]

end VeriGIS.P006Terminate
