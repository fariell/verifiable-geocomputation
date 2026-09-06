/-
  ==========================================================================
   GeoProofBench · P-002-bis
   文件 : formal/lean4/VeriGIS/PitFilling2D.lean
   算子 : Wang & Liu 2D 邻域抬升的标量核 + 单行还原
   对偶 : formal/dafny/P002_pit_filling_2d.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  Dafny 在栅格上写 RaiseNbr;Lean 把同一步收成标量 `floodMax`,再证明
  单行扫描就是 `PitFilling.fill`。不证堆的 O(n log n) 弹出即终态。

    GPB-024  floodMax 不降低当前填高、且不低于 orig[n]
    GPB-025  结果只依赖 (orig[n], fill[p], fill[n]),fill[p] 不被回写
    GPB-026  左出口单行扫描 ≡ `PitFilling.fill`
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.PitFilling

namespace VeriGIS.PitFilling2D

/-- W&L 对邻居 n 的一次抬升: `fill[n] := max(fill[n], max(orig[n], fill[p]))`. -/
def floodMax (origN fillP fillN : ℤ) : ℤ :=
  max fillN (max origN fillP)

-- ==========================================================================
-- GPB-024 · 不降低
-- ==========================================================================

theorem floodMax_ge_fillN (origN fillP fillN : ℤ) :
    floodMax origN fillP fillN ≥ fillN := by
  simp [floodMax]

theorem floodMax_ge_origN (origN fillP fillN : ℤ) :
    floodMax origN fillP fillN ≥ origN :=
  le_trans (le_max_left origN fillP) (le_max_right fillN _)

-- ==========================================================================
-- GPB-025 · p 的填高只作输入
-- ==========================================================================

theorem floodMax_ignores_rewriting_p (origN fillP fillN : ℤ) :
    floodMax origN fillP fillN = max fillN (max origN fillP) := rfl

theorem floodMax_stable_of_already_ge
    (origN fillP fillN : ℤ) (h : max origN fillP ≤ fillN) :
    floodMax origN fillP fillN = fillN := by
  simp [floodMax, max_eq_left h]

-- ==========================================================================
-- GPB-026 · 单行、左出口、依次抬升 ≡ 1D fill
-- ==========================================================================

theorem floodMax_left_scan (y left : ℤ) :
    floodMax y left y = max left y := by
  simp only [floodMax]
  rw [← max_assoc, max_self, max_comm]

def fillStripGo (left : ℤ) : List ℤ → List ℤ
  | [] => []
  | y :: ys =>
      let y' := floodMax y left y
      y' :: fillStripGo y' ys

def fillStrip : List ℤ → List ℤ
  | [] => []
  | x :: xs => x :: fillStripGo x xs

theorem fillStripGo_eq_fill_go (acc : ℤ) (xs : List ℤ) :
    fillStripGo acc xs = VeriGIS.PitFilling.fill.go acc xs := by
  induction xs generalizing acc with
  | nil => rfl
  | cons y ys ih =>
      simp [fillStripGo, VeriGIS.PitFilling.fill.go, floodMax_left_scan]
      exact ih _

theorem fillStrip_eq_fill (a : List ℤ) :
    fillStrip a = VeriGIS.PitFilling.fill a := by
  cases a with
  | nil => rfl
  | cons x xs =>
      simp [fillStrip, VeriGIS.PitFilling.fill, fillStripGo_eq_fill_go]

-- 3×3 中心洼地: orig[n]=0, 北邻 fill[p]=1, 当前 fill[n]=0 → 抬到 1
theorem example_center_pit : floodMax 0 1 0 = 1 := rfl

end VeriGIS.PitFilling2D
