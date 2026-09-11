/-
  ==========================================================================
   GeoProofBench · P-006
   文件 : formal/lean4/VeriGIS/Watershed.lean
   算子 : 流域唯一性(确定性 D8 流)
   对偶 : formal/dafny/P006_watershed.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件证明:在有限元胞集上,若存在严格下降后继函数,则每个轨道终止于不动点.
  这是 P-006 流域唯一性的代数基础.

  注意:本文件不涉及具体 DEM 数据结构,而是抽象为任意有限类型上的函数迭代.
-/

import Mathlib.Logic.Function.Iteration
import Mathlib.WellFounded

namespace VeriGIS.Watershed

open Function

/--
  严格下降条件:若非不动点,则后继的测度严格下降.
  其中 `f` 是后继函数, `m` 是取值为自然数的测度函数.
-/
theorem terminates {α : Type _} (f : α → α) (m : α → ℕ)
    (h : ∀ x, f x ≠ x → m (f x) < m x) (x : α) :
    ∃ n, f^[n] x = f^[n+1] x := by
  letI : WellFoundedRelation α := measure m
  induction' x using WellFounded.induction with x ih
  by_cases hfx : f x = x
  · -- 若 x 已是不动点,则取 n=0 即可.
    use 0
    simp [hfx]
  · -- 否则,对 f x 应用归纳假设 (因为 m (f x) < m x)
    have step : m (f x) < m x := h x hfx
    rcases ih (f x) step with ⟨n, hn⟩
    -- 则从 x 出发, n+1 步后到达不动点.
    use n+1
    -- 展开迭代定义: f^[n+1] x = f^[n] (f x) 且 f^[n+2] x = f^[n+1] (f x)
    rw [iterate_succ_apply, iterate_succ_apply, hn]
    rfl

-- ==========================================================================
-- 注:有限性条件未显式使用,因为测度下降条件已蕴含终止性.
-- 在具体 DEM 应用中,测度 m 可取为高程的整数编码,或为元胞到汇点的步数上界(有限性保证其存在).
-- ==========================================================================

end VeriGIS.Watershed
