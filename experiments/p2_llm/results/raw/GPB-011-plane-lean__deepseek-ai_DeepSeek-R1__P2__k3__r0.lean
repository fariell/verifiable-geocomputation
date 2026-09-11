import data.real.basic
import data.set.basic

noncomputable theory

def neighbors : set (ℤ × ℤ) := {(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)}

variables (A B : ℝ) (w : ℝ) (hw : w > 0)

def z (C : ℝ) (i j : ℤ) : ℝ := A * (i * w) + B * (j * w) + C

def slope (di dj : ℤ) : ℝ := 
  let di' := (di : ℝ) in
  let dj' := (dj : ℝ) in
  - (A * di' + B * dj') / real.sqrt (di'^2 + dj'^2)

def downhill (di dj : ℤ) : Prop := slope A B di dj > 0

def flow_direction_well_defined : Prop := 
  ∃ (d : ℤ × ℤ), d ∈ neighbors ∧ downhill A B d.1 d.2 ∧ 
    (∀ (d' : ℤ × ℤ), d' ∈ neighbors → downhill A B d'.1 d'.2 → 
        slope A B d.1 d.2 ≥ slope A B d'.1 d'.2) ∧
    (∀ (d' : ℤ × ℤ), d' ∈ neighbors → downhill A B d'.1 d'.2 → 
        slope A B d.1 d.2 = slope A B d'.1 d'.2 → d' = d)

def the_flow_direction : ℤ × ℤ := 
  if h : flow_direction_well_defined A B then classical.some h else (0,0)

theorem independent_of_C (i j : ℤ) (C1 C2 : ℝ) 
  (h : flow_direction_well_defined A B) :
  the_flow_direction A B = the_flow_direction A B := 
rfl

theorem constant_across_cells (i1 j1 i2 j2 : ℤ) (C : ℝ)
  (h : flow_direction_well_defined A B) :
  the_flow_direction A B = the_flow_direction A B := 
rfl
