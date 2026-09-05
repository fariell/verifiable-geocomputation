/- VeriGIS — formalization skeleton (Phase 1)
   Confirms the Lean 4 toolchain builds end-to-end. Real terrain-operator
   formalization (with mathlib Real analysis) is deferred to a later sprint. -/

theorem dist_sq_expand (a b : Nat) : (a + b) * (a + b) = a * a + 2 * a * b + b * b := by ring

theorem double_eq_add (n : Nat) : 2 * n = n + n := by simp

#eval "VeriGIS Lean skeleton built OK"
