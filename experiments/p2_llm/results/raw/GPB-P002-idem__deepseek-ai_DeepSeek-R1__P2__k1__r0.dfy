function prefixMax(a: seq<int>, i: int): int
  requires 0 <= i < |a|
  decreases i
{
  if i == 0 then a[0] else max(a[i], prefixMax(a, i-1))
}

function Fill(a: seq<int>): seq<int> {
  if |a| == 0 then a else
    seq(|a|, i requires 0 <= i < |a| => prefixMax(a, i))
}

lemma FillIsNonDecreasing(a: seq<int>)
  requires |a| > 0
  ensures forall j :: 1 <= j < |a| ==> Fill(a)[j] >= Fill(a)[j-1]
{
  // Follows directly from prefixMax definition
}

lemma PrefixMaxForNonDecreasing(a: seq<int>)
  requires |a| > 0
  requires forall j :: 1 <= j < |a| ==> a[j] >= a[j-1]
  ensures forall i :: 0 <= i < |a| ==> prefixMax(a, i) == a[i]
  decreases |a|
{
  if |a| > 1 {
    PrefixMaxForNonDecreasing(a[0..|a|-1]);
  }
}

lemma Idempotence(a: seq<int>)
  ensures Fill(Fill(a)) == Fill(a)
{
  if |a| == 0 {
    // Trivial for empty array
  } else {
    var b := Fill(a);
    FillIsNonDecreasing(a);
    assert forall j | 1 <= j < |b| :: b[j] >= b[j-1];
    PrefixMaxForNonDecreasing(b);
    assert forall i | 0 <= i < |b| :: prefixMax(b, i) == b[i];
    assert Fill(b) == b;
  }
}

lemma FixedPoint(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires i == 0 || a[i] >= prefixMax(a, i-1)
  ensures Fill(a)[i] == a[i]
{
  // Directly from definition when condition holds
}
