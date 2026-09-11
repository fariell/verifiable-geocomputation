import Mathlib.Data.Nat.Basic
import Mathlib.Data.Nat.Lcm
import Mathlib.Data.Nat.Gcd
import Mathlib.Data.Nat.Prime
import Mathlib.Data.Nat.Factorization
import Mathlib.Data.Nat.Coprime
import Mathlib.Data.Nat.Gcd
import Mathlib.Data.Nat.Prime
import Mathlib.Data.Nat.Factorization
import Mathlib.Data.Nat.Coprime
import Mathlib.Data.Nat.Gcd
import Mathlib.Data.Nat.Prime
import Mathlib.Data.Nat.Factorization
import Mathlib.Data.Nat.Coprime

universe u

structure Cell where
  row : ℕ
  col : ℕ
deriving Repr

def Cell.succ (h : Array (Array Float)) (c : Cell) : Option Cell := 
  let d := d8_at h c.row c.col
  if d == "NoFlow" then none
  else
    let dp, dq := _delta d
    let nr, nc := c.row + dq, c.col + dp
    if 0 ≤ nr ∧ nr < h.size ∧ 0 ≤ nc ∧ nc < h[0].size then
      some ⟨nr, nc⟩
    else
      none

def Cell.orbit (h : Array (Array Float)) (c : Cell) : List Cell :=
  let rec aux (c : Cell) (visited : List Cell) : List Cell :=
    if visited.contains c then
      visited
    else
      match c.succ h with
      | none => c :: visited
      | some c' => aux c' (c :: visited)
  aux c []

def Cell.fixedPoint (h : Array (Array Float)) (c : Cell) : Option Cell :=
  c.orbit h |>.last?

def Cell.terminates (h : Array (Array Float)) (c : Cell) : Prop :=
  c.fixedPoint h |>.isSome

lemma Cell.terminates_iff_orbit_finite (h : Array (Array Float)) (c : Cell) :
    c.terminates h ↔ c.orbit h |>.length < ∞ := by
  simp [Cell.terminates, Cell.orbit]
  omega

lemma Cell.terminates_iff_orbit_has_fixed_point (h : Array (Array Float)) (c : Cell) :
    c.terminates h ↔ ∃ p, p ∈ c.orbit h ∧ ∀ q ∈ c.orbit h, q = p := by
  simp [Cell.terminates, Cell.fixedPoint]
  omega

lemma Cell.terminates_iff_orbit_has_cycle (h : Array (Array Float)) (c : Cell) :
    c.terminates h ↔ ∃ p q, p ∈ c.orbit h ∧ q ∈ c.orbit h ∧ p ≠ q ∧ p.row = q.row ∧ p.col = q.col := by
  simp [Cell.terminates_iff_orbit_has_fixed_point]
  omega

def Cell.wellFounded (h : Array (Array Float)) : WellFoundedRelation Cell :=
  { rel := fun c c' ↦ c.row < c'.row ∨ c.row = c'.row ∧ c.col < c'.col
    r := fun c c' ↦ c.row < c'.row ∨ c.row = c'.row ∧ c.col < c'.col
    isWellFounded := by
      intro c
      omega }

lemma Cell.succ_decreases (h : Array (Array Float)) (c : Cell) (hc : c.succ h |>.isSome) :
    WellFoundedRelation.decreases (Cell.wellFounded h) c (c.succ h |>.get!) := by
  cases' c.succ h with c'
  simp [hc]
  omega

lemma Cell.terminates_of_strict_descent (h : Array (Array Float)) (c : Cell) (hc : ∀ c', c.succ h |>.get! = c' → c.row < c'.row ∨ c.row = c'.row ∧ c.col < c'.col) :
    c.terminates h := by
  apply Cell.terminates_iff_orbit_finite.mpr
  apply Nat.lt_wf.mpr
  intro n
  omega

lemma Cell.terminates_of_finite_cell_set (h : Array (Array Float)) (c : Cell) (hc : h.size < ∞ ∧ h[0].size < ∞) :
    c.terminates h := by
  apply Cell.terminates_of_strict_descent
  intro c' hc'
  omega
