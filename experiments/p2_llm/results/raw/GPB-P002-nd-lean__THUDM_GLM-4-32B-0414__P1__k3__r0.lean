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

  本文件证明 Fill(a) 是一个非递减序列:对于所有 i, Fill(a)[i] <= Fill(a)[i+1] 当两者都定义时。
-/

-- 定义 1D 序列类型
def Seq (n : ℕ) := Fin n → ℝ

-- 定义左出口填充算子
def Fill (a : Seq (n + 1)) : Seq (n + 1) :=
  fun i ↦ if i = 0 then a 0 else max (a i) (Fill a (i.pred))

-- 证明 Fill(a) 是非递减的
theorem fill_non_decreasing (a : Seq (n + 1)) (i : Fin (n + 1)) :
    Fill a i ≤ Fill a i.succ := by
  cases i <;> simp [Fill, max_le, le_max_left, le_max_right]
  all_goals aesop

-- 冒烟测试(非命题,仅确认算子可计算)
example (a : Seq 2) : Fill a 0 ≤ Fill a 1 := by simp [fill_non_decreasing]
example (a : Seq 3) : Fill a 1 ≤ Fill a 2 := by simp [fill_non_decreasing]

end -- noncomputable section

end VeriGIS.PitFill
