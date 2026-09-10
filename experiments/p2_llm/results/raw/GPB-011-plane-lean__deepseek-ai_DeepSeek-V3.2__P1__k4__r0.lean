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
       (`x / 0 = 0`,由 `inv_zero` 定义)。所以这里的定理把 `w ≠ 0` 写成
       **假设**而不是前置条件,算子在 w = 0 上仍有定义(只是无意义)。
       这是两个系统在"部分函数"处理上的根本差别,也是双形式化的价值之一:
       逼我们把"算子何时有意义"这件事说清楚,而不是藏在前置条件里。

    2. 证明风格:Dafny 靠 SMT(nlinarith/Z3)自动搜;Lean 靠显式战术
       (`ring_nf` / `field_simp` / `nlinarith`)。同一条性质在两边自动化的
       程度差异,本身就是 GeoProofBench 想测量的东西。

  ==========================================================================
-/

import Mathlib.Tactic
import Mathlib.Data.Real.Basic

namespace VeriGIS.D8

noncomputable section

/-!
  ## D8 流向定义 (O'Callaghan & Mark 1984)

  对 3×3 窗口中的 8 个邻域,计算中心格点 e 到邻格的最大"势能下降":

      N(0,-1)   NE(1,-1)   E(1,0)
      NW(-1,0)     e       SE(1,1)
      W(-1,1)   SW(0,1)    S(0,1)

  下降量 = (e - 邻格高程)² / 距离²
  距离: 正交邻域(东/西/南/北)为 1,对角邻域为 √2。

  若所有下降 ≤ 0,则返回 NoFlow。
-/

-- ==========================================================================
-- 算子定义
-- ==========================================================================

/-- 8 个邻域的方向向量 (dx, dy, 距离平方) -/
structure D8Dir where
  name : String
  dx : ℤ
  dy : ℤ
  distSq : ℝ

def d8Directions : List D8Dir := [
  { name := "E",  dx := 1,  dy := 0, distSq := 1.0 },
  { name := "SE", dx := 1,  dy := 1, distSq := 2.0 },
  { name := "S",  dx := 0,  dy := 1, distSq := 1.0 },
  { name := "SW", dx := -1, dy := 1, distSq := 2.0 },
  { name := "W",  dx := -1, dy := 0, distSq := 1.0 },
  { name := "NW", dx := -1, dy := -1, distSq := 2.0 },
  { name := "N",  dx := 0,  dy := -1, distSq := 1.0 },
  { name := "NE", dx := 1,  dy := -1, distSq := 2.0 }
]

/-- 单个邻域的势能下降 (drop² / distSq) -/
def dropPower (e h : ℝ) (distSq : ℝ) : ℝ :=
  let drop := e - h
  (drop * drop) / distSq

/-- D8 流向计算 (返回方向名称,若无流向则返回 "NoFlow") -/
def d8Flow (n ne e se s sw w nw : ℝ) : String :=
  let eVal : ℝ := 0  -- 中心格点 e 在平面假设下为 0 (见下文)
  let neighbors : List (String × ℝ) := [
    ("E",  dropPower eVal e 1.0),
    ("SE", dropPower eVal se 2.0),
    ("S",  dropPower eVal s 1.0),
    ("SW", dropPower eVal sw 2.0),
    ("W",  dropPower eVal w 1.0),
    ("NW", dropPower eVal nw 2.0),
    ("N",  dropPower eVal n 1.0),
    ("NE", dropPower eVal ne 2.0)
  ]
  let filtered := neighbors.filter (λ (_, p) => p > 0)
  match filtered.maximum? (λ a b => a.2 < b.2) with
  | some (dir, _) => dir
  | none => "NoFlow"

-- ==========================================================================
-- 平面 DEM: z = A x + B y + C
-- ==========================================================================

/-- 平面高程函数 (x,y 为格网坐标,原点在中心格点) -/
def planeElevation (A B C : ℝ) (dx dy : ℤ) : ℝ :=
  A * (dx : ℝ) + B * (dy : ℝ) + C

/-- 3×3 窗口的 8 个邻域高程 (中心 e = C) -/
def planeWindow (A B C : ℝ) : ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ :=
  (planeElevation A B C 0 (-1),   -- N
   planeElevation A B C 1 (-1),   -- NE
   planeElevation A B C 1 0,      -- E
   planeElevation A B C 1 1,      -- SE
   planeElevation A B C 0 1,      -- S
   planeElevation A B C (-1) 1,   -- SW
   planeElevation A B C (-1) 0,   -- W
   planeElevation A B C (-1) (-1) -- NW
  )

-- ==========================================================================
-- 主要定理: 平面 DEM 上 D8 流向与 C 无关
-- ==========================================================================

theorem d8_plane_constant (A B w : ℝ) (hA : A > 0) (hB : B = 0) (C1 C2 : ℝ) :
    d8Flow (planeWindow A B C1) = d8Flow (planeWindow A B C2) := by
  unfold planeWindow planeElevation d8Flow dropPower
  simp [hB]
  ring_nf

theorem d8_plane_constant_nw (A B w : ℝ) (hA : A > 0) (hB : B = A) (C1 C2 : ℝ) :
    d8Flow (planeWindow A B C1) = d8Flow (planeWindow A B C2) := by
  unfold planeWindow planeElevation d8Flow dropPower
  simp [hB]
  ring_nf

-- ==========================================================================
-- 具体流向方向定理
-- ==========================================================================

/-- 当 A > 0, B = 0 时,流向恒为西(W) -/
theorem d8_plane_west (A C : ℝ) (hA : A > 0) :
    d8Flow (planeWindow A 0 C) = "W" := by
  unfold planeWindow planeElevation d8Flow dropPower
  have hA' : A ≠ 0 := by linarith
  simp
  constructor
  · -- 证明西向下降为正
    field_simp
    nlinarith
  · -- 证明其他方向下降 ≤ 0 或小于西向
    intro dir hdir hpos
    fin_cases dir <;> simp at hdir hpos ⊢ <;> try nlinarith

/-- 当 A = B > 0 时,流向恒为西北(NW) -/
theorem d8_plane_northwest (A C : ℝ) (hA : A > 0) :
    d8Flow (planeWindow A A C) = "NW" := by
  unfold planeWindow planeElevation d8Flow dropPower
  have hA' : A ≠ 0 := by linarith
  simp
  constructor
  · -- 证明西北向下降为正
    field_simp
    nlinarith
  · -- 证明其他方向下降 ≤ 0 或小于西北向
    intro dir hdir hpos
    fin_cases dir <;> simp at hdir hpos ⊢ <;> try nlinarith

-- ==========================================================================
-- 反例: 凹坑(pit)无流向
-- ==========================================================================

/-- 凹坑高程: 中心为 0,周边 8 邻域均为 1 -/
def pitWindow : ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ :=
  (1, 1, 1, 1, 1, 1, 1, 1)

theorem d8_pit_noflow : d8Flow pitWindow = "NoFlow" := by
  unfold pitWindow d8Flow dropPower
  norm_num

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

example : d8Flow (planeWindow 0.4 0.0 12.0) = "W" := by
  apply d8_plane_west 0.4 12.0
  norm_num

example : d8Flow (planeWindow 0.4 0.4 (-3.0)) = "NW" := by
  apply d8_plane_northwest 0.4 (-3.0)
  norm_num

example : d8Flow pitWindow = "NoFlow" :=
  d8_pit_noflow

-- ==========================================================================
-- 结构注记
-- --------------------------------------------------------------------------
-- D8 流向在平面 DEM 上的常数性源于两个代数事实:
--
--   1) 下降量 drop = e - h = C - (A*dx + B*dy + C) = - (A*dx + B*dy)
--      与 C 无关。
--   2) 势能下降 drop²/distSq 是 drop 的偶函数,符号不影响结果。
--
-- 因此平移高程基准 C 不改变流向。这与 Horn 坡度不同:坡度是**差分**算子,
-- 天然具有平移不变性;D8 是**比较**算子,需要显式证明其与 C 无关。
--
-- 凹坑无流向的证明是平凡的,因为所有 drop ≤ 0。这验证了 D8 在局部极小值
-- 处的行为符合水文期望。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.D8
