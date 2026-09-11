// P0: Pit filling idempotent and fixed point properties in 1D
function prefixMax(a: seq<int>, i: int): int
  requires 0 <= i < |a|
  decreases i
{
  if i == 0 then a[0]
  else
    var prev := prefixMax(a, i-1);
    if a[i] > prev then a[i] else prev
}

function Fill(a: seq<int>): seq<int>
  requires |a| > 0
{
  seq(|a|, i requires 0<=i<|a| => prefixMax(a, i))
}

lemma NonDecreasing(a: seq<int>)
  requires |a| > 0
  ensures forall j :: 0 <= j < |a|-1 ==> Fill(a)[j] <= Fill(a)[j+1]
{
  forall j | 0 <= j < |a|-1
    ensures Fill(a)[j] <= Fill(a)[j+1]
  {
    assert prefixMax(a, j+1) == (if a[j+1] > prefixMax(a, j) then a[j+1] else prefixMax(a, j));
  }
}

lemma LemmaPrefixMaxForNonDecreasing(b: seq<int>, i: int)
  requires |b| > 0
  requires 0 <= i < |b|
  requires forall j :: 0 <= j < |b|-1 ==> b[j] <= b[j+1]
  ensures prefixMax(b, i) == b[i]
  decreases i
{
  if i > 0 {
    LemmaPrefixMaxForNonDecreasing(b, i-1);
  }
}

lemma Idempotent(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
{
  var b := Fill(a);
  NonDecreasing(a);
  var c := Fill(b);
  forall i | 0 <= i < |a|
    ensures c[i] == b[i]
  {
    LemmaPrefixMaxForNonDecreasing(b, i);
  }
}

lemma FixedPoint(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  requires prefixMax(a, i) == a[i]
  ensures Fill(a)[i] == a[i]
{
}
