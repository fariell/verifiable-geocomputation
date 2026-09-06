/-
  ==========================================================================
   GeoProofBench · P-COMP-5 填洼元性质
   文件 : formal/lean4/VeriGIS/Composition/PitFillingIdempotent.lean
   命题 : fill ∘ fill = fill; floodMax 双亲交换; 四条 1D 实例
   对偶 : formal/dafny/PCOMP_5_idempotent.dfy(独立重述,不翻译)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================
-/

import Mathlib.Tactic
import VeriGIS.PitFilling
import VeriGIS.PitFilling2D

namespace VeriGIS.Composition

open VeriGIS.PitFilling VeriGIS.PitFilling2D

theorem fill_idempotent (a : List ℤ) : fill (fill a) = fill a :=
  fill_idem a

theorem floodMax_parent_schedule (orig p1 p2 n : ℤ) :
    floodMax orig p2 (floodMax orig p1 n) = floodMax orig p1 (floodMax orig p2 n) := by
  simp [floodMax]
  ac_rfl

theorem hash_plane : fill [5, 5, 5, 5] = [5, 5, 5, 5] := by native_decide
theorem hash_pit : fill [3, 1, 4] = [3, 3, 4] := by native_decide
theorem hash_slope : fill [0, 1, 2, 3] = [0, 1, 2, 3] := by native_decide
theorem hash_cascade : fill [3, 1, 0] = [3, 3, 3] := by native_decide

theorem twice_pit : fill (fill [3, 1, 4]) = fill [3, 1, 4] :=
  fill_idempotent [3, 1, 4]

end VeriGIS.Composition
