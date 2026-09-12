To address the problem of proving the idempotence of pit filling in a 1D left-outlet specialization and the fixed-point property of cells that do not spill left, we formalize the solution in Dafny. The approach involves defining a function `Fill` that computes the cumulative maximum of the elevation sequence, ensuring the result is non-decreasing. Key lemmas establish that applying `Fill` twice yields the same result as applying it once, and cells that are local maxima in their prefix remain unchanged.

```dafny
function MaxSeq(s: seq<int>): int
  requires |s| > 0
  decreases |s|
{
  if |s| == 1 then
    s[0]
  else
    var m := MaxSeq(s[1..]);
    if s[0] > m then s[0] else m
}

lemma MaxSeqMonotonic(s: seq<int>, t: seq<int>)
  requires |s| > 0 && |t| > 0
  requires s == t[0..|s|]
  ensures MaxSeq(s) <= MaxSeq(t)
  decreases |t|
{
  if |s| == |t| {
    // s equals t
  } else {
    MaxSeqMonotonic(s, t[0..|t|-1]);
    var m_t := MaxSeq(t);
    var m_t_prefix := MaxSeq(t[0..|t|-1]);
    assert m_t == max(m_t_prefix, t[|t|-1]);
    assert MaxSeq(s) <= m_t_prefix <= m_t;
  }
}

function Fill(a: seq<int>): seq<int>
  ensures |Fill(a)| == |a|
  ensures forall i | 0 <= i < |a| :: Fill(a)[i] == MaxSeq(a[0..i+1])
{
  if |a| == 0 then []
  else
    var m := a[0];
    var b := [m];
    var idx := 1;
    while idx < |a|
      invariant 1 <= idx <= |a|
      invariant |b| == idx
      invariant b[0] == a[0]
      invariant m == MaxSeq(a[0..idx])
      invariant forall j | 0 <= j < idx :: b[j] == MaxSeq(a[0..j+1])
    {
      if a[idx] > m {
        m := a[idx];
      }
      b := b + [m];
      idx := idx + 1;
    }
    b
}

lemma FillIsNonDecreasing(a: seq<int>)
  ensures forall i | 1 <= i < |a| :: Fill(a)[i] >= Fill(a)[i-1]
{
  for i := 1 to |a|-1
    invariant forall j | 1 <= j < i :: Fill(a)[j] >= Fill(a)[j-1]
  {
    MaxSeqMonotonic(a[0..i], a[0..i+1]);
  }
}

lemma FillOfNonDecreasingIsSelf(b: seq<int>)
  requires |b| > 0
  requires forall i | 1 <= i < |b| :: b[i] >= b[i-1]
  ensures Fill(b) == b
{
  for i := 0 to |b|-1
    invariant forall j | 0 <= j < i :: Fill(b)[j] == b[j]
  {
    assert Fill(b)[i] == MaxSeq(b[0..i+1]);
    if i > 0 {
      assert b[i] >= b[i-1];
    }
    var j := 0;
    while j <= i
      invariant forall k | 0 <= k < j :: b[k] <= b[i]
      invariant j <= i+1
    {
      if j < i {
        assert b[j] <= b[i];
      } else if j == i {
        // b[i] <= b[i]
      }
      j := j + 1;
    }
    assert MaxSeq(b[0..i+1]) == b[i];
  }
}

lemma Idempotence(a: seq<int>)
  ensures Fill(Fill(a)) == Fill(a)
{
  if |a| == 0 {
    // Handles empty sequence case
  } else {
    FillIsNonDecreasing(a);
    FillOfNonDecreasingIsSelf(Fill(a));
  }
}

lemma FixedPoint(a: seq<int>, i: int)
  requires 0 <= i < |a|
  ensures i == 0 ==> Fill(a)[i] == a[i]
  ensures i > 0 && a[i] >= Fill(a)[i-1] ==> Fill(a)[i] == a[i]
{
  if i > 0 && a[i] >= Fill(a)[i-1] {
    assert Fill(a)[i] == max(Fill(a)[i-1], a[i]) by {
      assert Fill(a)[i] == MaxSeq(a[0..i+1]);
      assert Fill(a)[i-1] == MaxSeq(a[0..i]);
      MaxSeqMonotonic(a[0..i], a[0..i+1]);
      assert a[i] >= Fill(a)[i-1] == MaxSeq(a[0..i]);
      assert MaxSeq(a[0..i+1]) == max(MaxSeq(a[0..i]), a[i]) == a[i];
    }
  }
}
```

This solution:
1. Defines `MaxSeq` to compute the maximum value in a sequence.
2. Implements `Fill` using a cumulative maximum approach.
3. Proves `Fill` produces non-decreasing sequences.
4. Establishes idempotence: `Fill(Fill(a)) = Fill(a)`.
5. Shows cells that are local maxima (or the outlet) remain unchanged by `Fill`.
