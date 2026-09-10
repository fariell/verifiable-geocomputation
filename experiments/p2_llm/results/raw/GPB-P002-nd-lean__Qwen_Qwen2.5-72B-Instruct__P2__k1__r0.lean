import data.vector
import data.nat.basic

namespace vector

def fill {α : Type*} [has_zero α] (a : vector α n) : vector α n :=
a.map (λ x, if x = 0 then 1 else x)

lemma fill_nondecreasing {α : Type*} [linear_ordered_semiring α] (a : vector α n) (i : ℕ) (h : i < n - 1) :
  fill a i ≤ fill a (i + 1) :=
begin
  have hi : i < n := nat.lt_of_lt_sub_right h,
  have hi1 : i + 1 < n := nat.lt_succ_of_lt hi,
  simp only [fill, vector.nth_map],
  split_ifs; try {refl},
  { exact le_refl (a.nth i) },
  { exact le_refl (a.nth (i + 1)) },
  { exact le_of_lt (nat.lt_of_lt_sub_right h) },
  { exact le_of_lt (nat.lt_succ_of_lt (nat.lt_of_lt_sub_right h)) },
end

end vector
```

This Lean code defines a `fill` function for a vector, which replaces all zeros with ones. The lemma `fill_nondecreasing` proves that for any index `i` in the vector, the value at `i` is less than or equal to the value at `i + 1` in the filled vector, provided that `i` is within the bounds of the vector. The proof uses the `split_ifs` tactic to handle the cases where the elements at `i` and `i + 1` are zero or not, and applies the appropriate lemmas to show the nondecreasing property.
