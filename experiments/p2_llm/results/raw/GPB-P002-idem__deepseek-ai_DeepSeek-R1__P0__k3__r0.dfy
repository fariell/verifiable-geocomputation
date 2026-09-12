function Fill(a: seq<int>): seq<int> {
  if |a| == 0 then []
  else [a[0]] + FillFrom(a[1..], a[0])
}

function FillFrom(a: seq<int>, cur: int): seq<int>
  decreases |a|;
{
  if |a| == 0 then []
  else [max(a[0], cur)] + FillFrom(a[1..], max(a[0], cur))
}

lemma FillIndex(a: seq<int>, i: int)
  requires 0 <= i < |a|
  ensures Fill(a)[i] == (if i == 0 then a[0] else max(a[i], Fill(a)[i-1]))
{
  if i == 0 {
  } else {
    if i == 1 {
      assert Fill(a)[1] == FillFrom(a[1..], a[0])[0];
    } else {
      FillIndex(a, i-1);
      assert Fill(a)[i] == FillFrom(a[1..], a[0])[i-1];
    }
  }
}

lemma FillNonDecreasing(a: seq<int>, i: int)
  requires 1 <= i < |a|
  ensures Fill(a)[i] >= Fill(a)[i-1]
{
  FillIndex(a, i);
  FillIndex(a, i-1);
}

lemma FixedPoint(a: seq<int>, i: int)
  requires 0 <= i < |a|
  requires forall j :: 1 <= j <= i ==> a[j] >= a[j-1]
  ensures Fill(a)[i] == a[i]
{
  if i == 0 {
  } else {
    FixedPoint(a, i-1);
    FillIndex(a, i);
    assert a[i] >= a[i-1];
    assert Fill(a)[i-1] == a[i-1];
  }
}

lemma Idempotent(a: seq<int>)
  ensures Fill(Fill(a)) == Fill(a)
{
  var b := Fill(a);
  forall i | 0 <= i < |b| 
    ensures Fill(b)[i] == b[i] 
  {
    if i >= 1 {
      FillNonDecreasing(a, i);
      assert b[i] >= b[i-1];
    }
    FixedPoint(b, i);
  }
}
