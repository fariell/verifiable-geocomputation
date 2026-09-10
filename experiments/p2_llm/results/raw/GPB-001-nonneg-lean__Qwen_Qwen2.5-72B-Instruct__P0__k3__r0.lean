import data.real.basic
import data.matrix.notation
import analysis.normed_space.basic
import analysis.special_functions.pow
import analysis.special_functions.exp
import analysis.special_functions.log
import analysis.special_functions.trigonometric
import analysis.special_functions.deriv
import analysis.mean_value
import analysis.normed_space.inner_product
import analysis.normed_space.normed_group_hom
import analysis.normed_space.bounded_linear_maps
import analysis.normed_space.pi_Lp
import analysis.normed_space.Lp_space
import analysis.normed_space.operator_norm
import analysis.normed_space.banach
import analysis.normed_space.bounded_linear_maps
import analysis.normed_space.normed_group_hom
import analysis.normed_space.pi_Lp
import analysis.normed_space.Lp_space
import analysis.normed_space.operator_norm
import analysis.normed_space.banach
import analysis.normed_space.banach
import analysis.normed_space.bounded_linear_maps
import analysis.normed_space.normed_group_hom
import analysis.normed_space.pi_Lp
import analysis.normed_space.Lp_space
import analysis.normed_space.operator_norm
import analysis.normed_space.banach
import analysis.normed_space.bounded_linear_maps
import analysis.normed_space.normed_group_hom
import analysis.normed_space.pi_Lp
import analysis.normed_space.Lp_space
import analysis.normed_space.operator_norm
import analysis.normed_space.banach
import analysis.normed_space.bounded_linear_maps
import analysis.normed_space.normed_group_hom
import analysis.normed_space.pi_Lp
import analysis.normed_space.Lp_space
import analysis.normed_space.operator_norm
import analysis.normed_space.banach

open real
open matrix
open normed_group
open normed_space
open inner_product_space
open bounded_linear_map
open normed_group_hom
open pi_Lp
open Lp_space
open operator_norm
open banach_space

variables (w : ℝ) (h : matrix 3 3 ℝ)

def horn_slope_square (h : matrix 3 3 ℝ) (w : ℝ) : ℝ :=
  let dzdx := (h 1 2 - h 1 0) / (2 * w)
  let dzdy := (h 2 1 - h 0 1) / (2 * w)
  dzdx * dzdx + dzdy * dzdy

lemma horn_slope_square_nonnegative (h : matrix 3 3 ℝ) (w : ℝ) (hw : w > 0) : 0 ≤ horn_slope_square h w :=
begin
  unfold horn_slope_square,
  let dzdx := (h 1 2 - h 1 0) / (2 * w),
  let dzdy := (h 2 1 - h 0 1) / (2 * w),
  have h1 : 0 ≤ dzdx * dzdx, from mul_self_nonneg dzdx,
  have h2 : 0 ≤ dzdy * dzdy, from mul_self_nonneg dzdy,
  exact add_nonneg h1 h2,
end
