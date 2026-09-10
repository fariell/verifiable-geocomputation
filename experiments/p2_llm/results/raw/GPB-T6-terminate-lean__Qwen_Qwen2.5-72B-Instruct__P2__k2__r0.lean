import data.finset
import tactic

variables {α : Type*} [fintype α] [decidable_eq α]

-- Define a strict descent successor function
def strict_descent_successor (f : α → α) (lt : α → α → Prop) : Prop :=
  ∀ x, f x ≠ x → lt (f x) x

-- Define a fixed point
def is_fixed_point (f : α → α) (x : α) : Prop := f x = x

-- Define the orbit of a point under a function
def orbit (f : α → α) (x : α) : set α := {y | ∃ n : ℕ, f^[n] x = y}

-- Define a measure function that decreases along the orbit
def measure (f : α → α) (lt : α → α → Prop) (x : α) : ℕ :=
  finset.univ.filter (λ y, y ∈ orbit f x).card

-- The main theorem: Under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem strict_descent_orbit_terminates (f : α → α) (lt : α → α → Prop) (h : strict_descent_successor f lt) :
  ∀ x : α, ∃ y : α, is_fixed_point f y ∧ y ∈ orbit f x :=
begin
  -- Use well-founded induction on the measure function
  refine well_founded.induction (measure_wf f lt) _,
  -- Assume the induction hypothesis
  intros x ih,
  -- If x is a fixed point, we are done
  by_cases hfx : f x = x,
  { use x, split, exact hfx, exact ⟨0, hfx⟩ },
  -- Otherwise, use the strict descent property
  { have hlt : lt (f x) x := h x hfx,
    -- Apply the induction hypothesis to f x
    have ih_fx : ∃ y : α, is_fixed_point f y ∧ y ∈ orbit f (f x),
      from ih (f x) (measure_decreases f lt x hfx),
    -- Extract the fixed point from the induction hypothesis
    cases ih_fx with y hy,
    use y, split, exact hy.1, exact ⟨1, hy.2⟩ },
end

-- Lemma: The measure function is well-founded
lemma measure_wf (f : α → α) (lt : α → α → Prop) : well_founded (λ x y, measure f lt x < measure f lt y) :=
begin
  -- Use the well-foundedness of the natural numbers
  apply nat.lt_wf,
  -- Show that the measure function decreases
  intros x y hxy,
  -- If y is in the orbit of x, then the measure of y is less than the measure of x
  rw measure,
  rw measure,
  -- Use the fact that the orbit of y is a subset of the orbit of x, minus x itself
  apply finset.card_lt_card,
  -- Show that the orbit of y is a subset of the orbit of x
  apply finset.subset_of_mem_of_subset (finset.mem_univ y),
  -- Show that the orbit of y is a proper subset of the orbit of x
  apply finset.proper_subset_of_subset_of_ne (finset.subset_of_mem_of_subset (finset.mem_univ x)),
  -- Show that x is not in the orbit of y
  intros hxy',
  -- If x were in the orbit of y, then the measure of y would not be less than the measure of x
  have hxy'' : measure f lt y < measure f lt x := hxy,
  -- This leads to a contradiction
  exact lt_irrefl (measure f lt x) (lt_trans hxy'' (measure_decreases f lt x hfx)),
end

-- Lemma: The measure function decreases along the orbit
lemma measure_decreases (f : α → α) (lt : α → α → Prop) (x : α) (hfx : f x ≠ x) : measure f lt (f x) < measure f lt x :=
begin
  -- The measure of f x is the cardinality of the orbit of f x
  rw measure,
  -- The measure of x is the cardinality of the orbit of x
  rw measure,
  -- The orbit of f x is a subset of the orbit of x, minus x itself
  apply finset.card_lt_card,
  -- Show that the orbit of f x is a subset of the orbit of x
  apply finset.subset_of_mem_of_subset (finset.mem_univ (f x)),
  -- Show that the orbit of f x is a proper subset of the orbit of x
  apply finset.proper_subset_of_subset_of_ne (finset.subset_of_mem_of_subset (finset.mem_univ x)),
  -- Show that x is not in the orbit of f x
  intros hxy,
  -- If x were in the orbit of f x, then f x would be a fixed point
  have hfix : is_fixed_point f (f x) := hxy.2,
  -- This contradicts the strict descent property
  exact hfx (hfix.1),
end
```

This Lean code formalizes the theorem that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point. It uses a well-founded induction on a measure function that counts the number of elements in the orbit of a point, ensuring that the measure decreases with each step in the orbit, which justifies the termination at a fixed point.
