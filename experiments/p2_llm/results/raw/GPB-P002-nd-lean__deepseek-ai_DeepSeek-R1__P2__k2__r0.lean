inductive nondecreasing : List ℕ → Prop
| nil : nondecreasing []
| singleton : ∀ x, nondecreasing [x]
| step : ∀ {x y : ℕ} {zs : List ℕ}, x ≤ y → nondecreasing (y::zs) → nondecreasing (x::y::zs)

def fill_aux : ℕ → List ℕ → List ℕ
| m, [] => []
| m, (x::xs) => 
  let new := max m x
  new :: fill_aux new xs

def fill : List ℕ → List ℕ
| [] => []
| (x::xs) => x :: fill_aux x xs

lemma fill_aux_nondec (m : ℕ) (l : List ℕ) : nondecreasing (fill_aux m l) := by
  induction l with
  | nil => apply nondecreasing.nil
  | cons x xs ih =>
      unfold fill_aux
      cases xs with
      | nil => 
          apply nondecreasing.singleton
      | cons y ys =>
          have h : max m x ≤ max (max m x) y := by
            apply le_max_left
          apply nondecreasing.step h
          exact ih

theorem fill_nondecreasing (a : List ℕ) : nondecreasing (fill a) := by
  cases a with
  | nil => apply nondecreasing.nil
  | cons x xs =>
      unfold fill
      cases xs with
      | nil => apply nondecreasing.singleton
      | cons y ys =>
          have h : x ≤ max x y := by
            apply le_max_left
          apply nondecreasing.step h
          exact fill_aux_nondec x (y::ys)
