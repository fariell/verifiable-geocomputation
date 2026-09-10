-- We define a Fill operator that, given a list of natural numbers,
-- returns a new list where each element is the maximum of all previous elements (including itself).
-- This is a "left-outlet" fill: it propagates the maximum seen so far from left to right.

def Fill (a : List ℕ) : List ℕ :=
  match a with
  | [] => []
  | h :: t =>
      let rec loop (current_max : ℕ) (rest : List ℕ) : List ℕ :=
        match rest with
        | [] => [current_max]
        | x :: xs =>
            let new_max := max current_max x
            new_max :: loop new_max xs
      h :: loop h t

-- The theorem: for all i in the range [0, length (Fill a) - 2], Fill(a)[i] ≤ Fill(a)[i+1]
theorem Fill_nondecreasing (a : List ℕ) :
    ∀ i : ℕ, i + 1 < (Fill a).length → (Fill a).get ⟨i, by omega⟩ ≤ (Fill a).get ⟨i + 1, by omega⟩ := by
  intro a i hlen
  unfold Fill at hlen
  -- We'll prove this by induction on `a`, but we need to track the current maximum.
  revert i
  induction' a with h t ih
  · simp [Fill]
  · intro i hlen
    simp [Fill] at hlen
    -- We'll break into cases on whether i = 0 or i > 0
    match i with
    | 0 =>
        simp [Fill]
        -- For i=0, we compare the first element with the result of the loop on the tail.
        -- The loop starts with `h` as current_max.
        -- We need to show: h ≤ (loop h t)[0] (if the tail is nonempty)
        cases t
        · simp at hlen
        · simp [Fill, loop]
          have : h ≤ max h (head t) := by
            exact le_max_left _ _
          exact this
    | i+1 =>
        -- For i+1, we shift the index in the tail.
        have : i + 1 < (loop h t).length := by
          simpa [Fill] using hlen
        -- Now we use the induction hypothesis on the tail, with the current_max = h
        -- But note: the loop on the tail is exactly `Fill (h :: t)` without the first element.
        -- Actually, we can prove a lemma about `loop`:
        --   ∀ current_max rest i, i+1 < (loop current_max rest).length → 
        --        (loop current_max rest)[i] ≤ (loop current_max rest)[i+1]
        -- We prove this by induction on `rest`.
        revert h t ih
        -- General lemma for `loop`
        intro current_max rest
        induction' rest with x xs ih_loop generalizing current_max
        · simp [loop] at hlen; omega
        · intro i hlen
          simp [loop] at hlen
          match i with
          | 0 =>
              simp [loop]
              exact le_max_right _ _
          | i+1 =>
              have hlen' : i + 1 < (loop (max current_max x) xs).length := by
                simpa [loop] using hlen
              have := ih_loop (max current_max x) i hlen'
              simp [loop] at this ⊢
              exact this
