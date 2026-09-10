import data.real.basic
import data.matrix.notation
import tactic.linarith

namespace VeriGIS

section Curvature

variables {α : Type} [decidable_eq α] [has_zero α] [has_one α] [has_add α] [has_sub α] [has_mul α] [has_le α] [has_lt α] [has_pow α] [has_inv α] [has_div α] [has_neg α] [linear_ordered_field α]

def discrete_laplacian (h : matrix (fin 3) (fin 3) α) (dx dy : α) : α :=
  (h 1 0 - 2 * h 1 1 + h 1 2) / dx^2 + (h 0 1 - 2 * h 1 1 + h 2 1) / dy^2

def is_discrete_local_maximum (h : matrix (fin 3) (fin 3) α) : Prop :=
  h 1 1 ≥ h 1 0 ∧ h 1 1 ≥ h 1 2 ∧ h 1 1 ≥ h 0 1 ∧ h 1 1 ≥ h 2 1

lemma discrete_laplacian_nonpositive_of_local_maximum (h : matrix (fin 3) (fin 3) α) (dx dy : α) (hdx : dx > 0) (hdy : dy > 0) (hmax : is_discrete_local_maximum h) : discrete_laplacian h dx dy ≤ 0 :=
begin
  have h10 : h 1 0 ≤ h 1 1 := hmax.1,
  have h12 : h 1 2 ≤ h 1 1 := hmax.2,
  have h01 : h 0 1 ≤ h 1 1 := hmax.3,
  have h21 : h 2 1 ≤ h 1 1 := hmax.4,

  have hxx : (h 1 0 - 2 * h 1 1 + h 1 2) / dx^2 ≤ 0,
  { linarith [h10, h12] },

  have hyy : (h 0 1 - 2 * h 1 1 + h 2 1) / dy^2 ≤ 0,
  { linarith [h01, h21] },

  linarith [hxx, hyy],
end

end Curvature

end VeriGIS
