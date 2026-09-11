import Mathlib.Tactic

namespace VeriGIS.D8

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## D8 流向约定

  D8 流向算法将每个格点视为中心,计算其与8个相邻格点的落差平方比。
  流向定义为具有最大正落差平方比的相邻格点方向。若所有相邻格点
  高程均不小于中心格点,则标记为"NoFlow"。

  方向编码:
  ```
  E(1,0), SE(1,1), S(0,1), SW(-1,1),
  W(-1,0), NW(-1,-1), N(0,-1), NE(1,-1)
  ```
  距离平方: E/W/S/N = 1.0, SE/SW/NW/NE = 2.0
-/

-- 平面 DEM z = A x + B y + C 的参数
-- 假设格网间距为 1 单位
def planeDEM (A B C : ℝ) (x y : ℝ) : ℝ := A * x + B * y + C

-- D8 流向计算的核心比较量
def d8Drop (A B C : ℝ) (x y : ℝ) (dx dy : ℝ) : ℝ :=
  let center := planeDEM A B C x y
  let neighbor := planeDEM A B C (x + dx) (y + dy)
  (center - neighbor) * (center - neighbor) / (dx * dx + dy * dy)

-- D8 流向决策函数
def d8Flow (A B C : ℝ) (x y : ℝ) : String :=
  let best_dir := "NoFlow"
  let best_p := 0.0
  let dirs := [
    ("E", 1, 0),
    ("SE", 1, 1),
    ("S", 0, 1),
    ("SW", -1, 1),
    ("W", -1, 0),
    ("NW", -1, -1),
    ("N", 0, -1),
    ("NE", 1, -1)
  ]
  for (name, dp, dq) in dirs do
    let p := d8Drop A B C x y dp dq
    if p > best_p then
      best_dir := name
      best_p := p
  best_dir

-- 平面 DEM 上 D8 流向的恒定性定理
-- 命题: 在平面 z = A x + B y + C 上,若 A > 0 且 B = 0,
-- 则所有内部格点的 D8 流向均为 "W" (西向)
theorem planeFlowWest (A B C : ℝ) (h x y : ℝ)
    (hA : A > 0) (hB : B = 0) :
    d8Flow A B C x y = "W" := by
  simp [hB, d8Flow, d8Drop]
  unfold planeDEM
  ring_nf
  nlinarith [hA, hB]

-- 平面 DEM 上 D8 流向的恒定性定理
-- 命题: 在平面 z = A x + B y + C 上,若 A > 0 且 B > 0,
-- 则所有内部格点的 D8 流向均为 "NW" (西北向)
theorem planeFlowNW (A B C : ℝ) (h x y : ℝ)
    (hA : A > 0) (hB : B > 0) :
    d8Flow A B C x y = "NW" := by
  simp [d8Flow, d8Drop]
  unfold planeDEM
  ring_nf
  nlinarith [hA, hB]

-- 高程基准面平移不影响流向定理
-- 命题: 在平面 z = A x + B y + C 上,将高程基准面平移 ΔC
-- (即使用 z = A x + B y + (C + ΔC)) 不改变 D8 流向
theorem datumTranslation (A B C ΔC : ℝ) (h x y : ℝ) :
    d8Flow A B C x y = d8Flow A B (C + ΔC) x y := by
  simp [d8Flow, d8Drop]
  unfold planeDEM
  ring_nf
  nlinarith

end VeriGIS.D8
