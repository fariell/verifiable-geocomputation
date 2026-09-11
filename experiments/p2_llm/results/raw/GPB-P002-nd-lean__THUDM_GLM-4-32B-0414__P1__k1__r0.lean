import Mathlib.Tactic

namespace VeriGIS.PitFill

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 1D 左出口填充算子

  给定序列 a,填充算子 Fill(a) 产生一个非递减序列,满足:
  1. Fill(a)[0] = a[0]
  2. 对于所有 i, Fill(a)[i+1] = max(a[i+1], Fill(a)[i])
  3. 当 Fill(a)[i] 未定义时,不等式不适用

  本文件证明 Fill(a) 是一个非递减算子。
-/

-- 1D 序列类型
def Seq (n : ℕ) := Fin n → ℝ

-- 左出口填充算子
def Fill (a : Seq (n + 1)) : Seq (n + 1) :=
  fun i ↦
    if i = 0 then a 0
    else max (a i) (Fill a (i.pred))

-- 基础情况:第一个元素
@[simp]
theorem Fill_zero (a : Seq (n + 1)) : Fill a 0 = a 0 := by simp [Fill]

-- 递归情况:后续元素
@[simp]
theorem Fill_succ (a : Seq (n + 1)) (i : Fin n) :
    Fill a (i.succ) = max (a i.succ) (Fill a i) := by simp [Fill]

-- 主定理:填充序列是非递减的
theorem Fill_nondecreasing (a : Seq (n + 1)) (i : Fin n) :
    Fill a i ≤ Fill a (i.succ) := by
  cases i <;> simp [Fill_succ, max_le (le_refl _) (le_refl _)]

-- 冒烟测试(非命题,仅确认算子可计算)
example (a : Seq 2) : Fill a 0 ≤ Fill a 1 := by simp [Fill_nondecreasing]
example (a : Seq 3) : Fill a 1 ≤ Fill a 2 := by simp [Fill_nondecreasing]

end -- noncomputable section

end VeriGIS.PitFill
