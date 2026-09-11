import Mathlib.Data.Real.Basic

structure Window where
  a : ℝ
  b : ℝ
  c : ℝ
  d : ℝ
  e : ℝ
  f : ℝ
  g : ℝ
  h : ℝ
  i : ℝ

def dzdx (win : Window) (w : ℝ) : ℝ :=
  (win.c + 2 * win.f + win.i - (win.a + 2 * win.d + win.g)) / (8 * w)

def dzdy (win : Window) (w : ℝ) : ℝ :=
  (win.g + 2 * win.h + win.i - (win.a + 2 * win.b + win.c)) / (8 * w)

def slopesq (win : Window) (w : ℝ) : ℝ :=
  dzdx win w ^ 2 + dzdy win w ^ 2

theorem horn_slopesq_nonneg (win : Window) {w : ℝ} (hw : w > 0) : slopesq win w ≥ 0 := by
  unfold slopesq
  apply add_nonneg
  · apply pow_two_nonneg
  · apply pow_two_nonneg
