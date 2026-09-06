// ===========================================================================
//  GeoProofBench · P-002
//  文件 : formal/dafny/P002_pit_filling.dfy
//  算子 : Wang & Liu (2006) 填洼在 1D 上的特化(左端为出口的一遍扫描)
//  覆盖 : GPB-021 单调性 / GPB-022 一遍扫描达到非降剖面 / GPB-023 不动点
//  环境 : Dafny 4.11 · 验证命令 dafny verify P002_pit_filling.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么 P-002 是 P-001 的对偶
//  ----------------------------
//  P-001 证明"什么是一致"(Horn 算子在平面上精确恢复梯度)。
//  P-002 证明"什么是收敛"(1D 填洼在有限步内达到非降剖面,且再填不变)。
//  前者是**代数性质**,后者是**离散算法性质**,两者共同构成
//  GeoProofBench 想覆盖的"可验证空间计算"的前两条腿:
//
//      可证的代数性质 (P-001) ← 一致性 → 形式化 Horn
//      可证的算法性质 (P-002) ← 收敛性 → 形式化 W&L 的 1D 特化
//
//  本文件只证**数学性质**,**不证数值精度**。浮点实现下的
//  "和真值差多少"留到 P-005 / Phase 2 的 RDD 数据集上做。
//  曲率(Evans / Zevenbergen–Thorne)是 P-003,不要和本文件混淆。
//
//  设计动机
//  --------
//  Wang & Liu 2006 是水文预处理的事实标准:
//      1. 边界像元(已知出口)入优先级队列
//      2. 弹出当前最低已处理像元
//      3. 每个未处理邻居被抬到 max(自身高程, 当前像元填后高程)
//      4. 直到队列空
//
//  在 1D、左端为唯一出口时,堆序处理退化为从左到右一遍扫描:
//      Fill[0] = orig[0]                         (出口不抬)
//      Fill[i] = max(orig[i], Fill[i-1])         (i = 1, 2, …)
//  这就是本文件的 Fill。2D / 8 邻域 + 堆不变量见 P-002-bis。
//
//  本轮修订的关键教训
//  ------------------
//  初稿引理 RaisePreservesOrImproves 陈述为
//      NonDecreasing(a) || NonDecreasing(Raise(a, i))
//  这是**假的**。反例 a = [3, 1, 0], i = 1:
//      Raise → [3, 3, 0],两侧都不是非降。
//  SMT 超时不是工具链问题,是命题不可证。本文件改为对完整扫描 Fill
//  陈述三条真命题:单调、扫描后非降、非降剖面是不动点(因而幂等)。
// ===========================================================================

module PitFilling {

  type Array = seq<int>

  // ------------------------------------------------------------------
  // 单点抬升:只处理 i ≥ 1。下标 0 是出口,永不抬升。
  // ------------------------------------------------------------------
  function Raise(a: Array, i: int): Array
    requires 1 <= i < |a|
    ensures |Raise(a, i)| == |a|
  {
    if a[i] >= a[i - 1] then a
    else a[i := a[i - 1]]
  }

  // 从下标 k 起向右扫描。k == |a| 时已扫完。
  function FillFrom(a: Array, k: nat): Array
    requires 1 <= k
    ensures |FillFrom(a, k)| == |a|
    decreases if k <= |a| then |a| - k else 0
  {
    if k >= |a| then a
    else FillFrom(Raise(a, k), k + 1)
  }

  function Fill(a: Array): Array
    ensures |Fill(a)| == |a|
  {
    if |a| <= 1 then a else FillFrom(a, 1)
  }

  predicate NonDecreasing(a: Array)
  {
    forall i :: 1 <= i < |a| ==> a[i] >= a[i - 1]
  }

  // 前缀 [0, k) 已经非降。k == 1 时为空前缀,恒真。
  predicate PrefixNonDec(a: Array, k: nat)
  {
    forall i :: 1 <= i < k && i < |a| ==> a[i] >= a[i - 1]
  }

  // ==================================================================
  // 局部事实:Raise 只改下标 i,且抬后 a[i] ≥ a[i-1]、不降原值
  // ==================================================================
  lemma RaiseLocal(a: Array, i: int)
    requires 1 <= i < |a|
    ensures |Raise(a, i)| == |a|
    ensures Raise(a, i)[i] >= a[i]
    ensures Raise(a, i)[i] >= a[i - 1]
    ensures Raise(a, i)[i] >= Raise(a, i)[i - 1]
    ensures Raise(a, i)[i - 1] == a[i - 1]
    ensures forall j :: 0 <= j < |a| && j != i ==> Raise(a, i)[j] == a[j]
  {
  }

  // ==================================================================
  // GPB-021 · 单调性(任何一次抬升都不降低任一像元)
  // 这是"填洼"这个动词的核心含义。
  // ==================================================================
  lemma Monotone(a: Array, i: int)
    requires 1 <= i < |a|
    ensures forall j :: 0 <= j < |a| ==> Raise(a, i)[j] >= a[j]
  {
    RaiseLocal(a, i);
    forall j | 0 <= j < |a|
      ensures Raise(a, i)[j] >= a[j]
    {
      if j == i {
        assert Raise(a, i)[i] >= a[i];
      } else {
        assert Raise(a, i)[j] == a[j];
      }
    }
  }

  // ==================================================================
  // GPB-023 · 透水点不动:若 a[i] 已不低于左邻,Raise 是恒等
  // ==================================================================
  lemma SpillFixpoint(a: Array, i: int)
    requires 1 <= i < |a|
    requires a[i] >= a[i - 1]
    ensures Raise(a, i) == a
  {
  }

  lemma RaisePreservesPrefix(a: Array, i: int)
    requires 1 <= i < |a|
    requires PrefixNonDec(a, i)
    ensures PrefixNonDec(Raise(a, i), i + 1)
  {
    RaiseLocal(a, i);
    forall j | 1 <= j < i + 1 && j < |Raise(a, i)|
      ensures Raise(a, i)[j] >= Raise(a, i)[j - 1]
    {
      if j < i {
        assert 1 <= j < i && j < |a|;
        assert a[j] >= a[j - 1];
        assert Raise(a, i)[j] == a[j];
        assert Raise(a, i)[j - 1] == a[j - 1];
      } else {
        assert j == i;
        assert Raise(a, i)[i] >= Raise(a, i)[i - 1];
      }
    }
  }

  lemma FillFromMonotone(a: Array, k: nat)
    requires 1 <= k
    ensures |FillFrom(a, k)| == |a|
    ensures forall j :: 0 <= j < |a| ==> FillFrom(a, k)[j] >= a[j]
    decreases if k <= |a| then |a| - k else 0
  {
    if k >= |a| {
    } else {
      Monotone(a, k);
      FillFromMonotone(Raise(a, k), k + 1);
      forall j | 0 <= j < |a|
        ensures FillFrom(a, k)[j] >= a[j]
      {
        assert FillFrom(a, k) == FillFrom(Raise(a, k), k + 1);
        assert FillFrom(Raise(a, k), k + 1)[j] >= Raise(a, k)[j];
        assert Raise(a, k)[j] >= a[j];
      }
    }
  }

  // ==================================================================
  // GPB-022 · 从已非降前缀继续扫描,最终整条剖面非降
  // 这是 1D 上"算法终止且结果无坑"的可证形式。
  // ==================================================================
  lemma FillFromCorrect(a: Array, k: nat)
    requires 1 <= k
    requires PrefixNonDec(a, k)
    ensures NonDecreasing(FillFrom(a, k))
    decreases if k <= |a| then |a| - k else 0
  {
    if k >= |a| {
      forall i | 1 <= i < |a|
        ensures a[i] >= a[i - 1]
      {
        assert 1 <= i < k && i < |a|;
      }
    } else {
      RaisePreservesPrefix(a, k);
      FillFromCorrect(Raise(a, k), k + 1);
    }
  }

  lemma FillCorrect(a: Array)
    ensures NonDecreasing(Fill(a))
    ensures forall j :: 0 <= j < |a| ==> Fill(a)[j] >= a[j]
  {
    if |a| <= 1 {
    } else {
      assert PrefixNonDec(a, 1);
      FillFromCorrect(a, 1);
      FillFromMonotone(a, 1);
    }
  }

  lemma FillFromIdentity(a: Array, k: nat)
    requires 1 <= k
    requires NonDecreasing(a)
    ensures FillFrom(a, k) == a
    decreases if k <= |a| then |a| - k else 0
  {
    if k >= |a| {
    } else {
      assert a[k] >= a[k - 1];
      SpillFixpoint(a, k);
      FillFromIdentity(a, k + 1);
    }
  }

  lemma FillFixpoint(a: Array)
    requires NonDecreasing(a)
    ensures Fill(a) == a
  {
    if |a| <= 1 {
    } else {
      FillFromIdentity(a, 1);
    }
  }

  lemma FillIdempotent(a: Array)
    ensures Fill(Fill(a)) == Fill(a)
  {
    FillCorrect(a);
    FillFixpoint(Fill(a));
  }

  // 具体洼地:出口 3,坑 1,右岸 4 → 填成 3,3,4
  lemma ExamplePitFilled()
    ensures Fill([3, 1, 4]) == [3, 3, 4]
  {
    var a := [3, 1, 4];
    assert Raise(a, 1) == [3, 3, 4];
    assert Raise([3, 3, 4], 2) == [3, 3, 4];
    calc {
      Fill(a);
      == FillFrom(a, 1);
      == FillFrom(Raise(a, 1), 2);
      == FillFrom([3, 3, 4], 2);
      == FillFrom(Raise([3, 3, 4], 2), 3);
      == FillFrom([3, 3, 4], 3);
      == [3, 3, 4];
    }
  }

  method Main() {
    print "GeoProofBench P-002 — Wang & Liu 填洼 1D 特化:单调 / 扫描后非降 / 幂等\n";
    print "P-002 是 P-001 的对偶:一阶算子的代数一致性 vs 填洼的算法收敛性\n";
    print "全部由编译期验证: dafny verify P002_pit_filling.dfy\n";
  }
}
