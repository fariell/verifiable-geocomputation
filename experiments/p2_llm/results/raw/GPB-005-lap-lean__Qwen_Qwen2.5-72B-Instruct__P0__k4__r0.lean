import data.real.basic
import data.matrix.notation
import tactic.linarith

namespace VeriGIS

section Curvature

variables {α : Type} [decidable_eq α] [linear_ordered_field α]

def discrete_laplacian (h : matrix (fin 3) (fin 3) α) (dx dy : α) : α :=
  (h 1 0 - 2 * h 1 1 + h 1 2) / dx^2 + (h 0 1 - 2 * h 1 1 + h 2 1) / dy^2

def is_discrete_local_maximum (h : matrix (fin 3) (fin 3) α) : Prop :=
  h 1 1 ≥ h 1 0 ∧ h 1 1 ≥ h 1 2 ∧ h 1 1 ≥ h 0 1 ∧ h 1 1 ≥ h 2 1

lemma discrete_laplacian_nonpositive_of_local_maximum (h : matrix (fin 3) (fin 3) α) (dx dy : α) (hdx : dx > 0) (hdy : dy > 0) :
  is_discrete_local_maximum h → discrete_laplacian h dx dy ≤ 0 :=
begin
  intros h_max,
  have h10_le_h11 : h 1 0 ≤ h 1 1 := h_max.1.1,
  have h12_le_h11 : h 1 2 ≤ h 1 1 := h_max.1.2,
  have h01_le_h11 : h 0 1 ≤ h 1 1 := h_max.2.1,
  have h21_le_h11 : h 2 1 ≤ h 1 1 := h_max.2.2,

  have hxx_le_0 : (h 1 0 - 2 * h 1 1 + h 1 2) / dx^2 ≤ 0,
  { linarith [h10_le_h11, h12_le_h11] },

  have hyy_le_0 : (h 0 1 - 2 * h 1 1 + h 2 1) / dy^2 ≤ 0,
  { linarith [h01_le_h11, h21_le_h11] },

  linarith [hxx_le_0, hyy_le_0],
end

end Curvature

end VeriGIS
