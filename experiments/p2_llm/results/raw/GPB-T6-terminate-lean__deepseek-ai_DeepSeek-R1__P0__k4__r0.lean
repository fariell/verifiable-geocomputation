import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic

variable {S : Type*} [Fintype S]
variable {α : Type*} [LinearOrder α]
variable (h : S → α)
variable (succ : S → Option S)
variable (h_succ : ∀ c d, succ c = some d → h d < h c)

def r (a b : S) : Prop := succ b = some a

def step_measure (c : S) : ℕ :=
  (Finset.univ.filter (fun d => h d < h c)).card

theorem measure_decreases {c : S} {d : S} (hstep : r succ d c) :
    step_measure h d < step_measure h c := by
  unfold r at hstep
  unfold step_measure
  have h_lt : h d < h c := h_succ c d hstep
  let set_below_d := Finset.filter (fun x => h x < h d) Finset.univ
  let set_below_c := Finset.filter (fun x => h x < h c) Finset.univ
  have h_sub : set_below_d ⊆ set_below_c := by
    intro x hx
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hx ⊢
    exact lt_trans hx h_lt
  have h_mem : d ∈ set_below_c := by
    simp [h_lt]
  have h_not_mem : d ∉ set_below_d := by
    simp [lt_irrefl (h d)]
  have : set_below_d ⊂ set_below_c :=
    Finset.ssubset_iff_subset_ne.2 ⟨h_sub, fun h_eq => h_not_mem (h_eq ▸ h_mem)⟩
  exact Finset.card_lt_card this

theorem wf_r : WellFounded (r succ) :=
  InvImage.wf (step_measure h) (Nat.lt_wfRel.wf) (fun _ _ hstep => measure_decreases h succ h_succ hstep)
