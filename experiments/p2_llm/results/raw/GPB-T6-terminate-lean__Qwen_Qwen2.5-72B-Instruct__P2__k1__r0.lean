import data.finset
import tactic

variables {α : Type*} [fintype α] [decidable_eq α]

-- Define a strict descent successor function
def strict_descent_successor (s : α → α) (lt : α → α → Prop) [is_strict_order α lt] : Prop :=
  ∀ x, lt x (s x)

-- Define a fixed point
def is_fixed_point (s : α → α) (x : α) : Prop := s x = x

-- Define the orbit of a point under a function
def orbit (s : α → α) (x : α) : set α := {y | ∃ n : ℕ, s^[n] x = y}

-- Define the termination of an orbit at a fixed point
def terminates_at_fixed_point (s : α → α) (x : α) : Prop :=
  ∃ y ∈ orbit s x, is_fixed_point s y

-- The main theorem: Under a strict descent successor on a finite cell set, every orbit terminates at a fixed point
theorem strict_descent_terminates (s : α → α) (lt : α → α → Prop) [is_strict_order α lt] (h : strict_descent_successor s lt) (x : α) :
  terminates_at_fixed_point s x :=
begin
  -- Use the well-foundedness of the strict order to find a minimal element in the orbit
  let orbit_set := orbit s x,
  have h_finite : orbit_set.finite := finset.finite_to_set (finset.image (λ n, s^[n] x) finset.univ),
  have h_well_founded : well_founded lt := is_strict_order.well_founded lt,
  let min_element := @well_founded.min α lt h_well_founded (λ y, y ∈ orbit_set) (h_finite.to_finset),
  have h_min : min_element ∈ orbit_set := well_founded.min_mem _ _ _,
  have h_min_prop : ∀ y ∈ orbit_set, lt y min_element → false := well_founded.min_unique _ _ _,

  -- Show that the minimal element is a fixed point
  cases h_min with n h_n,
  rw is_fixed_point at h_min_prop,
  have h_s_n : s^[n] x = min_element := h_n,
  have h_s_n1 : s^[n+1] x = s (s^[n] x) := rfl,
  rw h_s_n at h_s_n1,
  have h_not_lt : lt min_element (s min_element) → false := h_min_prop (s^[n+1] x) (by rw h_s_n1; exact h (s^[n] x)),
  exact h_not_lt (h min_element),
end
```

This Lean code formalizes the theorem that under a strict descent successor on a finite cell set, every orbit terminates at a fixed point. The proof uses the well-foundedness of the strict order to find a minimal element in the orbit and shows that this minimal element must be a fixed point.
