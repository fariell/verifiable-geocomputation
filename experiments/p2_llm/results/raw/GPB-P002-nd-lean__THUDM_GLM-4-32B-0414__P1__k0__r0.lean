import Mathlib.Tactic

namespace VeriGIS.PitFill

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 1D 左出口填充算子

  给定序列 a,填充算子 Fill(a) 产生一个非递减序列,满足:
  1. Fill(a)[0] = a[0]
  2. 对于所有 i, Fill(a)[i+1] = max(a[i+1], Fill(a)[i])
  3. Fill(a) 是 a 的最小非递减上界序列

  本文件证明 Fill(a) 的单调性:对于所有 i, Fill(a)[i] <= Fill(a)[i+1] 当定义时。
-/

-- 1D 序列类型
def Seq (n : ℕ) := Fin n → ℝ

-- 左出口填充算子
def Fill (a : Seq (n + 1)) : Seq (n + 1) :=
  fun i ↦ if i = 0 then a 0 else max (a i) (Fill a (i.pred))

-- 基础情况:第一个元素不变
@[simp]
theorem fill_zero (a : Seq (n + 1)) : Fill a 0 = a 0 := by simp [Fill]

-- 递归情况:后续元素是当前元素和前一个填充值的最大值
@[simp]
theorem fill_succ (a : Seq (n + 1)) (i : Fin n) :
    Fill a i.succ = max (a i.succ) (Fill a i) := by simp [Fill]

-- 填充序列的单调性
theorem fill_nondecreasing (a : Seq (n + 1)) (i : Fin n) :
    Fill a i ≤ Fill a i.succ := by
  cases i <;> simp [fill_zero, fill_succ, max_le]

-- 填充序列是原始序列的上界
theorem fill_upper_bound (a : Seq (n + 1)) (i : Fin (n + 1)) :
    a i ≤ Fill a i := by
  induction i <;> simp [*, fill_zero, fill_succ, max_le_left, le_refl]

-- 填充序列是最小的非递减上界序列
theorem fill_minimal (a : Seq (n + 1)) (b : Seq (n + 1)) (h₁ : ∀ i, a i ≤ b i) (h₂ : ∀ i j, i ≤ j → b i ≤ b j) (i : Fin (n + 1)) :
    Fill a i ≤ b i := by
  induction i <;> simp [*, fill_zero, fill_succ, h₁, h₂, max_le, le_trans]
  aesop

end VeriGIS.PitFill
