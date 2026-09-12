import Mathlib.Tactic
import Mathlib.Data.Real.Basic
import Mathlib.Data.List.MinMax
import Mathlib.Data.List.Basic

namespace VeriGIS.D8

noncomputable section

/-!
  ==========================================================================
   GeoProofBench · P-005
   算子 : D8 流向算法 (平面不变性)
   定理 : 在平面 DEM (z = A x + B y + C) 上，只要坡度非零 (A,B) ≠ (0,0)，
          则所有具有相同 (A,B) 的内部栅格流向相同，且与高程基准 C 无关。
   环境 : Lean 4.18.0 + mathlib
   ==========================================================================

  本文件形式化 D8 流向算法的关键不变性：在平面 DEM 上，流向由平面坡度 (A,B) 唯一确定，
  与高程基准 C 和栅格间距 w 无关。

  证明策略：
    1. 定义 8 个流向的偏移量 (D8 邻域)
    2. 定义平面高程函数 (z = A x + B y + C)
    3. 定义流向决策函数 (基于最大坡度下降)
    4. 证明流向决策仅依赖于 (A,B)，与 C 和 w 无关
-/

open Real

/-- D8 流向定义：8 邻域方向标签与坐标偏移 -/
def directions : List (String × ℤ × ℤ) := 
  [ ("E", 1, 0), 
    ("SE", 1, 1), 
    ("S", 0, 1), 
    ("SW", -1, 1), 
    ("W", -1, 0), 
    ("NW", -1, -1), 
    ("N", 0, -1), 
    ("NE", 1, -1) ]

/-- 平面 DEM 高程函数 -/
def planar_elevation (A B w C : ℝ) (i j : ℤ) : ℝ := 
  A * (i * w) + B * (j * w) + C

/-- 计算中心点流向 (返回方向标签) -/
def d8_flow_direction (A B w C : ℝ) : String :=
  let center_elev := planar_elevation A B w C 0 0
  let candidates := directions.map (λ (name, di, dj) => 
    let neighbor_elev := planar_elevation A B w C di dj
    let drop := center_elev - neighbor_elev
    (name, drop, di, dj))
  
  let valid := candidates.filter (λ (_, drop, _, _) => drop > 0)
  
  if h : valid = [] then "NoFlow" else
    let slopes := valid.map (λ (name, drop, di, dj) => 
      let dist_sq := (di : ℝ)^2 + (dj : ℝ)^2
      (name, drop^2 / dist_sq))  -- 坡度平方 (与真实坡度单调一致)
    
    let max_val := (slopes.map (·.2)).maximum  -- 获取最大坡度平方值
    have : ∃ (s : slopes), s.2 = max_val := by  -- 最大值存在性证明
      apply List.maximum_of_nonempty
      rw [List.map_eq_nil, not_iff_not] at h
      exact h.1 (λ _ => False.elim)
    
    let best := slopes.filter (λ (_, v) => v = max_val)
    (best.head (by simp [h])).1  -- 取第一个最大值方向 (方向顺序固定)

/-- 
  核心定理：在平面 DEM 上，只要坡度非零 (A,B) ≠ (0,0)，
  则流向决策与高程基准 C 和栅格间距 w 无关
-/
theorem d8_planar_constant (A B : ℝ) (hAB : A ≠ 0 ∨ B ≠ 0) 
    (w₁ w₂ : ℝ) (hw₁ : w₁ > 0) (hw₂ : w₂ > 0) (C₁ C₂ : ℝ) :
    d8_flow_direction A B w₁ C₁ = d8_flow_direction A B w₂ C₂ := by
  -- 展开流向决策函数定义
  unfold d8_flow_direction
  -- 提取高程计算函数
  unfold planar_elevation
  -- 化简表达式：中心高程与邻域高程差
  simp only [sub_self, add_zero, mul_zero, zero_mul, sub_add_cancel, 
             sub_eq_neg_add, neg_add_rev, neg_mul, mul_neg, neg_neg]
  
  -- 关键步骤：证明有效方向集相同
  have dirs_eq : 
      (directions.filter (λ (_, di, dj) => 
          center_elev - planar_elevation A B w₁ C₁ di dj > 0)) =
      (directions.filter (λ (_, di, dj) => 
          center_elev - planar_elevation A B w₂ C₂ di dj > 0)) := by
    apply List.ext
    intro (name, di, dj)
    simp only [List.mem_filter, and_congr_right_iff]
    intro _
    -- 展开高程计算
    unfold planar_elevation
    -- 化简高程差表达式
    field_simp [hw₁, hw₂]
    rw [← sub_pos, ← mul_sub, ← mul_sub]
    simp only [mul_eq_mul_left_iff, sub_eq_zero]
    -- 证明方向有效性条件等价
    apply iff_of_eq
    congr 2
    ring  -- 消除 C 和 w 的影响

  -- 应用方向集等价性
  rw [dirs_eq]
  -- 后续计算仅依赖方向集和 (A,B)，与 w,C 无关
  congr! 2  -- 强制推进计算一致性

end -- noncomputable section

end VeriGIS.D8
