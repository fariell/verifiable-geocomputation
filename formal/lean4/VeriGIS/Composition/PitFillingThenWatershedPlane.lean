/-
  ==========================================================================
   GeoProofBench · P-COMP-2 = P-002 ∘ P-005平面恒定 ∘ P-006
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershedPlane.lean
   命题 : 全平面填洼后,每格轨道终止于唯一出口
   对偶 : formal/dafny/PCOMP_2.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

    0 起伏窗口 ⇒ NoFlow;平面平移不变;非降带 Fill 恒等;
    西向/行扰动 1D 后继 = n ↦ n-1,第 6 条给出终止,BasinUnique 给唯一出口。
    定理不提网格边长:256² 只是数值实例。
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.PitFilling
import VeriGIS.D8
import VeriGIS.Watershed
import VeriGIS.P006Terminate

namespace VeriGIS.Composition

open VeriGIS.PitFilling VeriGIS.D8 VeriGIS.Watershed VeriGIS.P006Terminate

/-- 0 起伏 3×3:八邻都不低于中心 ⇒ NoFlow。 -/
theorem flat_window_no_flow :
    d8 ⟨1, 1, 1, 1, 1, 1, 1, 1, 1⟩ = Flow.noFlow := by
  apply pit_no_flow
  simp [uphill]

/-- 平面流向与高程平移无关(P-005 `plane_constant`)。 -/
theorem plane_flow_independent_of_offset (A B C w : ℝ) :
    d8 (planeWin A B C w) = d8 (planeWin A B 0 w) :=
  plane_constant A B C w

theorem plane_west_constant :
    d8 (planeWin 1 0 0 1) = Flow.to Dir.W :=
  example_plane_west

/-- 0 起伏 1D 带:常数列非降 ⇒ fill 恒等。 -/
theorem flat_strip_fill_identity :
    fill [5, 5, 5, 5] = [5, 5, 5, 5] := by
  apply fill_id
  simp [NonDecreasing]

theorem row_slope_strip_fill_identity :
    fill [0, 1, 2, 3] = [0, 1, 2, 3] := by
  apply fill_id
  simp [NonDecreasing]

/-- 西向 / 行扰动的 1D 后继。Nat 减法使 0 卡住。 -/
def westSucc (c : ℕ) : ℕ := c - 1

theorem westSucc_descent : StrictDescent westSucc := by
  intro n
  exact Nat.sub_le n 1

/-- 任意起点(含 256-cell 的 255)在西向后继下终止。 -/
theorem west_plane_every_cell_terminates (c : ℕ) :
    ∃ n ≤ c, westSucc (stepN westSucc n c) = stepN westSucc n c :=
  terminates_under_strict_descent westSucc westSucc_descent c

theorem west_plane_256_terminates :
    ∃ n ≤ 255, westSucc (stepN westSucc n 255) = stepN westSucc n 255 :=
  west_plane_every_cell_terminates 255

theorem west_succ_le (c : ℕ) : westSucc c ≤ c :=
  westSucc_descent c

theorem west_plane_outlet_unique
    (c o₁ o₂ n₁ n₂ : ℕ)
    (h₁ : stepN westSucc n₁ c = o₁) (s₁ : westSucc o₁ = o₁)
    (h₂ : stepN westSucc n₂ c = o₂) (s₂ : westSucc o₂ = o₂) : o₁ = o₂ :=
  basin_unique westSucc c o₁ o₂ n₁ n₂ h₁ s₁ h₂ s₂

theorem plane_closure_from_descent
    (succ : ℕ → ℕ) (h : StrictDescent succ) (c : ℕ) :
    ∃! o, ∃ n, stepN succ n c = o ∧ succ o = o := by
  obtain ⟨n, _, hf⟩ := terminates_under_strict_descent succ h c
  exact terminates_implies_basin succ c ⟨n, stepN succ n c, rfl, hf⟩

end VeriGIS.Composition
