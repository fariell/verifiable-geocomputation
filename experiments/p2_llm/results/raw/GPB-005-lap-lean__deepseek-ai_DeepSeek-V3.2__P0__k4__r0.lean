import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

-- A 3x3 window of elevations represented as a 3×3 matrix of real numbers
abbrev Window := Matrix (Fin 3) (Fin 3) ℝ

-- Get the center cell elevation
def center (w : Window) : ℝ := w 1 1

-- Get the four orthogonal neighbors: north, south, east, west
def north (w : Window) : ℝ := w 0 1
def south (w : Window) : ℝ := w 2 1
def east (w : Window) : ℝ := w 1 2
def west (w : Window) : ℝ := w 1 0

-- Discrete local maximum condition: center ≥ each orthogonal neighbor
def is_local_max (w : Window) : Prop :=
  center w ≥ north w ∧ center w ≥ south w ∧ center w ≥ east w ∧ center w ≥ west w

-- Discrete Laplacian at the center: Δ = (north + south + east + west) - 4 * center
def laplacian (w : Window) : ℝ :=
  north w + south w + east w + west w - 4 * center w

-- The theorem: if the center is a discrete local maximum, then the Laplacian ≤ 0
theorem local_max_implies_nonpositive_laplacian (w : Window) (h : is_local_max w) :
    laplacian w ≤ 0 := by
  -- Unpack the local maximum hypothesis
  rcases h with ⟨h_north, h_south, h_east, h_west⟩
  -- Expand the definition of laplacian
  unfold laplacian
  -- Rewrite each neighbor inequality as `center w - neighbor ≥ 0`
  have hn : center w - north w ≥ 0 := by linarith
  have hs : center w - south w ≥ 0 := by linarith
  have he : center w - east w ≥ 0 := by linarith
  have hw : center w - west w ≥ 0 := by linarith
  -- Combine the four nonnegative differences
  have h_sum : (center w - north w) + (center w - south w) + (center w - east w) + (center w - west w) ≥ 0 := by
    nlinarith
  -- Simplify the sum
  have h_simplified : 4 * center w - (north w + south w + east w + west w) ≥ 0 := by
    ring_nf at h_sum ⊢
    exact h_sum
  -- Rearrange to get the desired inequality
  linarith
