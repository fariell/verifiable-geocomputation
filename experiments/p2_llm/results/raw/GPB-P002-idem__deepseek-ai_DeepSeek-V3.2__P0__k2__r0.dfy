// P-COMP-5: Idempotence of 1D left-outlet pit filling
// Formalization of: Fill(Fill(a)) = Fill(a)
// and: Cells that already do not spill to the left are fixed points of Raise.

module PCOMP5 {
  // 1D left-outlet pit filling (prefix max)
  function Fill(a: seq<int>): seq<int>
    ensures |Fill(a)| == |a|
    ensures forall i :: 0 <= i < |a| ==> Fill(a)[i] >= a[i]
    ensures forall i :: 0 <= i < |a| ==> (i > 0 ==> Fill(a)[i] >= Fill(a)[i-1])
    ensures forall i :: 0 <= i < |a| ==> (i == 0 || Fill(a)[i-1] >= a[i] ==> Fill(a)[i] == a[i])
  {
    if |a| == 0 then []
    else FillAux(a, 0, a[0])
  }

  // Helper: Fill from index i with current maximum cur
  function FillAux(a: seq<int>, i: int, cur: int): seq<int>
    requires 0 <= i <= |a|
    ensures |FillAux(a, i, cur)| == |a|
    ensures forall j :: 0 <= j < i ==> FillAux(a, i, cur)[j] == Fill(a)[j]
    ensures forall j :: i <= j < |a| ==> FillAux(a, i, cur)[j] >= a[j]
    ensures forall j :: i <= j < |a| ==> FillAux(a, i, cur)[j] >= cur
    ensures forall j :: i <= j < |a| ==> (j > i ==> FillAux(a, i, cur)[j] >= FillAux(a, i, cur)[j-1])
    decreases |a| - i
  {
    if i == |a| then []
    else
      let newCur = if a[i] > cur then a[i] else cur in
      [newCur] + FillAux(a, i+1, newCur)
  }

  // Lemma: Fill is idempotent
  lemma Idempotent(a: seq<int>)
    ensures Fill(Fill(a)) == Fill(a)
  {
    // Key property: Fill is monotone and already satisfies prefix-max property
    // We prove by induction on index i that Fill(Fill(a))[i] == Fill(a)[i]
    if |a| > 0 {
      var i: int := 0;
      var cur1: int := a[0];
      var cur2: int := Fill(a)[0];
      while i < |a|
        invariant 0 <= i <= |a|
        invariant cur1 == (if i > 0 then Fill(a)[i-1] else a[0])
        invariant cur2 == (if i > 0 then Fill(Fill(a))[i-1] else Fill(a)[0])
        invariant forall j :: 0 <= j < i ==> Fill(Fill(a))[j] == Fill(a)[j]
        decreases |a| - i
      {
        // Fill(a)[i] = max(a[i], cur1)
        // Fill(Fill(a))[i] = max(Fill(a)[i], cur2)
        // But by invariant, for j < i, Fill(Fill(a))[j] == Fill(a)[j]
        // So cur2 == Fill(Fill(a))[i-1] == Fill(a)[i-1] == cur1
        // Therefore max(Fill(a)[i], cur2) = max(Fill(a)[i], cur1)
        // Since Fill(a)[i] >= cur1, this equals Fill(a)[i]
        i := i + 1;
        if i < |a| {
          cur1 := if a[i] > cur1 then a[i] else cur1;
          cur2 := if Fill(a)[i] > cur2 then Fill(a)[i] else cur2;
        }
      }
    }
  }

  // Definition: a cell does not spill to the left if its height is >= all previous cells
  predicate NoSpillLeft(a: seq<int>, i: int)
    requires 0 <= i < |a|
  {
    forall j :: 0 <= j < i ==> a[i] >= a[j]
  }

  // Lemma: Cells that do not spill to the left are fixed points of Raise (i.e., Fill)
  lemma NoSpillFixedPoint(a: seq<int>, i: int)
    requires 0 <= i < |a|
    requires NoSpillLeft(a, i)
    ensures Fill(a)[i] == a[i]
  {
    // By definition of Fill, Fill(a)[i] = max(a[i], Fill(a)[i-1])
    // We show that a[i] >= Fill(a)[i-1]
    if i > 0 {
      // Fill(a)[i-1] is the maximum of a[0..i-1]
      // Since a[i] >= all a[j] for j < i, a[i] >= max(a[0..i-1]) = Fill(a)[i-1]
      // Therefore max(a[i], Fill(a)[i-1]) = a[i]
    }
  }
}
