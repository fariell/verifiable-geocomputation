def fill_left {α : Type} [LinearOrder α] : List α → List α
  | [] => []
  | x::xs => List.scanl (fun acc y => max y acc) x xs

theorem fill_left_non_decreasing {α : Type} [LinearOrder α] (a : List α) :
    match fill_left a with
    | [] => True
    | x::xs => List.Chain (· ≤ ·) x xs := by
  cases a with
  | nil => simp [fill_left]
  | cons x xs =>
      simp [fill_left]
      let rec helper (init : α) (ys : List α) : List.Chain (· ≤ ·) init (List.scanl (fun acc y => max y acc) init ys) := by
        cases ys with
        | nil => exact List.Chain.nil
        | cons y ys' =>
            simp [List.scanl]
            apply List.Chain.cons
            · apply le_max_right
            · exact helper (max y init) ys'
      exact helper x xs
