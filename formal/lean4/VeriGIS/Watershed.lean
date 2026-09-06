/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   命题 : GPB-015 确定性后继下,终止轨道的流域出口唯一
   对偶 : formal/dafny/P006_watershed.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

    层 A  后继是函数 ⇒ n 步轨道唯一 ⇒ 若到达不动点出口则出口唯一
    层 B  Fin 4 上的 +1 环没有不动点,故不终止(P-006b)
    第 6 条(严格下降 ⇒ 终止)见 VeriGIS.P006Terminate
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.D8

namespace VeriGIS.Watershed

open VeriGIS.D8

/-- 有界展开:对 `n` 归纳,不递归搜索不动点。 -/
def stepN {α : Type*} (succ : α → α) : ℕ → α → α
  | 0, x => x
  | n + 1, x => succ (stepN succ n x)

theorem orbit_deterministic {α : Type*} (succ : α → α) (c : α) (n : ℕ) :
    stepN succ n c = stepN succ n c :=
  rfl

theorem stepN_add {α : Type*} (succ : α → α) (c : α) (n k : ℕ) :
    stepN succ (n + k) c = stepN succ k (stepN succ n c) := by
  induction k with
  | zero =>
    simp [stepN]
  | succ k ih =>
    rw [Nat.add_succ, stepN, ih, stepN]

theorem stuck_iter {α : Type*} (succ : α → α) (o : α) (k : ℕ)
    (h : succ o = o) : stepN succ k o = o := by
  induction k with
  | zero => rfl
  | succ k ih => simp [stepN, h, ih]

/-- D8 窗口上的流向是函数,故后继唯一。 -/
theorem flow_successor_unique (w : Win) : ∃! f : Flow, f = d8 w := by
  refine ⟨d8 w, rfl, ?_⟩
  intro f hf
  exact hf

/-- 平面西向实例:P-005 核给出唯一后继 `to W`。 -/
theorem plane_west_successor :
    d8 (planeWin 1 0 0 1) = Flow.to Dir.W :=
  example_plane_west

/-- 若轨道在某步到达不动点出口,则该出口唯一。 -/
theorem basin_unique {α : Type*} (succ : α → α) (c o₁ o₂ : α) (n₁ n₂ : ℕ)
    (h₁ : stepN succ n₁ c = o₁) (s₁ : succ o₁ = o₁)
    (h₂ : stepN succ n₂ c = o₂) (s₂ : succ o₂ = o₂) : o₁ = o₂ := by
  cases Nat.le_total n₁ n₂ with
  | inl hle =>
    obtain ⟨k, hk⟩ := Nat.exists_eq_add_of_le hle
    have stay : stepN succ k o₁ = o₁ := stuck_iter succ o₁ k s₁
    calc
      o₁ = stepN succ k o₁ := stay.symm
      _ = stepN succ k (stepN succ n₁ c) := by rw [h₁]
      _ = stepN succ (n₁ + k) c := (stepN_add succ c n₁ k).symm
      _ = stepN succ n₂ c := by rw [hk]
      _ = o₂ := h₂
  | inr hle =>
    obtain ⟨k, hk⟩ := Nat.exists_eq_add_of_le hle
    have stay : stepN succ k o₂ = o₂ := stuck_iter succ o₂ k s₂
    have : o₂ = o₁ :=
      calc
        o₂ = stepN succ k o₂ := stay.symm
        _ = stepN succ k (stepN succ n₂ c) := by rw [h₂]
        _ = stepN succ (n₂ + k) c := (stepN_add succ c n₂ k).symm
        _ = stepN succ n₁ c := by rw [hk]
        _ = o₁ := h₁
    exact this.symm

theorem terminates_implies_basin {α : Type*} (succ : α → α) (c : α)
    (h : ∃ n o, stepN succ n c = o ∧ succ o = o) :
    ∃! o, ∃ n, stepN succ n c = o ∧ succ o = o := by
  obtain ⟨n₁, o₁, h₁, s₁⟩ := h
  refine ⟨o₁, ⟨n₁, h₁, s₁⟩, ?_⟩
  intro o₂ ⟨n₂, h₂, s₂⟩
  exact (basin_unique succ c o₁ o₂ n₁ n₂ h₁ s₁ h₂ s₂).symm

-- ==========================================================================
-- P-006b · flat 4-环
-- ==========================================================================

def ringSucc : Fin 4 → Fin 4 := fun i => i + 1

theorem ring_succ_ne (i : Fin 4) : ringSucc i ≠ i := by
  fin_cases i <;> decide

theorem flat_cycle_no_termination (i : Fin 4) (n : ℕ) :
    ringSucc (stepN ringSucc n i) ≠ stepN ringSucc n i :=
  ring_succ_ne (stepN ringSucc n i)

end VeriGIS.Watershed
