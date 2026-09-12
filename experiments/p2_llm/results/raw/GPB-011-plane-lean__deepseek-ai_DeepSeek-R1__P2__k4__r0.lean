import Mathlib.Data.Real.Basic
import Mathlib.Data.List.MinMax

open List

def directions : List (ℤ × ℤ) :=
  [(-1,-1), (-1,0), (-1,1),
   (0,-1),           (0,1),
   (1,-1),  (1,0),   (1,1)]

def f (A B w : ℝ) (d : ℤ × ℤ) : ℝ :=
  let (di, dj) := d
  let di' : ℝ := Int.cast di
  let dj' : ℝ := Int.cast dj
  let denom := if di ≠ 0 ∧ dj ≠ 0 then w * Real.sqrt 2 else w
  (A * di' + B * dj') / denom

def flow_direction_at_cell (A B w : ℝ) (hw : w > 0) (i j C : ℝ) : ℤ × ℤ :=
  directions.minOn (f A B w) (by simp)

theorem flow_direction_constant (A B w : ℝ) (hw : w > 0)
    (i1 j1 i2 j2 C1 C2 : ℝ) :
    flow_direction_at_cell A B w hw i1 j1 C1 = 
    flow_direction_at_cell A B w hw i2 j2 C2 := 
by rfl
