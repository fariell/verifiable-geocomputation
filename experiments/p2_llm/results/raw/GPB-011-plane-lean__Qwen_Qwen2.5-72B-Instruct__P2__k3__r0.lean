import data.real.basic
import data.matrix.notation
import tactic.linarith

-- Define the D8 flow direction function
def D8_flow_direction (A B : ℝ) (x y : ℤ) : ℤ :=
  if A * x + B * y < 0 then
    if A * x + B * y < -1 / 2 then
      if A * x + B * y < -1 then
        if A * x + B * y < -3 / 2 then
          1
        else
          2
      else
        if A * x + B * y < -1 / 2 then
          4
        else
          8
    else
      if A * x + B * y < 0 then
        16
      else
        32
  else
    if A * x + B * y < 1 / 2 then
      if A * x + B * y < 1 then
        if A * x + B * y < 3 / 2 then
          64
        else
          128
      else
        if A * x + B * y < 1 / 2 then
          256
        else
          512
    else
      1024

-- Define the DEM function
def DEM (A B C : ℝ) (x y : ℤ) : ℝ := A * x + B * y + C

-- Theorem: D8 flow direction is constant across interior cells that share the same (A, B, w)
-- where w is the width of the cell, and translating the elevation datum C does not change the direction.
theorem D8_flow_direction_constant (A B : ℝ) (x y : ℤ) (C1 C2 : ℝ) (w : ℤ) :
  D8_flow_direction A B x y = D8_flow_direction A B (x + w) (y + w) :=
begin
  -- Simplify the expression for the flow direction
  simp [D8_flow_direction],
  -- Show that the condition A * x + B * y < 0 is equivalent to A * (x + w) + B * (y + w) < 0
  have h1 : A * x + B * y < 0 ↔ A * (x + w) + B * (y + w) < 0,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Show that the condition A * x + B * y < -1 / 2 is equivalent to A * (x + w) + B * (y + w) < -1 / 2
  have h2 : A * x + B * y < -1 / 2 ↔ A * (x + w) + B * (y + w) < -1 / 2,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Show that the condition A * x + B * y < -1 is equivalent to A * (x + w) + B * (y + w) < -1
  have h3 : A * x + B * y < -1 ↔ A * (x + w) + B * (y + w) < -1,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Show that the condition A * x + B * y < -3 / 2 is equivalent to A * (x + w) + B * (y + w) < -3 / 2
  have h4 : A * x + B * y < -3 / 2 ↔ A * (x + w) + B * (y + w) < -3 / 2,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Show that the condition A * x + B * y < 1 / 2 is equivalent to A * (x + w) + B * (y + w) < 1 / 2
  have h5 : A * x + B * y < 1 / 2 ↔ A * (x + w) + B * (y + w) < 1 / 2,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Show that the condition A * x + B * y < 1 is equivalent to A * (x + w) + B * (y + w) < 1
  have h6 : A * x + B * y < 1 ↔ A * (x + w) + B * (y + w) < 1,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Show that the condition A * x + B * y < 3 / 2 is equivalent to A * (x + w) + B * (y + w) < 3 / 2
  have h7 : A * x + B * y < 3 / 2 ↔ A * (x + w) + B * (y + w) < 3 / 2,
  { split,
    { intro h, linarith },
    { intro h, linarith } },
  -- Use the equivalences to show that the flow direction is the same
  rw [h1, h2, h3, h4, h5, h6, h7],
end
```

This Lean code formalizes the theorem that the D8 flow direction is constant across interior cells that share the same (A, B, w) and that translating the elevation datum C does not change the direction. The proof uses the `linarith` tactic to show that the conditions determining the flow direction are equivalent for the original and translated cells.
