/-
  ==========================================================================
   GeoProofBench · P-001
   文件 : formal/lean4/VeriGIS/HornSlope.lean
   算子 : Horn (1981) 有限差分坡度平方
   对偶 : experiments/phase1/gpb019_consistency.py
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  证明 Horn (1981) 坡度平方算子对任意 3×3 高程窗口和正网格间距 w 非负。
  该性质对任意高程表面成立，不限于平面。

  算子定义:
    SlopeSq = [(f - d)/(2w)]² + [(b - h)/(2w)]²

  覆盖:
    GPB-019 代数核: 坡度平方非负性
    Phase 1 核心算子基础性质
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.HornSlope

noncomputable section

/-!
  3×3 窗口(p 向右,q 向下),与 `Curvature` / Dafny P-003 相同。

      a(-1,-1)   b( 0,-1)   c( 1,-1)
      d(-1, 0)     e        f( 1, 0)
      g(-1, 1)   h( 0, 1)   i( 1, 1)

  Horn 坡度平方仅需 b,d,f,h 四点
-/

/-- Horn (1981) 坡度平方算子 -/
def slopeSq (b d f h w : ℝ) : ℝ := 
  ((f - d) / (2 * w)) ^ 2 + ((b - h) / (2 * w)) ^ 2

/-!
  核心定理: 对任意高程值和正网格间距，坡度平方非负。
  证明仅需:
  1. 实数平方的非负性
  2. 正网格间距保证分母非零
-/
theorem slopeSq_nonneg (b d f h w : ℝ) (hw : w > 0) :
    0 ≤ slopeSq b d f h w := by
  -- 展开算子定义
  unfold slopeSq
  -- 证明两项均非负
  apply add_nonneg
  · -- 第一项: [(f - d)/(2w)]² ≥ 0
    apply pow_two_nonneg
  · -- 第二项: [(b - h)/(2w)]² ≥ 0
    apply pow_two_nonneg

end
end VeriGIS.HornSlope
