// ===========================================================================
//  GeoProofBench · P-002-bis
//  文件 : formal/dafny/P002_pit_filling_2d.dfy
//  算子 : Wang & Liu (2006) 2D 邻域抬升(4 连通)
//  覆盖 : GPB-024 单调抬升 / GPB-025 已处理像元冻结 / GPB-026 单行 ≡ 1D Fill
//  环境 : Dafny 4.11 · dafny verify P002_pit_filling_2d.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  不证:完整堆实现的 O(n log n) 终止(Dijkstra 弹出即终态)。那需要优先
//  队列 + 全局最小路径,SMT 会超时,也容易写成假命题(见 P-002 初稿教训)。
//
//  本文件证 W&L 的**局部堆不变量**:
//    从已处理像元 p 抬升邻居 n:
//      fill[n] := max(fill[n], max(orig[n], fill[p]))
//    — 不降低任何像元(GPB-024)
//    — 不改 p,也不改其它格(GPB-025)。这就是"弹出后不再回写"
//    — 单行、从左出口依次抬升 ≡ P-002 的 Fill(GPB-026)
//
//  3×3 中心洼地 [1,1,1 / 1,0,1 / 1,1,1] 从北邻抬一次,中心变为 1。
// ===========================================================================

include "P002_pit_filling.dfy"

module PitFilling2D {
  import PitFilling   // include 只并入编译单元;跨模块名仍要 import

  type Grid = seq<seq<int>>

  predicate Rect(g: Grid)
  {
    |g| > 0 && |g[0]| > 0 && (forall i :: 0 <= i < |g| ==> |g[i]| == |g[0]|)
  }

  predicate InGrid(g: Grid, r: int, c: int)
    requires Rect(g)
  {
    0 <= r < |g| && 0 <= c < |g[0]|
  }

  predicate SameShape(g: Grid, f: Grid)
    requires Rect(g) && Rect(f)
  {
    |g| == |f| && |g[0]| == |f[0]|
  }

  function Max(x: int, y: int): int
  {
    if x >= y then x else y
  }

  function At(g: Grid, r: int, c: int): int
    requires Rect(g) && InGrid(g, r, c)
  {
    g[r][c]
  }

  function SetAt(g: Grid, r: int, c: int, v: int): Grid
    requires Rect(g) && InGrid(g, r, c)
    ensures Rect(SetAt(g, r, c, v))
    ensures |SetAt(g, r, c, v)| == |g|
    ensures |SetAt(g, r, c, v)[0]| == |g[0]|
    ensures At(SetAt(g, r, c, v), r, c) == v
    ensures forall i, j :: InGrid(g, i, j) && (i != r || j != c) ==>
              At(SetAt(g, r, c, v), i, j) == At(g, i, j)
  {
    g[r := g[r][c := v]]
  }

  // 4 邻(非自身)
  predicate Adjacent4(r: int, c: int, nr: int, nc: int)
  {
    (nr == r && (nc == c - 1 || nc == c + 1))
    || (nc == c && (nr == r - 1 || nr == r + 1))
  }

  // W&L 一步:已处理 p=(pr,pc) 把邻居 n 抬到 max(orig[n], fill[p])
  function RaiseNbr(orig: Grid, fill: Grid, pr: int, pc: int, nr: int, nc: int): Grid
    requires Rect(orig) && Rect(fill) && SameShape(orig, fill)
    requires InGrid(orig, pr, pc) && InGrid(orig, nr, nc)
    requires Adjacent4(pr, pc, nr, nc)
    ensures Rect(RaiseNbr(orig, fill, pr, pc, nr, nc))
    ensures SameShape(orig, RaiseNbr(orig, fill, pr, pc, nr, nc))
  {
    var nv := Max(At(orig, nr, nc), At(fill, pr, pc));
    if nv > At(fill, nr, nc) then SetAt(fill, nr, nc, nv) else fill
  }

  // ==================================================================
  // GPB-024 · 抬升不降低任一像元,且 n 不低于 orig[n]
  // ==================================================================
  lemma RaiseNbrMonotone(orig: Grid, fill: Grid, pr: int, pc: int, nr: int, nc: int)
    requires Rect(orig) && Rect(fill) && SameShape(orig, fill)
    requires InGrid(orig, pr, pc) && InGrid(orig, nr, nc)
    requires Adjacent4(pr, pc, nr, nc)
    ensures forall r, c :: InGrid(orig, r, c) ==>
              At(RaiseNbr(orig, fill, pr, pc, nr, nc), r, c) >= At(fill, r, c)
    ensures At(RaiseNbr(orig, fill, pr, pc, nr, nc), nr, nc)
            >= At(orig, nr, nc)
  {
    var f2 := RaiseNbr(orig, fill, pr, pc, nr, nc);
    var nv := Max(At(orig, nr, nc), At(fill, pr, pc));
    forall r, c | InGrid(orig, r, c)
      ensures At(f2, r, c) >= At(fill, r, c)
    {
      if r == nr && c == nc {
        if nv > At(fill, nr, nc) {
          assert At(f2, nr, nc) == nv;
        } else {
          assert f2 == fill;
        }
      } else {
        if nv > At(fill, nr, nc) {
          assert f2 == SetAt(fill, nr, nc, nv);
          assert At(f2, r, c) == At(fill, r, c);
        } else {
          assert f2 == fill;
        }
      }
    }
    if nv > At(fill, nr, nc) {
      assert At(f2, nr, nc) == nv;
      assert nv >= At(orig, nr, nc);
    } else {
      assert f2 == fill;
      assert At(fill, nr, nc) >= nv;
      assert nv >= At(orig, nr, nc);
    }
  }

  // ==================================================================
  // GPB-025 · 已处理像元冻结:抬邻居不改 p,也不改第三格
  // ==================================================================
  lemma RaiseNbrProcessedFrozen(orig: Grid, fill: Grid, pr: int, pc: int, nr: int, nc: int)
    requires Rect(orig) && Rect(fill) && SameShape(orig, fill)
    requires InGrid(orig, pr, pc) && InGrid(orig, nr, nc)
    requires Adjacent4(pr, pc, nr, nc)
    ensures At(RaiseNbr(orig, fill, pr, pc, nr, nc), pr, pc) == At(fill, pr, pc)
    ensures forall r, c :: InGrid(orig, r, c) && (r != nr || c != nc) ==>
              At(RaiseNbr(orig, fill, pr, pc, nr, nc), r, c) == At(fill, r, c)
  {
    var nv := Max(At(orig, nr, nc), At(fill, pr, pc));
    if nv > At(fill, nr, nc) {
      assert RaiseNbr(orig, fill, pr, pc, nr, nc) == SetAt(fill, nr, nc, nv);
      assert !(pr == nr && pc == nc);
    }
  }

  // ==================================================================
  // GPB-026 · 单行从左出口依次抬升 ≡ P-002 Fill
  // ==================================================================
  // 与 P-002 FillFrom 同形: k≥1。k==0 再调 k=1 在空序列上度量不降。
  function FillStripFrom(orig: seq<int>, fill: seq<int>, k: nat): seq<int>
    requires |orig| == |fill|
    requires 1 <= k
    ensures |FillStripFrom(orig, fill, k)| == |orig|
    decreases if k <= |orig| then |orig| - k else 0
  {
    if k >= |orig| then fill
    else
      var nv := Max(orig[k], fill[k - 1]);
      var fill' := if nv > fill[k] then fill[k := nv] else fill;
      FillStripFrom(orig, fill', k + 1)
  }

  function FillStrip(a: seq<int>): seq<int>
    ensures |FillStrip(a)| == |a|
  {
    if |a| <= 1 then a else FillStripFrom(a, a, 1)
  }

  lemma RaiseMatchesStrip(a: seq<int>, i: int)
    requires 1 <= i < |a|
    ensures PitFilling.Raise(a, i) == (if Max(a[i], a[i - 1]) > a[i]
                                       then a[i := Max(a[i], a[i - 1])]
                                       else a)
  {
    var nv := Max(a[i], a[i - 1]);
    if a[i] >= a[i - 1] {
      assert nv == a[i];
      assert PitFilling.Raise(a, i) == a;
    } else {
      assert nv == a[i - 1];
      assert PitFilling.Raise(a, i) == a[i := a[i - 1]];
    }
  }

  predicate StripInv(orig: seq<int>, fill: seq<int>, k: nat)
  {
    |orig| == |fill|
    && (forall j :: k <= j < |orig| ==> fill[j] == orig[j])
  }

  lemma FillStripFromEqStep(orig: seq<int>, fill: seq<int>, k: nat)
    requires 1 <= k
    requires |orig| == |fill|
    requires StripInv(orig, fill, k)
    ensures FillStripFrom(orig, fill, k) == PitFilling.FillFrom(fill, k)
    decreases if k <= |orig| then |orig| - k else 0
  {
    if k >= |orig| {
    } else {
      assert fill[k] == orig[k];
      var nv := Max(orig[k], fill[k - 1]);
      var fill' := if nv > fill[k] then fill[k := nv] else fill;
      RaiseMatchesStrip(fill, k);
      assert fill[k] == orig[k];
      assert Max(fill[k], fill[k - 1]) == nv;
      assert fill' == PitFilling.Raise(fill, k);
      assert forall j :: k + 1 <= j < |orig| ==> fill'[j] == fill[j];
      assert forall j :: k + 1 <= j < |orig| ==> fill[j] == orig[j];
      assert StripInv(orig, fill', k + 1);
      FillStripFromEqStep(orig, fill', k + 1);
    }
  }

  lemma FillStripEq1D(a: seq<int>)
    ensures FillStrip(a) == PitFilling.Fill(a)
  {
    if |a| <= 1 {
    } else {
      assert StripInv(a, a, 1);
      FillStripFromEqStep(a, a, 1);
    }
  }

  // 3×3 中心洼地:从北邻 (0,1) 抬 (1,1)
  lemma ExampleCenterPit()
  {
    var orig := [[1, 1, 1], [1, 0, 1], [1, 1, 1]];
    var fill := orig;
    assert Rect(orig) && Rect(fill);
    assert Adjacent4(0, 1, 1, 1);
    assert At(orig, 1, 1) == 0;
    assert At(fill, 0, 1) == 1;
    var f2 := RaiseNbr(orig, fill, 0, 1, 1, 1);
    assert Max(At(orig, 1, 1), At(fill, 0, 1)) == 1;
    assert At(f2, 1, 1) == 1;
    assert At(f2, 0, 1) == 1;
    RaiseNbrProcessedFrozen(orig, fill, 0, 1, 1, 1);
    RaiseNbrMonotone(orig, fill, 0, 1, 1, 1);
  }
}
