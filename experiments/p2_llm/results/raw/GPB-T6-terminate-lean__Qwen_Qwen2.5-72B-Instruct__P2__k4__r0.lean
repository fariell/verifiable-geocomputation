import data.fintype.basic
import tactic.wlog
import tactic.basic

variables {α : Type*} [fintype α] [decidable_eq α]

-- Define a strict descent successor
def strict_descent_successor (s : α → α) (lt : α → α → Prop) : Prop :=
∀ x, lt x (s x)

-- Define a fixed point
def is_fixed_point (s : α → α) (x : α) : Prop :=
s x = x

-- Define the orbit of a point under a successor function
def orbit (s : α → α) (x : α) : set α :=
{x' | ∃ n : ℕ, x' = nat.iterate s n x}

-- Define the termination of an orbit at a fixed point
def terminates_at_fixed_point (s : α → α) (x : α) : Prop :=
∃ y : α, is_fixed_point s y ∧ y ∈ orbit s x

-- Define a measure function for the orbit
def measure (s : α → α) (lt : α → α → Prop) (x : α) : ℕ :=
fintype.card {y : α | y ∈ orbit s x ∧ ¬ is_fixed_point s y}

-- The main theorem: Under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem strict_descent_terminates (s : α → α) (lt : α → α → Prop) (h1 : strict_descent_successor s lt) (h2 : well_founded lt) (x : α) :
terminates_at_fixed_point s x :=
begin
  -- Use the well-foundedness of the relation to find a minimal element in the orbit
  have h3 : ∃ y ∈ orbit s x, ∀ y' ∈ orbit s x, ¬ lt y y',
  { apply well_founded.min h2 (orbit s x),
    -- Show that the orbit is nonempty
    use x,
    simp [orbit],
    use 0,
    refl, },
  cases h3 with y hy,
  cases hy with hy1 hy2,
  -- Show that this minimal element is a fixed point
  have h4 : is_fixed_point s y,
  { by_contra h4,
    -- If y is not a fixed point, then s y is in the orbit and lt y (s y)
    have h5 : s y ∈ orbit s x,
    { simp [orbit],
      use 1,
      refl, },
    have h6 : lt y (s y) := h1 y,
    -- This contradicts the minimality of y
    exact hy2 (s y) h5 h6, },
  -- Therefore, the orbit terminates at y
  use y,
  split,
  { exact h4, },
  { exact hy1, },
end
```

This Lean code formalizes the theorem that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point. It uses a well-founded relation to find a minimal element in the orbit and shows that this element must be a fixed point, thus proving the termination of the orbit.
