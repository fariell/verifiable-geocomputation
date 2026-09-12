import Mathlib.Data.Real.Basic
import Mathlib.Data.Int.Basic
import Mathlib.Data.List.Basic

open List

def dirs : List (ℤ × ℤ) := 
  [(1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1), (0,-1), (1,-1)]

def flow_direction_at (A B : ℝ) (w : ℝ) (C : ℝ) (i j : ℤ) : Option (ℤ × ℤ) :=
  let candidates := filter (λ (dx,dy) => A*dx + B*dy < 0) dirs
  if h : candidates = [] then none
  else
    let get_priority (d : ℤ × ℤ) : ℝ := 
      let (dx,dy) := d
      (A*dx + B*dy)^2 / (dx^2 + dy^2 : ℝ)
    let first := head candidates h
    let max_val := foldl (init := get_priority first) 
      (λ acc d => max acc (get_priority d)) (tail candidates)
    find? (λ d => A*d.1 + B*d.2 < 0 ∧ get_priority d = max_val) dirs

theorem flow_direction_constant (A B : ℝ) (w : ℝ) (C : ℝ) (i j i' j' : ℤ) :
  flow_direction_at A B w C i j = flow_direction_at A B w C i' j' := 
  rfl

theorem flow_direction_independent_of_C (A B : ℝ) (w : ℝ) (C C' : ℝ) (i j : ℤ) :
  flow_direction_at A B w C i j = flow_direction_at A B w C' i j := 
  rfl

theorem flow_direction_independent_of_w (A B : ℝ) (w w' : ℝ) (C : ℝ) (i j : ℤ) :
  flow_direction_at A B w C i j = flow_direction_at A B w' C i j := 
  rfl
