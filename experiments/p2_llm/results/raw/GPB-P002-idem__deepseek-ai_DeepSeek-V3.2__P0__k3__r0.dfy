// Formalization of 1D left-outlet pit filling idempotence and fixed-point property
// Target: Dafny

// A 1D digital elevation model is represented as a sequence of integers.
// The left-outlet condition means water can only flow to the left neighbor.
// The fill operation raises each cell to at least the height of its left neighbor.

// Fill operation: for i from 1 to n-1, set a[i] = max(a[i], a[i-1])
function Fill(a: seq<int>): seq<int>
  requires |a| > 0
  ensures |Fill(a)| == |a|
{
  if |a| == 0 then a else
    var result := a;
    var i := 1;
    while i < |a|
      invariant 1 <= i <= |a|
      invariant forall j :: 0 <= j < i ==> result[j] == (if j == 0 then a[0] else max(a[j], result[j-1]))
      invariant forall j :: i <= j < |a| ==> result[j] == a[j]
      decreases |a| - i
    {
      result := result[i := max(result[i], result[i-1])];
      i := i + 1;
    }
    result
}

// Lemma: Fill is idempotent: Fill(Fill(a)) == Fill(a)
lemma FillIdempotent(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
{
  var fa := Fill(a);
  var ffa := Fill(fa);
  // Show ffa == fa by element-wise equality
  assert |ffa| == |fa| == |a|;
  forall i | 0 <= i < |a|
    ensures ffa[i] == fa[i]
  {
    // Proof by induction on i
    if i == 0 {
      assert fa[0] == a[0];
      assert ffa[0] == fa[0];
    } else {
      // From definition of Fill: fa[i] = max(a[i], fa[i-1])
      // and ffa[i] = max(fa[i], ffa[i-1])
      // By induction, ffa[i-1] == fa[i-1]
      calc {
        ffa[i];
        == // definition of Fill on fa
        max(fa[i], ffa[i-1]);
        == // induction hypothesis
        max(fa[i], fa[i-1]);
        == // since fa[i] >= fa[i-1] by construction of Fill
        fa[i];
      }
    }
  }
  // Extensional equality
  assert ffa == fa;
}

// A cell does not spill to the left if its height is already >= left neighbor.
predicate NoSpillLeft(a: seq<int>, i: int)
  requires 0 <= i < |a|
  requires |a| > 0
{
  i == 0 || a[i] >= a[i-1]
}

// Lemma: Cells that do not spill to the left are fixed points of Raise.
// Here "Raise" is the same as Fill (since Fill raises cells when needed).
lemma NoSpillIsFixedPoint(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires NoSpillLeft(a, i)
  ensures Fill(a)[i] == a[i]
{
  var fa := Fill(a);
  if i == 0 {
    assert fa[0] == a[0];
  } else {
    // Since a[i] >= a[i-1], max(a[i], fa[i-1]) = a[i] if fa[i-1] <= a[i].
    // But fa[i-1] >= a[i-1] by Fill definition, and a[i] >= a[i-1],
    // so a[i] >= fa[i-1]? Not necessarily: fa[i-1] could be larger than a[i-1].
    // Need stronger invariant: Fill is monotonic and preserves order.
    // Actually, Fill is the prefix maximum, so fa[i-1] = max_{j<=i-1} a[j].
    // Since a[i] >= a[i-1], we have a[i] >= max_{j<=i-1} a[j] = fa[i-1].
    // Therefore max(a[i], fa[i-1]) = a[i].
    // Let's prove fa[i-1] <= a[i].
    assert forall k :: 0 <= k <= i-1 ==> a[k] <= a[i] by {
      if k == i-1 {
        assert a[k] <= a[i] by NoSpillLeft(a, i);
      } else {
        // For k < i-1, by induction? Actually need transitivity.
        // Since a[i] >= a[i-1] and a[i-1] >= a[i-2] ... not given.
        // Wait, NoSpillLeft only says a[i] >= a[i-1], not about earlier cells.
        // So we cannot conclude a[i] >= a[k] for k < i-1.
        // But fa[i-1] is the max of a[0..i-1], so fa[i-1] >= a[i-1].
        // Since a[i] >= a[i-1], we only know a[i] >= a[i-1], not necessarily >= fa[i-1].
        // Counterexample: a = [10, 5, 6]. i=2: a[2]=6 >= a[1]=5, but fa[1]=10, so fa[2]=max(6,10)=10 != 6.
        // So the original statement is false! Let's verify.
        // The natural language says: "Cells that already do not spill to the left are fixed points of Raise."
        // But in 1D left-outlet, "does not spill to the left" means a[i] >= a[i-1].
        // In the counterexample, cell 2 (value 6) does not spill left (6>=5), but after fill it becomes 10.
        // So the statement is incorrect as written.
        // However, maybe they meant "does not spill to the left *in the original DEM*"?
        // Even so, the counterexample shows it's false.
        // Therefore we cannot prove this lemma; it's actually false.
        // We must output a counterexample instead.
        // But the requirement says "Prove the stated property". Since it's false, we should not prove it.
        // Instead, we should provide a counterexample and prove the negation.
        // However, the instruction says: if the property is negative, construct an explicit witness.
        // Let's do that.
    }
    // Since we discovered the statement is false, we stop this proof and instead provide a counterexample.
  }
}

// Counterexample to "NoSpillLeft => fixed point"
lemma Counterexample()
  ensures exists a: seq<int>, i: int :: |a| > 0 && 0 <= i < |a| && NoSpillLeft(a, i) && Fill(a)[i] != a[i]
{
  var a := [10, 5, 6];
  var i := 2;
  assert |a| == 3 > 0;
  assert 0 <= i < |a|;
  assert NoSpillLeft(a, i) because a[2] == 6 >= 5 == a[1];
  var fa := Fill(a);
  // Compute Fill: [10, max(5,10)=10, max(6,10)=10] = [10,10,10]
  assert fa[0] == 10;
  assert fa[1] == 10;
  assert fa[2] == 10;
  assert fa[2] != a[2]; // 10 != 6
}
