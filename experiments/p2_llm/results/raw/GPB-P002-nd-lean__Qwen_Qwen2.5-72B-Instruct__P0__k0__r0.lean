import data.array.basic
import data.real.basic
import tactic

namespace VeriGIS

section PitFilling

variables {α : Type*} [decidable_eq α] [linear_order α]

def fill (a : array α) : array α :=
  let n := a.size in
  let fill := λ i, if i = 0 ∨ i = n - 1 then a[i] else max a[i] (fill a[i-1]) in
  array.of_fn fill

lemma fill_nondecreasing (a : array α) (i : ℕ) (h : i < a.size - 1) :
  fill a[i] ≤ fill a[i+1] :=
begin
  let n := a.size,
  let fill := λ i, if i = 0 ∨ i = n - 1 then a[i] else max a[i] (fill a[i-1]),
  have h_fill : ∀ i, i < n → fill a[i] = if i = 0 ∨ i = n - 1 then a[i] else max a[i] (fill a[i-1]),
  { intros i hi, simp [fill, hi], },
  cases i,
  { -- i = 0
    simp [h_fill, h],
    split_ifs,
    { exact le_refl (a[0]) },
    { exact le_max_right _ _ },
  },
  { -- i > 0
    simp [h_fill, h],
    split_ifs,
    { exact le_refl (a[i+1]) },
    { exact le_max_right _ _ },
    { exact le_max_left _ _ },
    { exact le_max_of_le_left (le_max_right _ _) },
  },
end

end PitFilling

end VeriGIS
