import data.real.basic
import data.matrix.notation
import tactic.linarith

namespace GeoProofBench

variables {n : ℕ} (w : ℝ) (h : matrix (fin 3) (fin 3) ℝ)

def grid_spacing_pos (w : ℝ) : Prop := w > 0

def horn_slope_sq (h : matrix (fin 3) (fin 3) ℝ) (w : ℝ) : ℝ :=
  let dzdx := (h 1 2 - h 1 0) / (2 * w)
  let dzdy := (h 2 1 - h 0 1) / (2 * w)
  dzdx^2 + dzdy^2

theorem horn_slope_sq_nonnegative (w : ℝ) (h : matrix (fin 3) (fin 3) ℝ) (hw : grid_spacing_pos w) :
  horn_slope_sq w h ≥ 0 :=
begin
  unfold horn_slope_sq,
  simp only [sub_eq_add_neg, mul_comm, mul_assoc, pow_two, add_nonneg],
  have h1 : (h 1 2 - h 1 0) / (2 * w) ≥ 0 ∨ (h 1 2 - h 1 0) / (2 * w) < 0, by linarith,
  have h2 : (h 2 1 - h 0 1) / (2 * w) ≥ 0 ∨ (h 2 1 - h 0 1) / (2 * w) < 0, by linarith,
  cases h1 with h1_pos h1_neg,
  cases h2 with h2_pos h2_neg,
  { -- Case 1: dzdx ≥ 0 and dzdy ≥ 0
    have h1_sq : ((h 1 2 - h 1 0) / (2 * w))^2 ≥ 0, by linarith,
    have h2_sq : ((h 2 1 - h 0 1) / (2 * w))^2 ≥ 0, by linarith,
    linarith [h1_sq, h2_sq] },
  { -- Case 2: dzdx ≥ 0 and dzdy < 0
    have h1_sq : ((h 1 2 - h 1 0) / (2 * w))^2 ≥ 0, by linarith,
    have h2_sq : ((h 2 1 - h 0 1) / (2 * w))^2 ≥ 0, by linarith,
    linarith [h1_sq, h2_sq] },
  { -- Case 3: dzdx < 0 and dzdy ≥ 0
    have h1_sq : ((h 1 2 - h 1 0) / (2 * w))^2 ≥ 0, by linarith,
    have h2_sq : ((h 2 1 - h 0 1) / (2 * w))^2 ≥ 0, by linarith,
    linarith [h1_sq, h2_sq] },
  { -- Case 4: dzdx < 0 and dzdy < 0
    have h1_sq : ((h 1 2 - h 1 0) / (2 * w))^2 ≥ 0, by linarith,
    have h2_sq : ((h 2 1 - h 0 1) / (2 * w))^2 ≥ 0, by linarith,
    linarith [h1_sq, h2_sq] },
end

end GeoProofBench
