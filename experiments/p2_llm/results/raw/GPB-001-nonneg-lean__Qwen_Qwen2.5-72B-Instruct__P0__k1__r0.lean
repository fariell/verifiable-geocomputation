import data.real.basic
import data.matrix.notation
import analysis.normed_space.basic
import analysis.special_functions.pow

namespace HornSlope

variables {n : ℕ} [decidable_eq n] (w : ℝ) (h : matrix (fin 3) (fin 3) ℝ)

-- Define the Horn slope-square operator for a 3x3 elevation window
def horn_slope_sq (h : matrix (fin 3) (fin 3) ℝ) (w : ℝ) : ℝ :=
  let dzdx := (h 1 2 - h 1 0) / (2 * w),
      dzdy := (h 2 1 - h 0 1) / (2 * w) in
  dzdx * dzdx + dzdy * dzdy

-- Prove that the Horn slope-square is nonnegative for any finite 3x3 elevation window and positive grid spacing w
theorem horn_slope_sq_nonnegative (h : matrix (fin 3) (fin 3) ℝ) (w : ℝ) (w_pos : w > 0) : 0 ≤ horn_slope_sq h w :=
begin
  unfold horn_slope_sq,
  let dzdx := (h 1 2 - h 1 0) / (2 * w),
  let dzdy := (h 2 1 - h 0 1) / (2 * w),
  have dzdx_sq_nonneg : 0 ≤ dzdx * dzdx := real.mul_self_nonneg dzdx,
  have dzdy_sq_nonneg : 0 ≤ dzdy * dzdy := real.mul_self_nonneg dzdy,
  exact real.add_nonneg dzdx_sq_nonneg dzdy_sq_nonneg,
end

end HornSlope
