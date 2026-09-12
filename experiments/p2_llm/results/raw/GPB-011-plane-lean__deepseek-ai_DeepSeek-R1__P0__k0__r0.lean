import Mathlib.Data.Real.Basic
import Mathlib.Data.Int.Basic
import Mathlib.Data.List.Basic

open Real

def dirs : List (ℤ × ℤ) :=
  [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]

def admissible (A B : ℝ) (d : ℤ × ℤ) : Prop :=
  A * d.1 + B * d.2 < 0

def steepness (A B : ℝ) (d : ℤ × ℤ) : ℝ :=
  (A * d.1 + B * d.2)^2 / (d.1^2 + d.2^2)

variable (A B w : ℝ) (hw : w > 0)

variable (huniq : ∃! d, d ∈ dirs ∧ admissible A B d ∧
  (∀ d' ∈ dirs, admissible A B d' → steepness A B d ≥ steepness A B d') ∧
  (∀ d' ∈ dirs, admissible A B d' → steepness A B d' = steepness A B d → d' = d))

def flow_dir : ℤ × ℤ :=
  Classical.choose huniq

def grid (C : ℝ) (i j : ℤ) : ℝ :=
  A * (w * j) + B * (w * i) + C

def flow_direction_at (C : ℝ) (i j : ℤ) : ℤ × ℤ :=
  flow_dir A B w

theorem flow_direction_constant (C₁ C₂ : ℝ) (i₁ j₁ i₂ j₂ : ℤ) :
    flow_direction_at A B w C₁ i₁ j₁ = flow_direction_at A B w C₂ i₂ j₂ :=
  rfl
