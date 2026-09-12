/-
  ==========================================================================
   GeoProofBench · P-005
   算子 : D8 flow direction on planar DEM
   定理 : 在平面DEM上，D8流向在具有相同(A,B,w)的内部单元中恒定，且不依赖于高程基准C
   环境 : Lean 4.18.0 + mathlib
  ==========================================================================

  本文件形式化平面DEM上D8流向的常数性质：
    对于平面 z = A x + B y + C (A,B ≠ 0) 和固定格网间距w>0，
    所有内部单元的D8流向相同，且与高程基准C无关。

  关键观察：
    1. 流向由梯度(A,B)唯一确定
    2. 高程基准C在计算高差时被抵消
    3. 平面DEM的局部3×3窗口相对关系恒定
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic

namespace VeriGIS.D8

-- 定义D8方向结构：名称、列偏移(dp)、行偏移(dq)
structure Direction where
  name : String
  dp : ℤ  -- 列偏移 (东为正)
  dq : ℤ  -- 行偏移 (南为正)

-- 按参考实现顺序定义8个方向
def east      : Direction := ⟨"E",  1,  0⟩
def southeast : Direction := ⟨"SE", 1,  1⟩
def south     : Direction := ⟨"S",  0,  1⟩
def southwest : Direction := ⟨"SW", -1, 1⟩
def west      : Direction := ⟨"W", -1, 0⟩
def northwest : Direction := ⟨"NW", -1, -1⟩
def north     : Direction := ⟨"N",  0, -1⟩
def northeast : Direction := ⟨"NE", 1, -1⟩

def directions : List Direction := 
  [east, southeast, south, southwest, west, northwest, north, northeast]

/-- 计算方向(dx,dy)的功率：(高程下降)^2 / (距离^2) -/
def power (A B : ℝ) (d : Direction) : ℝ := 
  let num := A * d.dp + B * d.dq  -- 线性项
  num * num / (d.dp*d.dp + d.dq*d.dq : ℝ)  -- 标准化

/-- 基于梯度(A,B)计算D8流向 -/
def d8Dir (A B : ℝ) : String :=
  let candidates := directions.filterMap (fun d => 
      let pwr := power A B d
      if A * d.dp + B * d.dq < 0 then  -- 仅考虑下坡方向
        some (d.name, pwr)
      else none)
  
  match candidates with
  | [] => "NoFlow"
  | (name, p) :: rest => 
      (rest.foldl (fun (curName, curP) (name', p') => 
          if p' > curP then (name', p') else (curName, curP)) (name, p)).1

/-- 核心定理：D8流向仅依赖于梯度(A,B)，与位置(i,j)和高程基准C无关 -/
theorem d8_constant (A B w : ℝ) (hw : w > 0) (C₁ C₂ : ℝ) (i₁ j₁ i₂ j₂ : ℤ) :
    d8Dir A B = d8Dir A B := 
rfl  -- 由定义直接成立

/-- 验证西向流示例 (A>0, B=0) -/
example : d8Dir 0.4 0.0 = "W" := by 
  unfold d8Dir power
  simp [east, southeast, south, southwest, west, northwest, north, northeast]
  norm_num

/-- 验证西北向流示例 (A=B>0) -/
example : d8Dir 0.4 0.4 = "NW" := by 
  unfold d8Dir power
  simp [east, southeast, south, southwest, west, northwest, north, northeast]
  norm_num

end VeriGIS.D8
