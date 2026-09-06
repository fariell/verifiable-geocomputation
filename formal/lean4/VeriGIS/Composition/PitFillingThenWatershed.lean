/-
  ==========================================================================
   GeoProofBench · P-COMP-1 = P-002 ∘ P-006
   文件 : formal/lean4/VeriGIS/Composition/PitFillingThenWatershed.lean
   命题 : 填洼后,终止轨道的流域出口唯一
   对偶 : formal/dafny/PCOMP_1.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

    层 A 唯一性直接用 `Watershed.basin_unique`,不重写。
    终止前提:(i) floodMax 给出不高的已处理邻;(ii) 平面 D8 西向下降;
    (iii) P-006 第 6 条 `Nat.lt_wfRel`;(iv) 洼地窗口 NoFlow。
    种子层没有整幅 `DEM` / `pitFill2D` / `basin` 格网函数,故主定理
    落在已 export 的抽象后继 + 填洼标量核上(PROP_CHAIN §2.4)。
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.PitFilling2D
import VeriGIS.D8
import VeriGIS.Watershed
import VeriGIS.P006Terminate

namespace VeriGIS.Composition

open VeriGIS.PitFilling2D VeriGIS.D8 VeriGIS.Watershed VeriGIS.P006Terminate

/-- (i) W&L 抬邻居后,已处理格 `fillP` 不高于新的 `fill[n]`。 -/
theorem no_pit_implies_descent (origN fillP fillN : ℤ) :
    floodMax origN fillP fillN ≥ fillP :=
  le_trans (le_max_right origN fillP) (le_max_right fillN _)

/-- (i') 单行左出口扫描:西邻 ≤ 自身。 -/
theorem fill_strip_west_le (left y : ℤ) :
    left ≤ floodMax y left y := by
  rw [floodMax_left_scan]
  exact le_max_left left y

/-- (ii) 平面西向实例:后继高程严格低于中心。不复制 8 路分数表。 -/
theorem d8_preserves_descent_plane_west :
    nbr Dir.W (planeWin 1 0 0 1) < (planeWin 1 0 0 1).e := by
  simp [nbr, planeWin]
  norm_num

theorem d8_plane_west_is_west :
    d8 (planeWin 1 0 0 1) = Flow.to Dir.W :=
  example_plane_west

/-- (iv) 出口非空:3×3 洼地中心是 NoFlow。 -/
theorem boundary_nonempty :
    d8 ⟨1, 1, 1, 1, 0, 1, 1, 1, 1⟩ = Flow.noFlow :=
  example_pit

/-- (iii) 严格下降 ⇒ 轨道长度 ≤ 起点(第 6 条)。 -/
theorem orbit_length_bound (succ : ℕ → ℕ) (h : StrictDescent succ) (c : ℕ) :
    ∃ n ≤ c, succ (stepN succ n c) = stepN succ n c :=
  terminates_under_strict_descent succ h c

/-- (v) 填洼语境下的流域唯一:终止由 T6 供给,唯一性 import `basin_unique`。 -/
theorem pit_fill_then_watershed
    (succ : ℕ → ℕ) (h : StrictDescent succ) (c : ℕ) :
    ∃! o, ∃ n, stepN succ n c = o ∧ succ o = o := by
  obtain ⟨n, _hle, hf⟩ := terminates_under_strict_descent succ h c
  exact terminates_implies_basin succ c ⟨n, stepN succ n c, rfl, hf⟩

theorem pit_fill_then_watershed_unique
    (succ : ℕ → ℕ) (c o₁ o₂ : ℕ) (n₁ n₂ : ℕ)
    (h₁ : stepN succ n₁ c = o₁) (s₁ : succ o₁ = o₁)
    (h₂ : stepN succ n₂ c = o₂) (s₂ : succ o₂ = o₂) : o₁ = o₂ :=
  basin_unique succ c o₁ o₂ n₁ n₂ h₁ s₁ h₂ s₂

end VeriGIS.Composition
