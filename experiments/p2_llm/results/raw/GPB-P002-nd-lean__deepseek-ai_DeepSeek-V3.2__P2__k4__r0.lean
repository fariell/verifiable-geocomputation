def Fill (a : List ℕ) : List ℕ :=
  match a with
  | [] => []
  | h :: t =>
      let rec loop (current : ℕ) (rest : List ℕ) : List ℕ :=
        match rest with
        | [] => [current]
        | h :: t =>
            let next := max current h
            current :: loop next t
      loop h t

theorem Fill_nondecreasing (a : List ℕ) :
    ∀ i, i + 1 < (Fill a).length → (Fill a).get ⟨i, by omega⟩ ≤ (Fill a).get ⟨i + 1, by omega⟩ := by
  intro a i h
  unfold Fill at h
  split at h
  · simp at h
  · rename_i hd tl
    have : i < (Fill (hd :: tl)).length := by omega
    simp [Fill] at this h
    induction' tl with x xs IH generalizing hd i
    · simp at h
    · simp [Fill] at h
      match i with
      | 0 =>
          simp [Fill]
          exact Nat.le_max_left _ _
      | i+1 =>
          have : i + 1 < (Fill (max hd x :: xs)).length := by
            simpa [Fill] using h
          have IH' := IH (max hd x) i this
          simpa [Fill] using IH'
