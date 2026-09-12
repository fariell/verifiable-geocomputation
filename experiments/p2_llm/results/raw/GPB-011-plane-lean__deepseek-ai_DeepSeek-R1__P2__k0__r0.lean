import Mathlib.Data.Real.Basic
import Mathlib.Data.List.MinMax

structure GridPoint where
  i : ℤ
  j : ℤ

def Direction := ℤ × ℤ

def slope (A B : ℝ) (dx dy : ℤ) : ℝ :=
  let denom := if dx = 0 || dy = 0 then 1 else Real.sqrt 2
  (-A * dx - B * dy) / denom

def directions : List Direction :=
  [ (-1, -1), (-1, 0), (-1, 1),
    ( 0, -1),          ( 0, 1),
    ( 1, -1), ( 1, 0), ( 1, 1) ]

def flow_dir_at (A B : ℝ) (C : ℝ) (w : ℝ) (p : GridPoint) : Option Direction :=
  let slopes := directions.map (λ (dx, dy) => ((dx, dy), slope A B dx dy))
  let max_val := (slopes.map (·.2)).maximum?
  match max_val with
  | none => none
  | some max_val =>
    let max_dirs := slopes.filter (λ (_, s) => s = max_val) |>.map (·.1)
    if h : max_dirs.length = 1 then
      some (max_dirs[0]' (by simp [h]))
    else
      none

def unique_max_slope (A B : ℝ) : Prop :=
  let slopes := directions.map (λ (dx, dy) => slope A B dx dy)
  let max_val := slopes.maximum?
  max_val.isSome ∧
  let max_dirs := directions.filter (λ d => slope A B d.1 d.2 = max_val.get)
  max_dirs.length = 1

theorem flow_direction_constant (A B : ℝ) (h_unique : unique_max_slope A B)
    (w₁ w₂ : ℝ) (w₁_pos : w₁ > 0) (w₂_pos : w₂ > 0)
    (C₁ C₂ : ℝ) (p₁ p₂ : GridPoint) :
    flow_dir_at A B C₁ w₁ p₁ = flow_dir_at A B C₂ w₂ p₂ := by
  unfold flow_dir_at
  have h_slope_independent : ∀ (dx dy : ℤ), slope A B dx dy = slope A B dx dy := by
    intro dx dy; rfl
  rw [h_slope_independent, h_slope_independent]
  congr
