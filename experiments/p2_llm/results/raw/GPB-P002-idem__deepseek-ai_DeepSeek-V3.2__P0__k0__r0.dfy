// P0 · Zero-shot auto-formalization: Pit filling idempotence and fixed points
// Target: dafny
// Natural-language specification:
//   (i)  Pit filling is idempotent on the 1D left-outlet specialization: Fill(Fill(a)) = Fill(a).
//   (ii) Cells that already do not spill to the left are fixed points of Raise.

module PCOMP5 {
  // 1D left-outlet fill: cumulative maximum from left to right.
  function Fill1D(a: seq<int>): seq<int>
    ensures |Fill1D(a)| == |a|
    ensures forall i :: 0 <= i < |a| ==> Fill1D(a)[i] == cumulativeMax(a, i)
  {
    if |a| == 0 then []
    else Fill1DHelper(a, 0, [])
  }

  // Helper: compute cumulative maximum recursively.
  function Fill1DHelper(a: seq<int>, idx: int, prefix: seq<int>): seq<int>
    requires 0 <= idx <= |a|
    requires |prefix| == idx
    requires forall j :: 0 <= j < idx ==> prefix[j] == cumulativeMax(a, j)
    ensures |Fill1DHelper(a, idx, prefix)| == |a|
    ensures forall i :: 0 <= i < |a| ==> Fill1DHelper(a, idx, prefix)[i] == cumulativeMax(a, i)
    decreases |a| - idx
  {
    if idx == |a| then prefix
    else
      var newMax := if idx == 0 then a[0] else max(prefix[idx-1], a[idx]);
      Fill1DHelper(a, idx+1, prefix + [newMax])
  }

  // Cumulative maximum up to index i (inclusive).
  function cumulativeMax(a: seq<int>, i: int): int
    requires 0 <= i < |a|
  {
    if i == 0 then a[0]
    else max(cumulativeMax(a, i-1), a[i])
  }

  // Lemma: Fill1D is idempotent.
  lemma FillIdempotent(a: seq<int>)
    ensures Fill1D(Fill1D(a)) == Fill1D(a)
  {
    // Key property: cumulativeMax of a non-decreasing sequence is the sequence itself.
    var fa := Fill1D(a);
    // Show fa is non-decreasing.
    forall i | 1 <= i < |fa|
      ensures fa[i-1] <= fa[i]
    {
      assert cumulativeMax(a, i-1) <= cumulativeMax(a, i);
    }
    // Now show cumulativeMax(fa, i) == fa[i].
    forall i | 0 <= i < |fa|
      ensures cumulativeMax(fa, i) == fa[i]
    {
      if i == 0 {
        assert cumulativeMax(fa, 0) == fa[0];
      } else {
        // Since fa is non-decreasing, the max up to i is just fa[i].
        assert cumulativeMax(fa, i) == max(cumulativeMax(fa, i-1), fa[i]);
        assert cumulativeMax(fa, i-1) <= fa[i];
        assert cumulativeMax(fa, i) == fa[i];
      }
    }
    // By definition of Fill1D, Fill1D(fa) uses cumulativeMax(fa, i) which equals fa[i].
    // Therefore Fill1D(fa) == fa.
    assert Fill1D(fa) == fa;
  }

  // Raise operation: raise a cell to the maximum of itself and its left neighbor.
  function Raise(a: seq<int>, i: int): int
    requires 0 <= i < |a|
  {
    if i == 0 then a[0]
    else max(a[i], a[i-1])
  }

  // Lemma: cells that do not spill to the left are fixed points of Raise.
  lemma NoSpillLeftFixedPoint(a: seq<int>, i: int)
    requires 0 <= i < |a|
    requires i == 0 || a[i] >= a[i-1]   // does not spill left
    ensures Raise(a, i) == a[i]
  {
    // By definition of Raise and the precondition.
    if i == 0 {
      assert Raise(a, i) == a[i];
    } else {
      assert a[i] >= a[i-1];
      assert Raise(a, i) == max(a[i], a[i-1]) == a[i];
    }
  }
}
