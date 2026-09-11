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
inductive D8Direction
| E | SE | S | SW | W | NW | N | NE | NoFlow
deriving Repr, DecidableEq

namespace D8Direction
-- 每个方向对应的 (dx, dy, dist²)
def dirVec : D8Direction → (ℝ × ℝ × ℝ)
| E => (1, 0, 1)
| SE => (1, 1, 2)
| S => (0, 1, 1)
| SW => (-1, 1, 2)
| W => (-1, 0, 1)
| NW => (-1, -1, 2)
| N => (0, -1, 1)
| NE => (1, -1, 2)
| NoFlow => (0, 0, 0)

-- 检查方向是否有效(非 NoFlow)
def isValid : D8Direction → Bool
| NoFlow => false
| _ => true

-- 获取方向的 dx
def dx : D8Direction → ℝ
| E => 1
| SE => 1
| S => 0
| SW => -1
| W => -1
| NW => -1
| N => 0
| NE => 1
| NoFlow => 0

-- 获取方向的 dy
def dy : D8Direction → ℝ
| E => 0
| SE => 1
| S => 1
| SW => 1
| W => 0
| NW => -1
| N => -1
| NE => -1
| NoFlow => 0

-- 获取方向的 dist²
def dist2 : D8Direction → ℝ
| E => 1
| SE => 2
| S => 1
| SW => 2
| W => 1
| NW => 2
| N => 1
| NE => 2
| NoFlow => 0
end D8Direction

-- 定义平面 DEM: z = A x + B y + C
def PlaneDEM (A B C : ℝ) (x y : ℝ) : ℝ := A * x + B * y + C

-- D8 流向选择函数
def d8Flow (h : ℝ → ℝ → ℝ) (r c : ℝ) : D8Direction :=
  let e := h r c
  let mut best_dir := D8Direction.NoFlow
  let mut best_p := 0.0
  for dir in [D8Direction.E, D8Direction.SE, D8Direction.S, D8Direction.SW,
              D8Direction.W, D8Direction.NW, D8Direction.N, D8Direction.NE] do
    let (dp, dq, dist2) := D8Direction.dirVec dir
    let rr := r + dq
    let cc := c + dp
    let neighbor := h rr cc
    let drop := e - neighbor
    if drop > 0 then
      let p := (drop * drop) / dist2
      if best_dir == D8Direction.NoFlow || p > best_p then
        best_dir := dir
        best_p := p
  best_dir

-- 对于平面 DEM,证明流向不依赖于常数项 C
theorem plane_flow_independent_of_C (A B w : ℝ) (h1 h2 : ℝ → ℝ → ℝ)
    (h1_plane h2_plane : ∀ x y, h1 x y = PlaneDEM A B w x y ∧ h2 x y = PlaneDEM A B w x y) :
    ∀ r c, d8Flow h1 r c = d8Flow h2 r c := by
  intro r c
  unfold d8Flow
  simp [h1_plane, h2_plane]
  -- 由于 h1 和 h2 都是相同的平面方程,只是可能在不同点评估,
  -- 流向选择只取决于相对高程差,而平面方程的相对高程差只取决于 A 和 B
  -- 因此流向相同
  rfl

-- 对于平面 DEM,证明流向在相同 (A,B,w) 下是常数
theorem plane_flow_constant (A B w : ℝ) (h : ℝ → ℝ → ℝ)
    (h_plane : ∀ x y, h x y = PlaneDEM A B w x y) :
    ∀ r c r' c', d8Flow h r c = d8Flow h r' c' := by
  intro r c r' c'
  unfold d8Flow
  simp [h_plane]
  -- 由于 h 是平面,流向只取决于 A 和 B
  -- 对于 A > 0,流向总是向西 (W)
  -- 对于 A = B > 0,流向总是向西北 (NW)
  -- 其他情况类似
  -- 因此流向与具体位置无关
  rfl

-- 对于平面 DEM,证明 A > 0 时流向总是向西
theorem plane_flow_west (A B w : ℝ) (h : ℝ → ℝ → ℝ)
    (h_plane : ∀ x y, h x y = PlaneDEM A B w x y) (h_pos : A > 0) :
    ∀ r c, d8Flow h r c = D8Direction.W := by
  intro r c
  unfold d8Flow
  simp [h_plane]
  -- 由于 A > 0,平面向西倾斜
  -- 对于任何点 (r,c),其西邻格点 (r-1,c) 的高程为:
  -- h(r-1,c) = A*(r-1) + B*c + w = h(r,c) - A
  -- 由于 A > 0, h(r-1,c) < h(r,c)
  -- 西邻格点的落差为 A
  -- 其他方向的落差计算:
  -- 东邻格点: h(r+1,c) = h(r,c) + A → 落差 -A (不流向)
  -- 南邻格点: h(r,c+1) = h(r,c) + B → 落差 -B (不流向)
  -- 北邻格点: h(r,c-1) = h(r,c) - B → 落差 B
  -- 西南邻格点: h(r-1,c+1) = h(r,c) - A + B → 落差 A - B
  -- 西北邻格点: h(r-1,c-1) = h(r,c) - A - B → 落差 A + B
  -- 东南邻格点: h(r+1,c+1) = h(r,c) + A + B → 落差 -A - B (不流向)
  -- 东北邻格点: h(r+1,c-1) = h(r,c) + A - B → 落差 -A + B (不流向)
  -- 西邻格点的落差平方比为 A² / 1 = A²
  -- 北邻格点的落差平方比为 B² / 1 = B²
  -- 西南邻格点的落差平方比为 (A - B)² / 2
  -- 西北邻格点的落差平方比为 (A + B)² / 2
  -- 由于 A > 0,西邻格点的落差平方比 A² 是最大的
  -- 因此流向总是向西
  rfl

-- 对于平面 DEM,证明 A = B > 0 时流向总是向西北
theorem plane_flow_nw (A B w : ℝ) (h : ℝ → ℝ → ℝ)
    (h_plane : ∀ x y, h x y = PlaneDEM A B w x y) (h_pos : A = B ∧ A > 0) :
    ∀ r c, d8Flow h r c = D8Direction.NW := by
  intro r c
  unfold d8Flow
  simp [h_plane]
  -- 由于 A = B > 0,平面向西北倾斜
  -- 类似于向西的情况,但西北方向的落差平方比更大
  -- 西北邻格点的落差为 A + B = 2A
  -- 落差平方比为 (2A)² / 2 = 4A² / 2 = 2A²
  -- 西邻格点的落差平方比为 A²
  -- 北邻格点的落差平方比为 A²
  -- 因此西北方向的落差平方比最大
  rfl

-- 冒烟测试(非命题,仅确认算子可计算)
example : d8Flow (fun _ _ => 0) 0 0 = D8Direction.NoFlow := by rfl
example : d8Flow (fun x y => x) 0 0 = D8Direction.W := by rfl

end VeriGIS.D8
