import data.real.basic
import data.matrix.notation
import analysis.normed_space.inner_product
import analysis.special_functions.pow

open real
open matrix
open finset

variables (w : ℝ) (h : matrix (fin 3) (fin 3) ℝ)

-- Define the Horn slope-square operator for a 3x3 elevation window
def horn_slope_sq (h : matrix (fin 3) (fin 3) ℝ) (w : ℝ) : ℝ :=
  let dzdx := (h 1 2 - h 1 0) / (2 * w) in
  let dzdy := (h 2 1 - h 0 1) / (2 * w) in
  dzdx^2 + dzdy^2

-- Define the property that the Horn slope-square is nonnegative
def horn_slope_sq_nonnegative (h : matrix (fin 3) (fin 3) ℝ) (w : ℝ) : Prop :=
  0 ≤ horn_slope_sq h w

-- Prove that for any finite 3x3 elevation window and positive grid spacing w,
-- the Horn slope-square is nonnegative
theorem horn_slope_sq_nonnegative_of_positive_w (h : matrix (fin 3) (fin 3) ℝ) (w : ℝ) (hw : w > 0) :
  horn_slope_sq_nonnegative h w :=
begin
  -- Unfold the definition of horn_slope_sq
  unfold horn_slope_sq,
  -- Simplify the expression
  simp [pow_two, mul_comm, mul_assoc, add_nonneg],
  -- Show that both dzdx^2 and dzdy^2 are nonnegative
  have h1 : 0 ≤ (h 1 2 - h 1 0)^2 / (4 * w^2), from div_nonneg (sq_nonneg (h 1 2 - h 1 0)) (mul_pos (pos_of_gt hw) (pos_of_gt hw)),
  have h2 : 0 ≤ (h 2 1 - h 0 1)^2 / (4 * w^2), from div_nonneg (sq_nonneg (h 2 1 - h 0 1)) (mul_pos (pos_of_gt hw) (pos_of_gt hw)),
  -- Add the two nonnegative terms
  exact add_nonneg h1 h2,
end
