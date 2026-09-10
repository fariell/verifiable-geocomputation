import data.real.basic
import data.matrix.notation
import tactic.linarith

-- Define the type for a 3x3 elevation window
def ElevationWindow := matrix (fin 3) (fin 3) ℝ

-- Define the grid spacing
def GridSpacing := ℝ

-- Define the Horn slope-square function
def SlopeSq (w : GridSpacing) (e : ElevationWindow) : ℝ :=
  let dz_dx := (e 1 2 - e 1 0) / (2 * w),
      dz_dy := (e 2 1 - e 0 1) / (2 * w) in
  dz_dx^2 + dz_dy^2

-- Theorem: For any finite 3x3 elevation window and positive grid spacing w, the Horn slope-square is nonnegative
theorem SlopeSq_nonnegative (w : GridSpacing) (e : ElevationWindow) (hw : w > 0) :
  SlopeSq w e ≥ 0 :=
begin
  -- Unfold the definition of SlopeSq
  unfold SlopeSq,
  -- Simplify the expression
  simp [pow_two, mul_div_cancel' _ (by linarith : 2 * w ≠ 0)],
  -- Use the fact that the sum of squares is nonnegative
  linarith [sq_nonneg ((e 1 2 - e 1 0) / (2 * w)), sq_nonneg ((e 2 1 - e 0 1) / (2 * w))],
end
```

This repair addresses the following issues:
1. Ensures the definition of `SlopeSq` is correctly specified.
2. Adds the necessary hypothesis `hw : w > 0` to ensure the grid spacing is positive.
3. Uses `linarith` and `sq_nonneg` to prove that the sum of squares is nonnegative, which is the core of the theorem.
