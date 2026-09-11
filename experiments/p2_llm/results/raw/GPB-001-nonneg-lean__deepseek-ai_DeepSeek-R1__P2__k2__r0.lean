import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

def slopeSq (window : Matrix (Fin 3) (Fin 3) ℝ) (w : ℝ) : ℝ :=
  let a := window 0 0
  let b := window 0 1
  let c := window 0 2
  let d := window 1 0
  let f := window 1 2
  let g := window 2 0
  let h := window 2 1
  let i := window 2 2
  let dx := (c + 2*f + i - a - 2*d - g) / (8 * w)
  let dy := (g + 2*h + i - a - 2*b - c) / (8 * w)
  dx^2 + dy^2

theorem horn_slopeSq_nonneg (window : Matrix (Fin 3) (Fin 3) ℝ) {w : ℝ} (hw : w > 0) :
    slopeSq window w ≥ 0 := by
  unfold slopeSq
  apply add_nonneg
  · apply pow_two_nonneg
  · apply pow_two_nonneg
