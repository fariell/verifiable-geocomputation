import data.real.basic
import data.matrix.notation
import tactic.linarith

namespace HornSlope

variables {n : ℕ} (w : ℝ) [fact (0 < w)]

-- Define a 3x3 elevation window as a 3x3 matrix of real numbers
def elevation_window := matrix (fin 3) (fin 3) ℝ

-- Define the Horn slope-square operator
def horn_slope_square (h : elevation_window) : ℝ :=
let dzdx := (h 1 2 - h 1 0) / (2 * w),
    dzdy := (h 2 1 - h 0 1) / (2 * w) in
(dzdx^2 + dzdy^2)

-- Theorem: For any finite 3x3 elevation window and positive grid spacing w, the Horn slope-square is nonnegative
theorem horn_slope_square_nonnegative (h : elevation_window) (w_pos : 0 < w) : 0 ≤ horn_slope_square h w :=
begin
  unfold horn_slope_square,
  let dzdx := (h 1 2 - h 1 0) / (2 * w),
  let dzdy := (h 2 1 - h 0 1) / (2 * w),
  have dzdx_sq_nonneg : 0 ≤ dzdx^2 := sq_nonneg dzdx,
  have dzdy_sq_nonneg : 0 ≤ dzdy^2 := sq_nonneg dzdy,
  linarith,
end

end HornSlope
