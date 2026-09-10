/-
  ==========================================================================
   GeoProofBench · P-019
   文件 : formal/lean4/VeriGIS/HornSlope.lean
   算子 : Horn (1981) 有限差分坡度
   对偶 : formal/dafny/P019_slope_nonnegative.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  命题：对于任意 3×3 高程窗口和正网格间距 w，Horn 坡度平方 SlopeSq 非负。
  此性质对任意高程成立，不仅限于平面表面。

  覆盖：
    GPB-001 的推广：从平面精确性到任意高程的非负性
    Horn 坡度算子的数学性质：平方和形式保证非负性
    网格间距 w > 0 的物理意义
  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下)，与 Horn (1981) 原始定义一致。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  网格间距 w > 0，高程值 a..i 为任意实数。
-/

/-- Horn (1981) 有限差分坡度算子的 x 方向分量 -/
def dzdx (a b c d f g h i w : ℝ) : ℝ :=
  ((c + 2 * f + i) - (a + 2 * d + g)) / (8 * w)

/-- Horn (1981) 有限差分坡度算子的 y 方向分量 -/
def dzdy (a b c d f g h i w : ℝ) : ℝ :=
  ((g + 2 * h + i) - (a + 2 * b + c)) / (8 * w)

/-- Horn 坡度平方：dzdx² + dzdy² -/
def slopeSq (a b c d e f g h i w : ℝ) : ℝ :=
  (dzdx a b c d f g h i w) ^ 2 + (dzdy a b c d f g h i w) ^ 2

/-- 主定理：对于任意高程和正网格间距，Horn 坡度平方非负 -/
theorem horn_slope_sq_nonneg
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    0 ≤ slopeSq a b c d e f g h i w := by
  unfold slopeSq
  have h1 : 0 ≤ (dzdx a b c d f g h i w) ^ 2 := pow_two_nonneg _
  have h2 : 0 ≤ (dzdy a b c d f g h i w) ^ 2 := pow_two_nonneg _
  nlinarith

/-- 更强的形式：坡度平方是 dzdx 和 dzdy 的平方和 -/
theorem slopeSq_eq_sum_squares
    (a b c d e f g h i w : ℝ) :
    slopeSq a b c d e f g h i w =
      (dzdx a b c d f g h i w) ^ 2 + (dzdy a b c d f g h i w) ^ 2 :=
  rfl

/-- 当且仅当 dzdx 和 dzdy 同时为零时，坡度平方为零 -/
theorem slopeSq_eq_zero_iff
    (a b c d e f g h i w : ℝ) (hw : w > 0) :
    slopeSq a b c d e f g h i w = 0 ↔
      dzdx a b c d f g h i w = 0 ∧ dzdy a b c d f g h i w = 0 := by
  constructor
  · intro h
    unfold slopeSq at h
    have hdx : dzdx a b c d f g h i w = 0 := by
      have h1 : (dzdx a b c d f g h i w) ^ 2 = 0 := by
        nlinarith
      exact pow_eq_zero h1
    have hdy : dzdy a b c d f g h i w = 0 := by
      have h2 : (dzdy a b c d f g h i w) ^ 2 = 0 := by
        nlinarith
      exact pow_eq_zero h2
    exact ⟨hdx, hdy⟩
  · intro ⟨hdx, hdy⟩
    unfold slopeSq
    rw [hdx, hdy]
    simp

/-- 网格间距缩放不变性：坡度平方与 w² 成反比 -/
theorem slopeSq_scaling
    (a b c d e f g h i w k : ℝ) (hw : w > 0) (hk : k > 0) :
    slopeSq a b c d e f g h i (k * w) =
      (1 / k ^ 2) * slopeSq a b c d e f g h i w := by
  unfold slopeSq dzdx dzdy
  field_simp [show k * w ≠ 0 from mul_ne_zero hk.ne' hw.ne']
  ring

/-- 高程平移不变性：所有高程加同一常数不影响坡度平方 -/
theorem slopeSq_translation_invariant
    (a b c d e f g h i w K : ℝ) (hw : w > 0) :
    slopeSq (a + K) (b + K) (c + K) (d + K) (e + K) (f + K) (g + K) (h + K) (i + K) w =
      slopeSq a b c d e f g h i w := by
  unfold slopeSq dzdx dzdy
  ring

/-- 平面表面的特殊情况：坡度平方等于解析斜率的平方 -/
theorem slopeSq_exact_on_plane
    (A B C D E F w : ℝ) (hw : w > 0) :
    let a := A * (-w) + B * (-w) + C * (-w) * (-w) + D * (-w) + E * (-w) + F
        b := A * 0 + B * (-w) + C * 0 * (-w) + D * 0 + E * (-w) + F
        c := A * w + B * (-w) + C * w * (-w) + D * w + E * (-w) + F
        d := A * (-w) + B * 0 + C * (-w) * 0 + D * (-w) + E * 0 + F
        e := A * 0 + B * 0 + C * 0 * 0 + D * 0 + E * 0 + F
        f := A * w + B * 0 + C * w * 0 + D * w + E * 0 + F
        g := A * (-w) + B * w + C * (-w) * w + D * (-w) + E * w + F
        h := A * 0 + B * w + C * 0 * w + D * 0 + E * w + F
        i := A * w + B * w + C * w * w + D * w + E * w + F
    slopeSq a b c d e f g h i w = (A ^ 2 + B ^ 2) := by
  intro a b c d e f g h i
  unfold slopeSq dzdx dzdy
  field_simp [hw.ne']
  ring

end

end VeriGIS.HornSlope
