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
    have : (Fill a) = loop hd tl := rfl
    rw [this] at h
    clear this
    induction' tl with x xs IH generalizing hd i
    · simp [loop] at h
    · simp [loop] at h
      cases' i with i
      · simp [loop]
      · have : i + 1 < (loop (max hd x) xs).length := by
          simpa [loop] using h
        have IH := IH (max hd x) i this
        simp [loop] at IH ⊢
        exact IH
where
  loop (current : ℕ) (rest : List ℕ) : List ℕ :=
    match rest with
    | [] => [current]
    | h :: t =>
        let next := max current h
        current :: loop next t
