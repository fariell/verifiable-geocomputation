/-
  ==========================================================================
   GeoProofBench · P-002
   文件 : formal/lean4/VeriGIS/PitFilling.lean
   算子 : Wang & Liu (2006) 填洼在 1D 上的闭式(从左端出口的前缀最大值)
   对偶 : formal/dafny/P002_pit_filling.dfy  (Dafny 4.11, AutoDL 24 verified / 0 errors)
   环境 : Lean 4.18.0 + mathlib
   日期 : 2026-09-06
  ==========================================================================

  独立重述,不是翻译。Dafny 用下标扫描 `FillFrom ∘ Raise` 贴近 2D 堆算法;
  Lean 用链表上的**前缀最大值**——1D、左端为唯一出口时二者恒等:

      fill[0] = orig[0]
      fill[i] = max(orig[i], fill[i-1]) = max(orig[0], …, orig[i])

  这是双形式化想量的差异:同一条水文事实,SMT 走下标不变量,Lean 走结构归纳。

  覆盖 GPB-021 单调性 / GPB-022 结果非降 / GPB-023 不动点与幂等。
  曲率是 P-003。2D 堆不变量是 P-002-bis。

  初稿 Dafny 引理 `NonDecreasing(a) ∨ NonDecreasing(Raise a i)` 为假
  (反例 [3,1,0]、i=1)。两边都只证完整 `fill`,不证单点抬升能修整条剖面。
  ==========================================================================
-/

import Mathlib.Tactic

namespace VeriGIS.PitFilling

-- ℤ 与 List 都可计算;不必 noncomputable。这与 HornSlope 的 ℝ 除法相反。

/-- 非降剖面。空表与单点平凡成立。 -/
def NonDecreasing : List ℤ → Prop
  | [] => True
  | [_] => True
  | x :: y :: xs => x ≤ y ∧ NonDecreasing (y :: xs)

/-- 从左端出口起的前缀最大值。1D W&L 的闭式。 -/
def fill : List ℤ → List ℤ
  | [] => []
  | x :: xs => x :: fill.go x xs
where
  go (acc : ℤ) : List ℤ → List ℤ
    | [] => []
    | y :: ys =>
      let acc' := max acc y
      acc' :: go acc' ys

/-- 单点抬升:把下标 `i≥1` 抬到不低于左邻。越界时恒等(Lean 全函数 vs Dafny requires)。 -/
def raise (a : List ℤ) (i : ℕ) : List ℤ :=
  if h : 1 ≤ i ∧ i < a.length then
    if a[i] ≥ a[i - 1] then a else a.set i (a[i - 1]'(by omega))
  else
    a

-- ==========================================================================
-- 长度
-- ==========================================================================

theorem fill_go_length (acc : ℤ) (xs : List ℤ) : (fill.go acc xs).length = xs.length := by
  induction xs generalizing acc with
  | nil => rfl
  | cons _ ys ih => simp [fill.go, ih]

@[simp] theorem fill_length (a : List ℤ) : (fill a).length = a.length := by
  cases a with
  | nil => rfl
  | cons _ xs => simp [fill, fill_go_length]

@[simp] theorem raise_length (a : List ℤ) (i : ℕ) : (raise a i).length = a.length := by
  unfold raise
  split_ifs <;> simp

-- ==========================================================================
-- GPB-021 · 单调性:fill / raise 都不降低任一像元
-- ==========================================================================

theorem fill_go_ge (acc : ℤ) (xs : List ℤ) (i : ℕ) (hi : i < xs.length) :
    xs[i] ≤ (fill.go acc xs)[i]'(by simp [fill_go_length]; exact hi) := by
  induction xs generalizing acc i with
  | nil => cases hi
  | cons y ys ih =>
    cases i with
    | zero =>
      simp [fill.go, le_max_right]
    | succ i =>
      simp [fill.go] at hi
      simpa [fill.go] using ih (max acc y) i hi

/-- 填后高程不低于原高程。 -/
theorem fill_ge (a : List ℤ) (i : ℕ) (hi : i < a.length) :
    a[i] ≤ (fill a)[i]'(by simp; exact hi) := by
  cases a with
  | nil => cases hi
  | cons x xs =>
    cases i with
    | zero => simp [fill]
    | succ i =>
      simp [fill] at hi
      simpa [fill] using fill_go_ge x xs i hi

theorem raise_ge (a : List ℤ) (i j : ℕ) (hj : j < a.length) :
    a[j] ≤ (raise a i)[j]'(by simp [raise_length]; exact hj) := by
  unfold raise
  split_ifs with h hge
  · rfl
  · simp [List.getElem_set]
    split_ifs with hij
    · have hij' : i = j := hij
      have : a[i] < a[i - 1] := lt_of_not_ge hge
      simpa [hij'] using this.le
    · rfl
  · rfl

-- ==========================================================================
-- GPB-022 · fill 的结果非降
-- ==========================================================================

theorem fill_go_nondec (acc : ℤ) (xs : List ℤ) : NonDecreasing (fill.go acc xs) := by
  induction xs generalizing acc with
  | nil => simp [fill.go, NonDecreasing]
  | cons y ys ih =>
    cases ys with
    | nil => simp [fill.go, NonDecreasing]
    | cons z zs =>
      constructor
      · simp [fill.go, le_max_left]
      · exact ih (max acc y)

theorem fill_nondec (a : List ℤ) : NonDecreasing (fill a) := by
  match a with
  | [] => trivial
  | [x] => simp [fill, fill.go, NonDecreasing]
  | x :: y :: xs =>
    constructor
    · simp [fill, fill.go, le_max_left]
    · simpa [fill] using fill_go_nondec x (y :: xs)

-- ==========================================================================
-- GPB-023 · 非降剖面是不动点,因而幂等
-- ==========================================================================

theorem fill_go_id (acc : ℤ) (xs : List ℤ) (h : NonDecreasing (acc :: xs)) :
    fill.go acc xs = xs := by
  induction xs generalizing acc with
  | nil => rfl
  | cons y ys ih =>
    have hnd : acc ≤ y ∧ NonDecreasing (y :: ys) := by
      simpa [NonDecreasing] using h
    simp [fill.go, max_eq_right hnd.1]
    exact ih y hnd.2

theorem fill_id (a : List ℤ) (h : NonDecreasing a) : fill a = a := by
  match a with
  | [] => rfl
  | [_] => rfl
  | x :: y :: xs =>
    have hxy : x ≤ y := h.1
    simp [fill, fill.go, max_eq_right hxy]
    exact fill_go_id y xs h.2

theorem fill_idem (a : List ℤ) : fill (fill a) = fill a :=
  fill_id (fill a) (fill_nondec a)

/-- 透水点不动:已不低于左邻则 raise 恒等。 -/
theorem raise_spill (a : List ℤ) (i : ℕ) (hi : 1 ≤ i ∧ i < a.length)
    (h : a[i - 1] ≤ a[i]) : raise a i = a := by
  unfold raise
  rw [dif_pos hi, if_pos h]

-- ==========================================================================
-- 具体洼地(与 Dafny ExamplePitFilled 同一例子)
-- ==========================================================================

example : fill [3, 1, 4] = [3, 3, 4] := by native_decide

example : fill [3, 1, 0] = [3, 3, 3] := by native_decide

end VeriGIS.PitFilling
