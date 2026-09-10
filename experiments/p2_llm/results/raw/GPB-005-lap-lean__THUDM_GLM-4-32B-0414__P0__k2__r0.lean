import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Basic

namespace Curvature

/-- A 3x3 window of elevation values -/
def Window := Matrix (Fin 3) (Fin 3) ℝ

/-- The center cell of a 3x3 window -/
def center (w : Window) : ℝ := w 1 1

/-- The four orthogonal neighbors of the center cell -/
def north (w : Window) : ℝ := w 0 1
def east (w : Window) : ℝ := w 1 2
def south (w : Window) : ℝ := w 2 1
def west (w : Window) : ℝ := w 1 0

/-- A cell is a discrete local maximum if it is >= each of its orthogonal neighbors -/
def isDiscreteLocalMax (w : Window) : Prop := 
  w.center ≥ w.north ∧ w.center ≥ w.east ∧ w.center ≥ w.south ∧ w.center ≥ w.west

/-- The discrete Laplacian at the center cell -/
def discreteLaplacian (w : Window) : ℝ := 
  w.north + w.east + w.south + w.west - 4 * w.center

/-- If the center cell is a discrete local maximum, then the discrete Laplacian is <= 0 -/
theorem localMaxImpliesNonPositiveLaplacian (w : Window) (h : w.isDiscreteLocalMax) : 
  w.discreteLaplacian ≤ 0 := by
  simp [discreteLaplacian, h.1, h.2.1, h.2.2.1, h.2.2.2]
  nlinarith
```

This Lean code formalizes the given natural-language specification. It defines a 3x3 window of elevation values, identifies the center cell and its four orthogonal neighbors, defines what it means for the center cell to be a discrete local maximum, defines the discrete Laplacian at the center cell, and proves that if the center cell is a discrete local maximum, then the discrete Laplacian is less than or equal to zero.
