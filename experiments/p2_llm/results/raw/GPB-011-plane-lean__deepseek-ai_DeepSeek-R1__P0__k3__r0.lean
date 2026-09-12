import Mathlib.Data.Real.Basic
import Mathlib.Data.List.Basic
import Mathlib.Data.Option.Basic

open List

namespace D8Flow

def directions : List (ℤ × ℤ) := 
  [(1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1), (0,-1), (1,-1)]

def drop (A B : ℝ) (d : ℤ × ℤ) : ℝ := 
  let (dx, dy) := d
  - (A * dx + B * dy)

def power (A B : ℝ) (d : ℤ × ℤ) : ℝ := 
  let (dx, dy) := d
  let d2 : ℝ := dx^2 + dy^2
  (drop A B d)^2 / d2

def flow_dir_val (A B : ℝ) : Option (ℤ × ℤ) :=
  foldl (λ (best : Option (ℤ × ℤ)) (d : ℤ × ℤ) =>
    if h : drop A B d > 0 then
      match best with
      | none => some d
      | some d₀ => 
          if power A B d > power A B d₀ then some d else best
    else best
  ) none directions

def flow_direction (A B : ℝ) (w : ℕ) (h_w : w ≥ 3) (C : ℝ) (i j : ℕ) 
  (hi : 1 ≤ i ∧ i ≤ w - 2) (hj : 1 ≤ j ∧ j ≤ w - 2) : Option (ℤ × ℤ) :=
  flow_dir_val A B

theorem constant_flow (A B : ℝ) (w : ℕ) (h_w : w ≥ 3) (C : ℝ)
  (i₁ j₁ i₂ j₂ : ℕ) 
  (h₁ : 1 ≤ i₁ ∧ i₁ ≤ w - 2) (h₂ : 1 ≤ j₁ ∧ j₁ ≤ w - 2)
  (h₃ : 1 ≤ i₂ ∧ i₂ ≤ w - 2) (h₄ : 1 ≤ j₂ ∧ j₂ ≤ w - 2) :
  flow_direction A B w C i₁ j₁ h₁ h₂ = flow_direction A B w C i₂ j₂ h₃ h₄ := 
by 
  unfold flow_direction
  rfl

theorem translation_invariance (A B : ℝ) (w : ℕ) (h_w : w ≥ 3) (C C' : ℝ) (i j : ℕ) 
  (h : 1 ≤ i ∧ i ≤ w - 2) (h' : 1 ≤ j ∧ j ≤ w - 2) :
  flow_direction A B w C i j h h' = flow_direction A B w C' i j h h' := 
by 
  unfold flow_direction
  rfl

end D8Flow
