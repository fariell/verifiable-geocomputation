import Mathlib.Tactic

namespace VeriGIS.PitFill

-- ℝ 上的除法没有可执行代码,本文件全是规范层证明,不是数值实现。
noncomputable section

/-!
  ## 1D Fill 算子定义

  给定序列 a, Fill(a) 是通过以下过程构造的:
  1. 初始化 fill[0] = a[0]
  2. 对于每个 i > 0, fill[i] = max(a[i], fill[i-1])
  这个过程确保 fill 是非递减的,且 fill[i] ≥ a[i] 对所有 i 成立。
-/

-- 1D Fill 算子定义
def fillSeq (a : ℕ → ℝ) : ℕ → ℝ
| 0 => a 0
| n + 1 => max (a (n + 1)) (fillSeq a n)

/-!
  ## 非递减性质证明

  我们需要证明:对于所有 i, Fill(a)[i] ≤ Fill(a)[i+1] 当定义时。
  这等价于证明 fillSeq a 是一个非递减序列。
-/

-- 辅助引理:fillSeq 在 n=0 时成立
lemma fillSeq_nondecreasing_zero (a : ℕ → ℝ) : fillSeq a 0 ≤ fillSeq a 1 := by
  simp [fillSeq]
  apply le_max_left

-- 辅助引理:fillSeq 在 n+1 时成立
lemma fillSeq_nondecreasing_succ (a : ℕ → ℝ) (n : ℕ) :
    fillSeq a n ≤ fillSeq a (n + 1) := by
  simp [fillSeq]
  apply le_max_left

-- 主定理:fillSeq 是非递减的
theorem fillSeq_nondecreasing (a : ℕ → ℝ) (i : ℕ) : fillSeq a i ≤ fillSeq a (i + 1) := by
  induction i <;> simp [fillSeq, *]
  apply le_max_left

-- 冒烟测试(非命题,仅确认算子可计算)
example : fillSeq (fun _ => 0) 0 = 0 := by norm_num [fillSeq]
example : fillSeq (fun _ => 0) 1 = 0 := by norm_num [fillSeq]
example : fillSeq (fun _ => 0) 2 = 0 := by norm_num [fillSeq]

example : fillSeq (fun _ => 1) 0 = 1 := by norm_num [fillSeq]
example : fillSeq (fun _ => 1) 1 = 1 := by norm_num [fillSeq]
example : fillSeq (fun _ => 1) 2 = 1 := by norm_num [fillSeq]

example : fillSeq (fun i => i) 0 = 0 := by norm_num [fillSeq]
example : fillSeq (fun i => i) 1 = 1 := by norm_num [fillSeq]
example : fillSeq (fun i => i) 2 = 2 := by norm_num [fillSeq]

example : fillSeq (fun i => if i = 0 then 0 else 1) 0 = 0 := by norm_num [fillSeq]
example : fillSeq (fun i => if i = 0 then 0 else 1) 1 = 1 := by norm_num [fillSeq]
example : fillSeq (fun i => if i = 0 then 0 else 1) 2 = 1 := by norm_num [fillSeq]

end VeriGIS.PitFill
