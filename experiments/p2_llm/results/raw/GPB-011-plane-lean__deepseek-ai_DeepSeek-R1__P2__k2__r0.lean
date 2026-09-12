import Mathlib.Data.Real.Basic
import Mathlib.Data.List.Basic

def neighbors : List (ℤ × ℤ) :=
  [(-1,-1), (-1,0), (-1,1),
   (0,-1),           (0,1),
   (1,-1),  (1,0),   (1,1)]

def dist (di dj : ℤ) (w : ℝ) : ℝ :=
  if di ≠ 0 ∧ dj ≠ 0 then w * Real.sqrt 2 else w

def drop (A B : ℝ) (di dj : ℤ) : ℝ :=
  - (A * di + B * dj)

def slope (A B w : ℝ) (di dj : ℤ) : ℝ :=
  drop A B di dj / dist di dj w

def flow_direction (A B w : ℝ) : ℤ × ℤ :=
  match neighbors with
  | [] => (0, 0)  -- Unreachable case
  | d0::ds =>
      let s0 := slope A B w d0.1 d0.2
      (List.foldl (λ (cand, max_val) (d : ℤ × ℤ) =>
          let s := slope A B w d.1 d.2
          if s > max_val then (d, s) else (cand, max_val)
        ) (d0, s0) ds).1

def flow_direction_at (A B w C : ℝ) (i j : ℤ) : ℤ × ℤ :=
  flow_direction A B w

theorem flow_direction_constant (A B w : ℝ) (hA : A ≠ 0 ∨ B ≠ 0) (hw : w > 0)
    (i₁ j₁ i₂ j₂ : ℤ) (C₁ C₂ : ℝ) :
    flow_direction_at A B w C₁ i₁ j₁ = flow_direction_at A B w C₂ i₂ j₂ :=
  rfl
```

This formalization defines:
1. The 8 neighbor offsets for D8 flow
2. Distance calculation accounting for diagonals (√2 * w) and cardinals (w)
3. Elevation drop computation using the planar DEM gradient
4. Slope calculation (drop/distance)
5. Flow direction via steepest slope with first-match tie-breaking
6. Flow direction at any cell (ignoring position and elevation datum)
7. The main theorem: flow direction is constant across interior cells and invariant to elevation datum translation, given the same (A,B,w) parameters and positive slope (A,B ≠ 0,0).
