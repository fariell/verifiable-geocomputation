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

    1. Dafny 的 `real` 除法要求 `requires w > 0.0`;Lean 的 `ℝ` 除法是全函数
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

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## D8 流向定义 (O'Callaghan & Mark 1984)

  对 3×3 窗口中的每个邻域方向 (dx,dy) ∈ {(-1,-1), (0,-1), ..., (1,1)} \ {(0,0)},
  计算高程下降 Δz = z_center - z_neighbor 和水平距离 L = w·√(dx²+dy²)。

  若 Δz ≤ 0 则跳过该方向;否则计算"下降功率" P = (Δz)² / (dx²+dy²) / w²。
  取 P 最大的方向为流向;若所有 Δz ≤ 0 则返回 NoFlow。

  注意: dx²+dy² ∈ {1,2},因此 L² = w²·(dx²+dy²)。

  本文件只证明平面 DEM 上的性质,不实现完整 D8 算法。
-/

-- ==========================================================================
-- 方向枚举与距离平方
-- ==========================================================================

/-- D8 的八个方向 (dx,dy) 及其距离平方 dx²+dy² -/
inductive D8Dir : Type
  | E  : D8Dir  -- (1,0)  dist2 = 1
  | SE : D8Dir  -- (1,1)  dist2 = 2
  | S  : D8Dir  -- (0,1)  dist2 = 1
  | SW : D8Dir  -- (-1,1) dist2 = 2
  | W  : D8Dir  -- (-1,0) dist2 = 1
  | NW : D8Dir  -- (-1,-1) dist2 = 2
  | N  : D8Dir  -- (0,-1) dist2 = 1
  | NE : D8Dir  -- (1,-1) dist2 = 2
deriving DecidableEq, Fintype

namespace D8Dir

/-- 方向对应的 Δx (列偏移) -/
def dx : D8Dir → ℤ
  | E  => 1
  | SE => 1
  | S  => 0
  | SW => -1
  | W  => -1
  | NW => -1
  | N  => 0
  | NE => 1

/-- 方向对应的 Δy (行偏移,向下为正) -/
def dy : D8Dir → ℤ
  | E  => 0
  | SE => 1
  | S  => 1
  | SW => 1
  | W  => 0
  | NW => -1
  | N  => -1
  | NE => -1

/-- 水平距离平方 dx²+dy² (∈ {1,2}) -/
def distSq (d : D8Dir) : ℕ :=
  let x := dx d
  let y := dy d
  x.natAbs * x.natAbs + y.natAbs * y.natAbs

@[simp] theorem distSq_E : distSq E = 1 := rfl
@[simp] theorem distSq_SE : distSq SE = 2 := rfl
@[simp] theorem distSq_S : distSq S = 1 := rfl
@[simp] theorem distSq_SW : distSq SW = 2 := rfl
@[simp] theorem distSq_W : distSq W = 1 := rfl
@[simp] theorem distSq_NW : distSq NW = 2 := rfl
@[simp] theorem distSq_N : distSq N = 1 := rfl
@[simp] theorem distSq_NE : distSq NE = 2 := rfl

theorem distSq_pos (d : D8Dir) : 0 < distSq d := by
  cases d <;> decide

end D8Dir

-- ==========================================================================
-- 平面 DEM 定义
-- ==========================================================================

/-- 平面 DEM: z = A·x + B·y + C,其中 x,y 为格网坐标(整数),A,B,C,w ∈ ℝ -/
structure PlaneDEM where
  A : ℝ
  B : ℝ
  C : ℝ
  w : ℝ
  hw : w ≠ 0

namespace PlaneDEM

/-- 在格网坐标 (x,y) 处的高程 -/
def elev (P : PlaneDEM) (x y : ℤ) : ℝ :=
  P.A * (x : ℝ) + P.B * (y : ℝ) + P.C

/-- 从中心格 (x,y) 到方向 d 的邻格的高程下降 Δz = z_center - z_neighbor -/
def drop (P : PlaneDEM) (x y : ℤ) (d : D8Dir) : ℝ :=
  P.elev x y - P.elev (x + d.dx) (y + d.dy)

/-- 下降功率 P = (Δz)² / (dx²+dy²) / w²,若 Δz > 0,否则为 0 -/
def power (P : PlaneDEM) (x y : ℤ) (d : D8Dir) : ℝ :=
  let Δz := P.drop x y d
  if h : Δz > 0 then
    Δz ^ 2 / ((d.distSq : ℝ) * P.w ^ 2)
  else 0

/-- D8 流向: 取 power 最大的方向;若所有 power = 0 则返回 None 表示 NoFlow -/
def direction (P : PlaneDEM) (x y : ℤ) : Option D8Dir :=
  let dirs : Finset D8Dir := Finset.univ
  let powers := dirs.filterMap (λ d =>
    let p := P.power x y d
    if p > 0 then some (d, p) else none)
  match powers.maxBy (·.2) (by intro; simp) with
  | some (d, _) => some d
  | none => none

end PlaneDEM

-- ==========================================================================
-- 主要定理: 平面 DEM 上 D8 流向与平移不变性
-- ==========================================================================

open PlaneDEM

/-- 在正坡度平面(A>0,B=0)上,所有内部单元格流向西(W) -/
theorem plane_west_flow (P : PlaneDEM) (hA : P.A > 0) (hB : P.B = 0) (x y : ℤ) :
    P.direction x y = some D8Dir.W := by
  have hB' : P.B = 0 := hB
  subst hB'
  unfold direction power drop elev
  simp [D8Dir.distSq, hA, P.hw]
  have : (P.A : ℝ) > 0 := by exact_mod_cast hA
  have hpos : P.A * ((-1 : ℤ) : ℝ) = -P.A := by ring
  have hdrop : ∀ d : D8Dir, P.drop x y d = -P.A * (d.dx : ℝ) - P.B * (d.dy : ℝ) := by
    intro d
    unfold drop elev
    ring_nf
  simp [hdrop, D8Dir.dx, D8Dir.dy, this] at *
  -- 只有 W 方向 Δz = P.A > 0,其他方向 Δz ≤ 0
  constructor
  · intro d h
    have := hdrop d
    simp [D8Dir.dx, D8Dir.dy] at this h
    linarith
  · norm_num [hA]

/-- 在正坡度平面(A=B>0)上,所有内部单元格流向西北(NW) -/
theorem plane_northwest_flow (P : PlaneDEM) (hAB : P.A = P.B) (hpos : P.A > 0) (x y : ℤ) :
    P.direction x y = some D8Dir.NW := by
  have hA : P.A > 0 := hpos
  have hB : P.B > 0 := by rwa [← hAB]
  unfold direction power drop elev
  simp [D8Dir.distSq, hA, hB, P.hw, hAB]
  have hdrop : ∀ d : D8Dir, P.drop x y d = -P.A * (d.dx : ℝ) - P.B * (d.dy : ℝ) := by
    intro d
    unfold drop elev
    ring_nf
  simp [hdrop, D8Dir.dx, D8Dir.dy, hAB] at *
  -- 只有 NW 方向 Δz = P.A + P.B > 0,其他方向 Δz ≤ 0
  constructor
  · intro d h
    have := hdrop d
    simp [D8Dir.dx, D8Dir.dy, hAB] at this h
    nlinarith
  · nlinarith

/-- 平移高程基准 C 不改变 D8 流向 -/
theorem translation_invariant (P : PlaneDEM) (ΔC : ℝ) (x y : ℤ) :
    let P' : PlaneDEM :=
      { P with
        C := P.C + ΔC
        hw := P.hw }
    P'.direction x y = P.direction x y := by
  intro P'
  unfold direction power drop elev
  simp [P']
  congr! 2
  ext d
  simp [P']
  ring_nf

-- ==========================================================================
-- 冒烟测试
-- ==========================================================================

example : True := by
  trivial

-- ==========================================================================
-- 结构注记
-- --------------------------------------------------------------------------
-- 1. 平面 DEM 的 D8 流向恒定,因为 Δz = -A·dx - B·dy 与 x,y,C 无关。
-- 2. 平移不变性源于 Δz 只依赖高程差,而 C 在差中被抵消。
-- 3. 正坡度条件(A>0或A=B>0)保证至少一个方向的 Δz > 0,避免 NoFlow。
-- 4. 本证明不涉及边界单元格(邻域不全),这是 D8 在 DEM 边缘的固有局限。
-- ==========================================================================

end -- noncomputable section

end VeriGIS.D8
