import data.array.basic
import data.real.basic
import tactic

namespace VeriGIS

section PitFilling

variables {α : Type*} [linear_order α] [decidable_eq α]

def Fill (a : array α) : array α :=
  let n := a.size in
  let fill := array.mk n (λ i, if i = 0 ∨ i = n - 1 then a[i] else ⊤) in
  let visited := array.mk n (λ i, false) in
  let rec seed (i : ℕ) : unit :=
    if visited[i] then ()
    else do
      fill[i] := a[i],
      visited[i] := true,
      if i > 0 then seed (i - 1),
      if i < n - 1 then seed (i + 1)
  seed 0;
  seed (n - 1);
  fill

def nondecreasing (a : array α) : Prop :=
  ∀ i, i < a.size - 1 → a[i] ≤ a[i + 1]

lemma Fill_nondecreasing (a : array α) : nondecreasing (Fill a) :=
begin
  let n := a.size,
  let fill := Fill a,
  intros i hi,
  have h0 : i < n - 1, from hi,
  have h1 : i + 1 < n, from nat.lt_of_lt_of_le hi (nat.pred_le_pred (nat.lt_succ_self n)),
  have h2 : fill[i] = a[i] ∨ fill[i] = ⊤, from if_pos (or.inl (eq.refl i)),
  have h3 : fill[i + 1] = a[i + 1] ∨ fill[i + 1] = ⊤, from if_pos (or.inr (eq.refl (i + 1))),
  cases h2 with h2 h2,
  { cases h3 with h3 h3,
    { exact le_refl (a[i]) },
    { exact le_top (a[i]) } },
  { cases h3 with h3 h3,
    { exact le_top (a[i + 1]) },
    { exact le_top (a[i]) } }
end

end PitFilling

end VeriGIS
