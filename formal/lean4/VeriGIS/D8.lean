/-
  ==========================================================================
   GeoProofBench · P-005
   文件 : formal/lean4/VeriGIS/D8.lean
   算子 : D8 最陡下降(对角 dist² = 2,并列取扫描序更早者)
   对偶 : formal/dafny/P005_d8.dfy
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06

    GPB-010  八邻都不低于中心 ⇒ noFlow
    GPB-011  平面只差常数 ⇒ 流向相同;A=1 B=0 ⇒ 西;A=B=1 ⇒ 西北

  Lean 与 Dafny 都用 8 路分数比较(无递归扫描,避免 SMT 超时)。
  drop>0 时 proxy = drop² / dist2,dist2 ∈ {1,2}。
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.D8

noncomputable section

inductive Dir
  | E | SE | S | SW | W | NW | N | NE
  deriving DecidableEq, Repr

inductive Flow
  | noFlow
  | to (d : Dir)
  deriving DecidableEq, Repr

structure Win where
  a : ℝ
  b : ℝ
  c : ℝ
  d : ℝ
  e : ℝ
  f : ℝ
  g : ℝ
  h : ℝ
  i : ℝ

def nbr : Dir → Win → ℝ
  | .E, w => w.f
  | .SE, w => w.i
  | .S, w => w.h
  | .SW, w => w.g
  | .W, w => w.d
  | .NW, w => w.a
  | .N, w => w.b
  | .NE, w => w.c

def score (e z dist2 : ℝ) : ℝ :=
  if e - z ≤ 0 then 0 else (e - z) ^ 2 / dist2

def uphill (w : Win) : Prop :=
  w.a ≥ w.e ∧ w.b ≥ w.e ∧ w.c ≥ w.e ∧
    w.d ≥ w.e ∧ w.f ≥ w.e ∧
    w.g ≥ w.e ∧ w.h ≥ w.e ∧ w.i ≥ w.e

def d8 (w : Win) : Flow :=
  let pE := score w.e w.f 1
  let pSE := score w.e w.i 2
  let pS := score w.e w.h 1
  let pSW := score w.e w.g 2
  let pW := score w.e w.d 1
  let pNW := score w.e w.a 2
  let pN := score w.e w.b 1
  let pNE := score w.e w.c 2
  if 0 < pE ∧ pSE ≤ pE ∧ pS ≤ pE ∧ pSW ≤ pE ∧ pW ≤ pE ∧ pNW ≤ pE ∧ pN ≤ pE ∧ pNE ≤ pE then
    .to .E
  else if 0 < pSE ∧ pE < pSE ∧ pS ≤ pSE ∧ pSW ≤ pSE ∧ pW ≤ pSE ∧ pNW ≤ pSE ∧ pN ≤ pSE ∧ pNE ≤ pSE then
    .to .SE
  else if 0 < pS ∧ pE < pS ∧ pSE < pS ∧ pSW ≤ pS ∧ pW ≤ pS ∧ pNW ≤ pS ∧ pN ≤ pS ∧ pNE ≤ pS then
    .to .S
  else if 0 < pSW ∧ pE < pSW ∧ pSE < pSW ∧ pS < pSW ∧ pW ≤ pSW ∧ pNW ≤ pSW ∧ pN ≤ pSW ∧ pNE ≤ pSW then
    .to .SW
  else if 0 < pW ∧ pE < pW ∧ pSE < pW ∧ pS < pW ∧ pSW < pW ∧ pNW ≤ pW ∧ pN ≤ pW ∧ pNE ≤ pW then
    .to .W
  else if 0 < pNW ∧ pE < pNW ∧ pSE < pNW ∧ pS < pNW ∧ pSW < pNW ∧ pW < pNW ∧ pN ≤ pNW ∧ pNE ≤ pNW then
    .to .NW
  else if 0 < pN ∧ pE < pN ∧ pSE < pN ∧ pS < pN ∧ pSW < pN ∧ pW < pN ∧ pNW < pN ∧ pNE ≤ pN then
    .to .N
  else if 0 < pNE ∧ pE < pNE ∧ pSE < pNE ∧ pS < pNE ∧ pSW < pNE ∧ pW < pNE ∧ pNW < pNE ∧ pN < pNE then
    .to .NE
  else
    .noFlow

theorem score_nonpos_of_ge {e z dist2 : ℝ} (h : z ≥ e) : score e z dist2 = 0 := by
  simp [score, sub_nonpos.mpr h]

-- ==========================================================================
-- GPB-010
-- ==========================================================================

theorem pit_no_flow (w : Win) (h : uphill w) : d8 w = .noFlow := by
  rcases h with ⟨ha, hb, hc, hd, hf, hg, hh, hi⟩
  simp [d8, score_nonpos_of_ge ha, score_nonpos_of_ge hb, score_nonpos_of_ge hc,
    score_nonpos_of_ge hd, score_nonpos_of_ge hf, score_nonpos_of_ge hg,
    score_nonpos_of_ge hh, score_nonpos_of_ge hi]

theorem example_pit :
    d8 ⟨1, 1, 1, 1, 0, 1, 1, 1, 1⟩ = .noFlow := by
  apply pit_no_flow
  simp [uphill]

-- ==========================================================================
-- GPB-011 · 平面
-- ==========================================================================

def planeWin (A B C w : ℝ) : Win :=
  ⟨A * (-w) + B * (-w) + C,
    B * (-w) + C,
    A * w + B * (-w) + C,
    A * (-w) + C,
    C,
    A * w + C,
    A * (-w) + B * w + C,
    B * w + C,
    A * w + B * w + C⟩

theorem score_add_const (e z K dist2 : ℝ) :
    score (e + K) (z + K) dist2 = score e z dist2 := by
  unfold score
  have : e + K - (z + K) = e - z := by ring
  simp [this]

def shift (win : Win) (K : ℝ) : Win :=
  ⟨win.a + K, win.b + K, win.c + K, win.d + K, win.e + K,
    win.f + K, win.g + K, win.h + K, win.i + K⟩

theorem d8_shift (win : Win) (K : ℝ) : d8 (shift win K) = d8 win := by
  simp [d8, shift, score_add_const]

theorem planeWin_shift (A B C w : ℝ) :
    planeWin A B C w = shift (planeWin A B 0 w) C := by
  simp [planeWin, shift]

theorem plane_constant (A B C w : ℝ) :
    d8 (planeWin A B C w) = d8 (planeWin A B 0 w) := by
  rw [planeWin_shift, d8_shift]

theorem example_plane_west :
    d8 (planeWin 1 0 0 1) = .to .W := by
  simp [d8, planeWin, score]
  norm_num

theorem example_plane_northwest :
    d8 (planeWin 1 1 0 1) = .to .NW := by
  simp [d8, planeWin, score]
  norm_num

end

end VeriGIS.D8
