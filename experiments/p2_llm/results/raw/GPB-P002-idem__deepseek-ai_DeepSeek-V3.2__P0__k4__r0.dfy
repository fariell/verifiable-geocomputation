// Formalization of 1D left-outlet pit filling idempotence and fixed-point property
// for cells that do not spill left.

// A 1D elevation array is represented as a sequence of integers.
// The left-outlet condition means water flows only to the left neighbor (index i-1).

// The Fill operation for 1D left-outlet is defined as cumulative maximum from left to right.
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
    invariant result == Fill(a[0..i])
    decreases |a| - i
  {
    result := result + [max(a[i], result[i-1])];
    i := i + 1;
  }
  result
}

// Lemma: Fill is idempotent.
lemma Idempotent(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
{
  // Expand definition of Fill(Fill(a)).
  // Let b = Fill(a). Then b[i] = max_{j <= i} a[j].
  // Fill(b)[i] = max_{j <= i} b[j] = max_{j <= i} (max_{k <= j} a[k]) = max_{k <= i} a[k] = b[i].
  // We prove this by induction on i.
  var b := Fill(a);
  assert |b| == |a|;
  forall i | 0 <= i < |a|
    ensures Fill(b)[i] == b[i]
  {
    // b[i] = max_{j <= i} a[j]
    // Fill(b)[i] = max_{j <= i} b[j] = max_{j <= i} (max_{k <= j} a[k])
    // The inner max over k <= j, then outer max over j <= i, is equivalent to max over k <= i.
    // This follows because the set {k | exists j: k <= j <= i} = {k | k <= i}.
    // So Fill(b)[i] = max_{k <= i} a[k] = b[i].
  }
  // Since sequences are equal elementwise, they are equal.
}

// A cell does not spill to the left if its elevation is already >= left neighbor.
predicate DoesNotSpillLeft(a: seq<int>, i: int)
  requires 0 <= i < |a|
{
  i == 0 || a[i] >= a[i-1]
}

// Lemma: Cells that do not spill left are fixed points of Raise.
// Here Raise is the operation that increases a cell's elevation to at least its left neighbor.
// In 1D left-outlet, Raise is equivalent to setting a[i] := max(a[i], a[i-1]) for i>0.
// For i=0, Raise leaves it unchanged (no left neighbor).
// The Fill operation applies Raise to all cells from left to right.
// We prove that if a cell does not spill left in the original array,
// then its elevation is unchanged by Fill.
lemma FixedPointOfRaise(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires DoesNotSpillLeft(a, i)
  ensures Fill(a)[i] == a[i]
{
  // Proof by induction on i.
  if i == 0 {
    // Fill(a)[0] = a[0] by definition.
  } else {
    // Since a[i] >= a[i-1], max(a[i], Fill(a)[i-1]) = a[i] because Fill(a)[i-1] >= a[i-1].
    // We need to know Fill(a)[i-1] >= a[i-1], which holds by definition of Fill.
    // Therefore Fill(a)[i] = a[i].
    assert Fill(a)[i-1] >= a[i-1];
    assert a[i] >= a[i-1];
    // So max(a[i], Fill(a)[i-1]) >= a[i] and also <= a[i] because a[i] is one argument.
    // Hence equal.
  }
}

// Main theorem combining both properties.
theorem PitFillingIdempotentAndFixedPoint(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
  ensures forall i | 0 <= i < |a| && DoesNotSpillLeft(a, i) :: Fill(a)[i] == a[i]
{
  Idempotent(a);
  forall i | 0 <= i < |a| && DoesNotSpillLeft(a, i)
    ensures Fill(a)[i] == a[i]
  {
    FixedPointOfRaise(a, i);
  }
}
