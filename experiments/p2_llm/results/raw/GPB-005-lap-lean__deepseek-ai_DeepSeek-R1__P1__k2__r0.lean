import Mathlib.Tactic

namespace VeriGIS.LocalMaxLaplacian

noncomputable section

/-!
## 3×3 Window Convention (row offset q positive downward)

    a(-1,-1)   b( 0,-1)   c( 1,-1)
    d(-1, 0)     e        f( 1, 0)
    g(-1, 1)   h( 0, 1)   i( 1, 1)

Discrete Laplacian (Δh) at center cell e is defined as:
  Δh = (b + d + f + h - 4*e) / w²
Since w² > 0, sign(Δh) = sign(b + d + f + h - 4*e)
-/

/-- Discrete Laplacian numerator (sign determines concavity) -/
def laplacian_num (b d e f h : ℝ) : ℝ := b + d + f + h - 4 * e

/-- Orthogonal neighborhood: North(b), West(d), East(f), South(h) -/
structure OrthoMax (b d e f h : ℝ) : Prop where
  north : e ≥ b
  west  : e ≥ d
  east  : e ≥ f
  south : e ≥ h

/-!
### Main Theorem
If center cell e is local maximum in its orthogonal neighborhood,
then discrete Laplacian numerator ≤ 0.
-/
theorem local_max_implies_nonpositive_laplacian
    (b d e f h : ℝ) (h_max : OrthoMax b d e f h) :
    laplacian_num b d e f h ≤ 0 := by
  -- Expand Laplacian definition
  unfold laplacian_num
  -- Extract neighborhood maximum conditions
  have hb := h_max.north
  have hd := h_max.west
  have hf := h_max.east
  have hh := h_max.south
  -- Algebraic rearrangement: b + d + f + h ≤ 4*e
  calc
    b + d + f + h ≤ e + e + e + e := by rel [hb, hd, hf, hh]
    _ = 4 * e := by ring
  -- Conclude inequality
  linarith

end -- noncomputable section

end VeriGIS.LocalMaxLaplacian
