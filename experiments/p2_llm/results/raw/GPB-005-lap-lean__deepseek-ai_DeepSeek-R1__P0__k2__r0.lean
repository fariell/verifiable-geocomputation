import Mathlib.Data.Real.Basic

/-!
We formalize the property about a 3x3 grid window in digital elevation models (DEM):
If the center cell is a discrete local maximum (≥ all four orthogonal neighbors),
then the discrete Laplacian at the center is ≤ 0.

Notation:
  c : elevation at center
  n, s, w, e : elevations at north/south/west/east neighbors

The discrete Laplacian is defined as: (n + s + w + e) - 4*c
-/

theorem local_max_implies_nonpositive_laplacian
  (c n s w e : ℝ)  -- Elevations: center, north, south, west, east
  (h_n : c ≥ n)    -- Center ≥ north neighbor
  (h_s : c ≥ s)    -- Center ≥ south neighbor
  (h_w : c ≥ w)    -- Center ≥ west neighbor
  (h_e : c ≥ e)    -- Center ≥ east neighbor
  :
  (n + s + w + e) - 4 * c ≤ 0 := by
  -- Rewrite goal as sum of non-positive differences
  have h1 : n - c ≤ 0 := by linarith
  have h2 : s - c ≤ 0 := by linarith
  have h3 : w - c ≤ 0 := by linarith
  have h4 : e - c ≤ 0 := by linarith
  -- Combine differences algebraically
  calc
    (n + s + w + e) - 4 * c
      = (n - c) + (s - c) + (w - c) + (e - c) := by ring
    _ ≤ 0 + 0 + 0 + 0 := by gcongr
    _ = 0 := by simp
