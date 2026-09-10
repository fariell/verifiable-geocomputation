import data.real.basic
import data.matrix.notation
import tactic.linarith

namespace VeriGIS

-- Define a 3x3 grid of real numbers
def Grid3x3 := matrix (fin 3) (fin 3) ℝ

-- Define the center cell of a 3x3 grid
def center (g : Grid3x3) : ℝ := g 1 1

-- Define the orthogonal neighbors of the center cell in a 3x3 grid
def north (g : Grid3x3) : ℝ := g 0 1
def south (g : Grid3x3) : ℝ := g 2 1
def east (g : Grid3x3) : ℝ := g 1 2
def west (g : Grid3x3) : ℝ := g 1 0

-- Define the discrete Laplacian at the center cell of a 3x3 grid
def discreteLaplacian (g : Grid3x3) : ℝ := (north g + south g + east g + west g - 4 * center g)

-- Property: If the center cell is a discrete local maximum, then the discrete Laplacian at the center is <= 0
theorem discreteLocalMax_implies_nonPositiveLaplacian (g : Grid3x3) :
  (center g ≥ north g) ∧ (center g ≥ south g) ∧ (center g ≥ east g) ∧ (center g ≥ west g) →
  discreteLaplacian g ≤ 0 :=
begin
  intros h,
  have h1 := h.1,
  have h2 := h.2,
  have h3 := h.3,
  have h4 := h.4,
  have h5 : north g + south g + east g + west g ≤ 4 * center g,
  { linarith },
  have h6 : north g + south g + east g + west g - 4 * center g ≤ 0,
  { linarith },
  exact h6,
end

end VeriGIS
