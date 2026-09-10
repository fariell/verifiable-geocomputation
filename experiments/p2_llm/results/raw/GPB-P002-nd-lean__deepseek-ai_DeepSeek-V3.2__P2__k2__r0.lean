-- Define the Fill operator for a 1D sequence (list) with left outlet.
-- The Fill operator propagates the maximum value seen so far from left to right.
def Fill (a : List ℕ) : List ℕ :=
  match a with
  | [] => []
  | h :: t =>
      let rec loop (current_max : ℕ) (rest : List ℕ) : List ℕ :=
        match rest with
        | [] => []
        | x :: xs =>
          let new_max := max current_max x
          new_max :: loop new_max xs
      h :: loop h t

-- Theorem: Fill yields a nondecreasing sequence.
-- For all i, Fill(a)[i] ≤ Fill(a)[i+1] when defined.
theorem Fill_nondecreasing (a : List ℕ) :
    ∀ i, i + 1 < (Fill a).length → (Fill a).get ⟨i, by omega⟩ ≤ (Fill a).get ⟨i + 1, by omega⟩ := by
  intro a i hlen
  unfold Fill at hlen
  -- We'll prove this by induction on the list `a`.
  induction a with
  | nil =>
      simp [Fill] at hlen
  | cons h t ih =>
      -- We need to analyze the structure of `Fill (h :: t)`
      simp [Fill] at hlen
      -- The first element is `h`, then the rest is built by `loop h t`.
      -- We'll prove a helper lemma about `loop`.
      have loop_nondecreasing : ∀ (start : ℕ) (lst : List ℕ) (j : ℕ),
          j + 1 < (loop start lst).length →
          (loop start lst).get ⟨j, by omega⟩ ≤ (loop start lst).get ⟨j + 1, by omega⟩ := by
        intro start lst j hj
        induction lst generalizing start j with
        | nil => simp [loop] at hj
        | cons x xs ih_loop =>
            unfold loop at hj
            match j with
            | 0 =>
                -- First element of the loop output vs second element
                simp [loop]
                have : max start x ≤ max (max start x) (xs.head? |>.getD 0) := by
                  exact Nat.le_max_left _ _
                simpa
            | j+1 =>
                -- Shift index and recurse
                have : j + 1 < (loop (max start x) xs).length := by
                  simpa [loop] using hj
                have hrec := ih_loop (max start x) j this
                simpa [loop]
      -- Now apply the helper to our case.
      -- The list `Fill (h :: t)` is `h :: loop h t`.
      -- If i = 0, compare h and first element of loop h t.
      -- If i > 0, we are inside `loop h t`.
      match i with
      | 0 =>
          have hpos : 0 + 1 < (h :: loop h t).length := hlen
          simp at hpos
          have hloop_len : 0 < (loop h t).length := by omega
          rcases exists_of_mem_get? (by simp [hloop_len]) with ⟨v, hv⟩
          have : h ≤ v := by
            unfold loop at hv
            match t with
            | [] => simp at hv
            | x :: xs =>
                simp at hv
                have : h ≤ max h x := Nat.le_max_left h x
                simpa [loop] using this
          simpa [Fill]
      | i+1 =>
          have : i + 1 < (loop h t).length := by
            simp at hlen
            omega
          have hloop := loop_nondecreasing h t i this
          simpa [Fill]
