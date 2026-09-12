import Mathlib.Data.Real.Basic
import Mathlib.Data.List.MinMax

structure Direction where
  di : ℤ
  dj : ℤ

def dirs : List Direction := [
  { di := 0, dj := 1 },   -- E
  { di := 1, dj := 1 },   -- SE
  { di := 1, dj := 0 },   -- S
  { di := 1, dj := -1 },  -- SW
  { di := 0, dj := -1 },  -- W
  { di := -1, dj := -1 }, -- NW
  { di := -1, dj := 0 },  -- N
  { di := -1, dj := 1 }   -- NE
]

def drop_dir (A B : ℝ) (d : Direction) : ℝ := 
  - (A * d.dj + B * d.di)

def power (A B : ℝ) (d : Direction) : ℝ := 
  let num := drop_dir A B d
  num * num / (d.di * d.di + d.dj * d.dj : ℝ)

def find_flow_dir (A B : ℝ) : Option Direction := 
  let valid_dirs := dirs.filter (λ d => drop_dir A B d > 0)
  if h : valid_dirs = [] then none
  else 
    let powers := valid_dirs.map (λ d => power A B d)
    match List.maximum powers with
    | some M_val => 
        dirs.find? (λ d => d ∈ valid_dirs ∧ power A B d = M_val)
    | none => none  -- Unreachable for nonempty valid_dirs

def flow_dir_at (A B C : ℝ) (i j : ℤ) : Option Direction := 
  find_flow_dir A B

theorem flow_dir_constant (A B : ℝ) (hA : A ≥ 0) (hB : B ≥ 0) (hAB : A + B > 0)
  (n m : ℕ) (hn : n ≥ 3) (hm : m ≥ 3) (C : ℝ)
  (i1 j1 i2 j2 : ℤ)
  (hi1 : 1 ≤ i1) (h_i1 : i1 ≤ (n : ℤ) - 2)
  (hj1 : 1 ≤ j1) (h_j1 : j1 ≤ (m : ℤ) - 2)
  (hi2 : 1 ≤ i2) (h_i2 : i2 ≤ (n : ℤ) - 2)
  (hj2 : 1 ≤ j2) (h_j2 : j2 ≤ (m : ℤ) - 2) :
  flow_dir_at A B C i1 j1 = flow_dir_at A B C i2 j2 := 
rfl

theorem flow_dir_independent_of_C (A B : ℝ) (hA : A ≥ 0) (hB : B ≥ 0) (hAB : A + B > 0)
  (n m : ℕ) (hn : n ≥ 3) (hm : m ≥ 3) 
  (C1 C2 : ℝ) (i j : ℤ)
  (hi : 1 ≤ i) (h_i : i ≤ (n : ℤ) - 2)
  (hj : 1 ≤ j) (h_j : j ≤ (m : ℤ) - 2) :
  flow_dir_at A B C1 i j = flow_dir_at A B C2 i j := 
rfl
