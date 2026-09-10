// Formalization of 1D left-outlet pit-filling idempotence and fixed-point property
// for cells that do not spill left.

// A 1D elevation array is represented as a sequence of integers.
// The left-outlet condition means water can only flow to the left neighbor (index i-1).

// The Fill operation is defined as the cumulative maximum from left to right.
function Fill(a: seq<int>): seq<int>
  requires |a| > 0
  ensures |Fill(a)| == |a|
{
  if |a| == 1 then [a[0]]
  else Fill(a[0..|a|-1]) + [max(a[|a|-1], Fill(a[0..|a|-1])[|a|-2])]
}

// Alternative iterative definition for clarity in proofs.
function FillIterative(a: seq<int>): seq<int>
  requires |a| > 0
  ensures FillIterative(a) == Fill(a)
{
  var result := [a[0]];
  var i := 1;
  while i < |a|
    invariant i >= 1
    invariant |result| == i
    invariant forall k :: 0 <= k < i ==> result[k] == Fill(a[0..i])[k]
  {
    result := result + [max(a[i], result[i-1])];
    i := i + 1;
  }
  result
}

// Lemma: Fill is idempotent.
lemma FillIdempotent(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
{
  // Expand definition of Fill(Fill(a)).
  // Let b = Fill(a). Then b[i] = max(a[i], b[i-1]) for i>0, and b[0]=a[0].
  // Now compute Fill(b). By definition, Fill(b)[0] = b[0] = a[0].
  // For i>0, Fill(b)[i] = max(b[i], Fill(b)[i-1]).
  // We show by induction that Fill(b)[i] = b[i] for all i.
  if |a| == 1 {
    // Trivial: single element.
    assert Fill(Fill(a)) == Fill(a);
  } else {
    var b := Fill(a);
    // Prove Fill(b) == b by induction on index i.
    var i := 0;
    while i < |a|
      invariant 0 <= i <= |a|
      invariant forall k :: 0 <= k < i ==> Fill(b)[k] == b[k]
    {
      if i == 0 {
        assert Fill(b)[0] == b[0];
      } else {
        // Fill(b)[i] = max(b[i], Fill(b)[i-1])
        // By invariant, Fill(b)[i-1] == b[i-1].
        // So Fill(b)[i] = max(b[i], b[i-1]).
        // But b[i] = max(a[i], b[i-1]) >= b[i-1].
        // Therefore max(b[i], b[i-1]) = b[i].
        assert Fill(b)[i] == max(b[i], Fill(b)[i-1]);
        assert Fill(b)[i-1] == b[i-1];
        assert b[i] >= b[i-1];
        assert max(b[i], b[i-1]) == b[i];
        assert Fill(b)[i] == b[i];
      }
      i := i + 1;
    }
    assert Fill(b) == b;
  }
}

// A cell does not spill left if its elevation is not lower than its left neighbor.
predicate DoesNotSpillLeft(a: seq<int>, i: int)
  requires 0 <= i < |a|
{
  i == 0 || a[i] >= a[i-1]
}

// Lemma: Cells that do not spill left are fixed points of Raise.
// In 1D left-outlet, Raise is the same as Fill for a single cell?
// Actually, Raise is the operation that increases a cell's elevation to the
// minimum level that prevents it from being a pit, i.e., to the level of its
// lowest spill neighbor. In 1D left-outlet, the only possible spill neighbor
// is the left cell. So Raise sets a[i] to max(a[i], a[i-1]) for i>0, and leaves
// a[0] unchanged. This is exactly the per-cell update in Fill.
// Therefore, if a cell already does not spill left, Raise leaves it unchanged.

function RaiseCell(a: seq<int>, i: int): int
  requires 0 <= i < |a|
{
  if i == 0 then a[i] else max(a[i], a[i-1])
}

lemma RaiseFixedPoint(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires DoesNotSpillLeft(a, i)
  ensures RaiseCell(a, i) == a[i]
{
  // By definition of DoesNotSpillLeft: i==0 or a[i] >= a[i-1].
  // If i==0, RaiseCell(a,0) = a[0].
  // If i>0, RaiseCell(a,i) = max(a[i], a[i-1]) = a[i] because a[i] >= a[i-1].
}

// The full Raise operation on the whole array is Fill.
// So the lemma above implies that for each cell i that does not spill left,
// Fill(a)[i] == a[i]. This is consistent with the definition of Fill.

lemma FillPreservesNonSpillingCells(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires DoesNotSpillLeft(a, i)
  ensures Fill(a)[i] == a[i]
{
  // Fill(a)[i] = max(a[i], Fill(a)[i-1]) for i>0, and Fill(a)[0]=a[0].
  // For i==0, trivial.
  // For i>0, we know a[i] >= a[i-1].
  // By induction, we can show Fill(a)[i-1] >= a[i-1], but not necessarily <=.
  // Actually, Fill is monotonic: Fill(a)[i-1] >= a[i-1].
  // So a[i] >= a[i-1] <= Fill(a)[i-1]. But we need a[i] >= Fill(a)[i-1] to conclude.
  // That may not hold: e.g., a = [10, 5], i=1. a[1]=5, a[0]=10, so a[1] < a[0].
  // But DoesNotSpillLeft(a,1) is false because a[1] < a[0]. So the precondition fails.
  // When DoesNotSpillLeft(a,i) holds, a[i] >= a[i-1].
  // Also, Fill(a)[i-1] >= a[i-1] by monotonicity.
  // But we cannot deduce a[i] >= Fill(a)[i-1] because Fill(a)[i-1] could be larger.
  // Example: a = [0, 1, 0], i=2. a[2]=0, a[1]=1, so a[2] < a[1] -> DoesNotSpillLeft false.
  // So the precondition ensures a[i] >= a[i-1]. However, Fill(a)[i-1] might be > a[i-1].
  // Example: a = [0, 2, 1], i=2. a[2]=1, a[1]=2 -> DoesNotSpillLeft false because 1<2.
  // Actually, if a[i] >= a[i-1], then Fill(a)[i-1] could be larger than a[i-1] only if
  // some earlier cell is higher. But then a[i] might still be less than that higher value.
  // Example: a = [5, 3, 4], i=2. a[2]=4, a[1]=3 -> DoesNotSpillLeft true.
  // Fill(a) = [5,5,5]. Fill(a)[2]=5 != a[2]=4. So the lemma as stated is false.
  // Wait, the natural language says: "Cells that already do not spill to the left are fixed points of Raise."
  // In the example, cell 2 does not spill left because 4 >= 3. But after Raise (i.e., Fill),
  // it becomes 5. So it is not a fixed point. Therefore, the natural language statement
  // is false in general for the global Raise (Fill). It might be true for a local Raise
  // that only considers the immediate left neighbor, not the cumulative maximum.
  // The reference implementation's RaiseNbr uses the immediate neighbor, not the filled value.
  // So we need to clarify: RaiseCell (local) vs Fill (global).
  // The lemma RaiseFixedPoint above is correct for the local RaiseCell.
  // The natural language might refer to the local Raise.
  // We'll keep both lemmas, but note that FillPreservesNonSpillingCells is not provable.
}

// Therefore, we only prove the idempotence of Fill and the fixed-point property
// for the local RaiseCell operation.

// Main theorem: idempotence of Fill.
theorem FillIsIdempotent(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
{
  FillIdempotent(a);
}

// Main theorem: local Raise fixed point for non-spilling cells.
theorem RaiseCellFixedPoint(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires DoesNotSpillLeft(a, i)
  ensures RaiseCell(a, i) == a[i]
{
  RaiseFixedPoint(a, i);
}
