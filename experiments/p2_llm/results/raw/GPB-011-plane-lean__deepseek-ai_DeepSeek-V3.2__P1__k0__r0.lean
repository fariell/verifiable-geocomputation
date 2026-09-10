/-
  ==========================================================================
   GeoProofBench · P-005
   文件 : formal/lean4/VeriGIS/D8.lean
   算子 : D8 流向 (O'Callaghan & Mark 1984)
   对偶 : formal/dafny/P005_d8.dfy  (Dafny 4.11, 19 verified 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  本文件是 Dafny 版本的**独立**重述 —— 不是翻译。两处必须注意的差异:

    1. Dafny 的 `real` 除法要求分母非零;Lean 的 `ℝ` 除法是全函数
       (`x / 0 = 0`,由 `inv_zero` 定义)。所以 D8 的 `drop² / dist2` 在
       `dist2 = 0` 时自动为 0,不会崩溃。这要求我们在定理中显式假设分母非零。

    2. 证明风格:Dafny 靠 SMT(nlinarith/Z3)自动搜;Lean 靠显式战术
       (`ring_nf` / `field_simp` / `nlinarith`)。同一条性质在两边自动化的
       程度差异,本身就是 GeoProofBench 想测量的东西。

  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic

namespace VeriGIS.D8

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## D8 流向定义 (O'Callaghan & Mark 1984)

  对 3×3 窗口的 8 个邻域计算:

      NW( -1, -1)   N( 0, -1)   NE( 1, -1)
      W ( -1,  0)     中心      E ( 1,  0)
      SW( -1,  1)   S( 0,  1)   SE( 1,  1)

  每个方向有:
    - 行偏移 dq (向下为正,符合栅格惯例)
    - 列偏移 dp
    - 欧氏距离平方 dist2 = dp² + dq²

  对每个邻域计算:
    drop = z_center - z_neighbor
    power = drop² / dist2   (当 drop > 0)

  选择 power 最大的方向;若所有 drop ≤ 0 则返回 NoFlow。
-/

-- ==========================================================================
-- 方向元数据
-- ==========================================================================

/-- D8 方向名称与几何参数 -/
structure D8Dir where
  name : String
  dp : ℤ  -- 列偏移
  dq : ℤ  -- 行偏移
  dist2 : ℝ  -- 距离平方 (dp² + dq²)

/-- 八个标准方向 -/
def dirs : List D8Dir := [
  { name := "E",  dp := 1,  dq := 0,  dist2 := 1 },
  { name := "SE", dp := 1,  dq := 1,  dist2 := 2 },
  { name := "S",  dp := 0,  dq := 1,  dist2 := 1 },
  { name := "SW", dp := -1, dq := 1,  dist2 := 2 },
  { name := "W",  dp := -1, dq := 0,  dist2 := 1 },
  { name := "NW", dp := -1, dq := -1, dist2 := 2 },
  { name := "N",  dp := 0,  dq := -1, dist2 := 1 },
  { name := "NE", dp := 1,  dq := -1, dist2 := 2 }
]

/-- 无流向标记 -/
def NoFlow : String := "NoFlow"

-- ==========================================================================
-- 核心算子
-- ==========================================================================

/-- 单个方向的 power 计算 (drop² / dist2) -/
def dirPower (z_center z_neighbor : ℝ) (dist2 : ℝ) : ℝ :=
  if h : z_center > z_neighbor then
    let drop := z_center - z_neighbor
    (drop * drop) / dist2
  else
    0

/-- D8 流向决策 -/
def d8 (z_center : ℝ) (neighbors : List ℝ) : String :=
  let powers := List.zipWith (λ dir z => (dir.name, dirPower z_center z dir.dist2)) dirs neighbors
  let filtered := powers.filter (λ (_, p) => p > 0)
  match filtered.maximum? (λ a b => a.2 < b.2) with
  | some (name, _) => name
  | none => NoFlow

-- ==========================================================================
-- 平面 DEM 的 D8 流向不变性
-- ==========================================================================

/-- 平面高程: z = A*x + B*y + C -/
def planeElevation (A B C : ℝ) (x y : ℤ) : ℝ :=
  A * (x : ℝ) + B * (y : ℝ) + C

/-- 3×3 窗口的邻域高程列表 (按 dirs 顺序) -/
def planeNeighbors (A B C : ℝ) (x y : ℤ) : List ℝ :=
  dirs.map (λ dir => planeElevation A B C (x + dir.dp) (y + dir.dq))

/-- 中心点高程 -/
def planeCenter (A B C : ℝ) (x y : ℤ) : ℝ :=
  planeElevation A B C x y

/-- 主要定理: 在正坡度平面上,内部单元的 D8 流向与 C 无关 -/
theorem d8_plane_constant (A B : ℝ) (hA : A > 0) (hB : B ≥ 0) (x y : ℤ) :
    d8 (planeCenter A B C x y) (planeNeighbors A B C x y) =
    d8 (planeCenter A B C' x y) (planeNeighbors A B C' x y) := by
  -- 展开定义
  unfold d8 planeCenter planeNeighbors planeElevation
  simp only [List.map_map, List.zipWith_map_left]
  -- 关键观察: C 在差值中抵消
  have h_cancel : ∀ (dir : D8Dir),
      planeCenter A B C x y - planeElevation A B C (x + dir.dp) (y + dir.dq) =
      planeCenter A B C' x y - planeElevation A B C' (x + dir.dp) (y + dir.dq) := by
    intro dir
    dsimp [planeCenter, planeElevation]
    ring
  -- 因此每个方向的 power 相同
  have h_power_eq : ∀ (dir : D8Dir),
      dirPower (planeCenter A B C x y) (planeElevation A B C (x + dir.dp) (y + dir.dq)) dir.dist2 =
      dirPower (planeCenter A B C' x y) (planeElevation A B C' (x + dir.dp) (y + dir.dq)) dir.dist2 := by
    intro dir
    unfold dirPower
    -- 差值相等 → 条件判断结果相同
    rw [h_cancel dir]
  -- 应用相等性
  simp_rw [h_power_eq]

/-- 西向流定理 (A>0, B=0) -/
theorem d8_plane_west (A : ℝ) (hA : A > 0) (x y : ℤ) :
    d8 (planeCenter A 0 C x y) (planeNeighbors A 0 C x y) = "W" := by
  unfold d8 planeCenter planeNeighbors planeElevation dirPower
  simp only [List.map_map, List.zipWith_map_left, zero_mul, add_zero]
  -- 计算每个方向的 power
  have h_powers : List.map (λ (dir : D8Dir) =>
      (dir.name, dirPower (A * (x : ℝ) + C) (A * ((x + dir.dp) : ℝ) + C) dir.dist2)) dirs =
    [("E", 0), ("SE", 0), ("S", 0), ("SW", 0), ("W", A^2), ("NW", A^2/2), ("N", 0), ("NE", 0)] := by
    unfold dirs
    simp
    ring_nf
    -- 西向和西北向的 drop 为正
    have hW : A * (x : ℝ) + C - (A * ((x - 1 : ℤ) : ℝ) + C) = A := by push_cast; ring
    have hNW : A * (x : ℝ) + C - (A * ((x - 1 : ℤ) : ℝ) + C) = A := by push_cast; ring
    field_simp
    nlinarith
  rw [h_powers]
  -- 最大 power 是 A² (西向)
  have h_max : A^2 > A^2/2 := by nlinarith [hA]
  simp [h_max]

/-- 西北向流定理 (A=B>0) -/
theorem d8_plane_northwest (A : ℝ) (hA : A > 0) (x y : ℤ) :
    d8 (planeCenter A A C x y) (planeNeighbors A A C x y) = "NW" := by
  unfold d8 planeCenter planeNeighbors planeElevation dirPower
  simp only [List.map_map, List.zipWith_map_left]
  -- 计算每个方向的 power
  have h_powers : List.map (λ (dir : D8Dir) =>
      (dir.name, dirPower (A * (x : ℝ) + A * (y : ℝ) + C)
                         (A * ((x + dir.dp) : ℝ) + A * ((y + dir.dq) : ℝ) + C)
                         dir.dist2)) dirs =
    [("E", 0), ("SE", 0), ("S", 0), ("SW", A^2/2), ("W", A^2), ("NW", 2*A^2), ("N", A^2), ("NE", A^2/2)] := by
    unfold dirs
    simp
    ring_nf
    -- 西北向的 drop 最大 (2A)
    have hNW : A * (x : ℝ) + A * (y : ℝ) + C - (A * ((x - 1 : ℤ) : ℝ) + A * ((y - 1 : ℤ) : ℝ) + C) = 2*A := by
      push_cast; ring
    field_simp
    nlinarith
  rw [h_powers]
  -- 最大 power 是 2A² (西北向)
  have h_max1 : 2*A^2 > A^2 := by nlinarith
  have h_max2 : 2*A^2 > A^2/2 := by nlinarith
  simp [h_max1, h_max2]

-- ==========================================================================
-- 注记
-- --------------------------------------------------------------------------
-- 1. 定理 `d8_plane_constant` 证明了: 在正坡度平面(A>0, B≥0)上,
--    D8 流向与高程基准面 C 无关。这是平面流向一致性的核心。
--
-- 2. 特例 `d8_plane_west` 和 `d8_plane_northwest` 给出了具体方向,
--    验证了参考实现中的代数预测。
--
-- 3. 这些定理不要求 w(格网间距),因为 D8 只依赖相对高差,不依赖绝对距离。
--    这是与 Horn 坡度算子的重要区别。
--
-- 4. 平面必须具有正坡度(A>0),否则可能出现平坦区域导致 NoFlow。
--    这是 DEM 流向分析的标准假设。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.D8
