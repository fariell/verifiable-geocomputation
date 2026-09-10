import data.list.basic
import data.vector
import tactic

namespace one_dimensional_fill

-- Define the 1D left-outlet Fill operator
def fill (a : list ℕ) : list ℕ := 
  let rec fill' : list ℕ → list ℕ → list ℕ
  | []     acc := acc.reverse
  | (h::t) acc := fill' t (max h (acc.head' 0) :: acc)
  in fill' a []

-- Theorem: The 1D left-outlet Fill operator yields a nondecreasing sequence
theorem fill_nondecreasing (a : list ℕ) : ∀ i, i < fill a.length → (fill a).nth i ≤ (fill a).nth (i+1) :=
begin
  intros i hi,
  -- We need to show that the i-th element is less than or equal to the (i+1)-th element
  -- in the filled list.
  -- First, we unfold the definition of `fill` and `fill'`.
  unfold fill,
  -- We need to reason about the list produced by `fill'`.
  -- We will use induction on the list `a`.
  induction a with h t ih,
  -- Base case: If `a` is empty, the filled list is also empty, and the theorem holds vacuously.
  { simp, },
  -- Inductive step: Assume the theorem holds for `t`, and show it holds for `h::t`.
  { 
    -- We need to show that the filled list of `h::t` is nondecreasing.
    -- The filled list of `h::t` is produced by `fill' (h::t) []`.
    -- We will use the definition of `fill'` to reason about the elements.
    simp [fill'],
    -- We need to show that the i-th element of `fill' t (max h 0 :: [])` is less than or equal to the (i+1)-th element.
    -- We will use the inductive hypothesis on `t`.
    -- We need to handle the case where `i` is 0 separately.
    cases i with i,
    { 
      -- If `i` is 0, we need to show that the first element is less than or equal to the second element.
      -- The first element is `max h 0`, and the second element is `max (t.head' 0) (max h 0)`.
      simp [list.nth, list.head'],
      exact le_max_right _ _,
    },
    { 
      -- If `i` is not 0, we need to show that the (i+1)-th element of `fill' t (max h 0 :: [])` is less than or equal to the (i+2)-th element.
      -- We will use the inductive hypothesis on `t`.
      -- We need to show that the (i+1)-th element of `fill' t (max h 0 :: [])` is the same as the i-th element of `fill t`.
      -- And the (i+2)-th element of `fill' t (max h 0 :: [])` is the same as the (i+1)-th element of `fill t`.
      simp [list.nth, list.head'],
      rw list.nth_tail,
      rw list.nth_tail,
      -- Apply the inductive hypothesis.
      exact ih _ (lt_of_lt_of_le hi (list.length_tail _ _)),
    },
  },
end

end one_dimensional_fill
