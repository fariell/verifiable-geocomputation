variable {α : Type} [LinearOrder α]

def fill_aux (curr : α) : List α → List α
  | [] => []
  | (x::xs) => 
      let m := max curr x
      m :: fill_aux m xs

def fill : List α → List α
  | [] => []
  | (x::xs) => x :: fill_aux x xs

def NonDecreasing : List α → Prop
  | [] => True
  | [_] => True
  | (x::y::xs) => x ≤ y ∧ NonDecreasing (y::xs)

lemma non_decreasing_fill_aux (curr : α) (l : List α) : NonDecreasing (fill_aux curr l) := by
  induction l with
  | nil => simp [fill_aux, NonDecreasing]
  | cons x xs ih =>
      simp [fill_aux]
      cases xs with
      | nil => 
          simp [NonDecreasing]
      | cons y ys =>
          apply And.intro
          · apply le_max_left
          · exact ih

theorem fill_non_decreasing (a : List α) : NonDecreasing (fill a) := by
  cases a with
  | nil => simp [fill, NonDecreasing]
  | cons x xs =>
      cases xs with
      | nil => 
          simp [fill, NonDecreasing]
      | cons y ys =>
          simp [fill]
          apply And.intro
          · apply le_max_left
          · apply non_decreasing_fill_aux
