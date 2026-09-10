-- Define the Fill operator for a 1D sequence (list) with left outlet.
-- Fill(a)[i] is the maximum value seen from the start up to index i.
def fill (a : List ℕ) : List ℕ :=
  a.scanl max 0 |>.tail? |>.getD []

-- Theorem: For all i, if Fill(a)[i] and Fill(a)[i+1] are defined, then Fill(a)[i] ≤ Fill(a)[i+1].
theorem fill_nondecreasing (a : List ℕ) (i : ℕ) (h : i + 1 < (fill a).length) :
    (fill a).get ⟨i, by omega⟩ ≤ (fill a).get ⟨i + 1, h⟩ := by
  unfold fill
  match a with
  | [] => simp
  | x :: xs =>
    simp [List.scanl]
    induction xs generalizing x with
    | nil => simp
    | cons y ys ih =>
      simp [List.scanl]
      intro hlen
      have hlen' : i < (List.scanl max (max 0 x) (y :: ys)).length := by
        simpa [List.length_cons] using h
      cases' i with i
      · simp [List.get]
      · have : i + 1 < (List.scanl max (max 0 x) (y :: ys)).length := by
          simpa [List.length_cons] using h
        exact ih this
