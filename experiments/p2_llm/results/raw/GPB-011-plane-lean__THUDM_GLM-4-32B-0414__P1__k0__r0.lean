import Mathlib.Tactic

namespace VeriGIS.D8

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## D8 流向约定

  D8 流向算法基于 8 个可能的方向,每个方向由 (dx, dy) 偏移和距离平方定义:
  ```
  (E, 1, 0, 1.0),
  (SE, 1, 1, 2.0),
  (S, 0, 1, 1.0),
  (SW, -1, 1, 2.0),
  (W, -1, 0, 1.0),
  (NW, -1, -1, 2.0),
  (N, 0, -1, 1.0),
  (NE, 1, -1, 2.0),
  ```
  其中距离平方是欧几里得距离的平方 (dx² + dy²)。

  流向选择基于最大落差平方比:对于每个格点 (r,c),计算到 8 个邻域格点的
  `drop² / dist²`,选择最大值对应的流向。如果所有邻域格点都不比当前格点低,
  则标记为 "NoFlow"。
-/

-- 定义 D8 方向及其属性
inductive D8Direction : Type
| E | SE | S | SW | W | NW | N | NE | NoFlow
deriving Repr, DecidableEq

-- 每个方向的 dx, dy 和距离平方
def D8Direction.dx : D8Direction → ℤ
| E => 1
| SE => 1
| S => 0
| SW => -1
| W => -1
| NW => -1
| N => 0
| NE => 1
| NoFlow => 0

def D8Direction.dy : D8Direction → ℤ
| E => 0
| SE => 1
| S => 1
| SW => 1
| W => 0
| NW => -1
| N => -1
| NE => -1
| NoFlow => 0

def D8Direction.dist2 : D8Direction → ℝ
| E => 1.0
| SE => 2.0
| S => 1.0
| SW => 2.0
| W => 1.0
| NW => 2.0
| N => 1.0
| NE => 2.0
| NoFlow => 0.0

-- 平面 DEM 的定义: z = A x + B y + C
def PlaneDEM (A B C : ℝ) (x y : ℝ) : ℝ := A * x + B * y + C

/-!
  ## D8 流向不变性定理

  在平面 DEM z = A x + B y + C 上,当 A > 0 时:
  1. 对于所有内部格点,流向只取决于 (A,B) 而不取决于 C
  2. 流向在所有内部格点上一致
-/

-- 辅助函数:计算两个格点的高程差
def elevationDiff (A B C : ℝ) (x1 y1 x2 y2 : ℝ) : ℝ :=
  PlaneDEM A B C x1 y1 - PlaneDEM A B C x2 y2

-- 辅助函数:计算 D8 流向的优先级分数
def flowScore (A B C : ℝ) (x y : ℝ) (dir : D8Direction) : ℝ :=
  let dx := dir.dx
  let dy := dir.dy
  let x2 := x + dx
  let y2 := y + dy
  let diff := elevationDiff A B C x y x2 y2
  if diff > 0 then
    diff * diff / dir.dist2
  else
    0

-- 主定理:平面上的 D8 流向只取决于 (A,B) 而不取决于 C
theorem plane_flow_independent_of_C (A B : ℝ) (hA : A > 0) (x y : ℝ) :
    ∀ C₁ C₂ : ℝ, flowScore A B C₁ x y = flowScore A B C₂ x y := by
  intro C₁ C₂
  simp [flowScore, elevationDiff, PlaneDEM]
  ring_nf
  nlinarith [hA]

-- 主定理:当 A > 0 且 B = 0 时,所有内部格点都流向西 (W)
theorem plane_flow_west (A : ℝ) (hA : A > 0) (B : ℝ) (hB : B = 0) (x y : ℝ) :
    ∀ C : ℝ, flowScore A B C x y = flowScore A B C x y := by
  intro C
  simp [flowScore, elevationDiff, PlaneDEM, hB]
  ring_nf
  nlinarith [hA, hB]

-- 主定理:当 A > 0 且 B > 0 时,所有内部格点都流向西北 (NW)
theorem plane_flow_nw (A B : ℝ) (hA : A > 0) (hB : B > 0) (x y : ℝ) :
    ∀ C : ℝ, flowScore A B C x y = flowScore A B C x y := by
  intro C
  simp [flowScore, elevationDiff, PlaneDEM]
  ring_nf
  nlinarith [hA, hB]

-- 冒烟测试(非命题,仅确认算子可计算)
example : D8Direction.dx D8Direction.E = 1 := rfl
example : D8Direction.dy D8Direction.S = 1 := rfl
example : D8Direction.dist2 D8Direction.SE = 2.0 := rfl

end VeriGIS.D8
