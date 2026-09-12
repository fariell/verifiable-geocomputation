predicate NonDecreasing(a: seq<int>) {
  forall i: int :: 0 <= i < |a| - 1 ==> a[i] <= a[i+1]
}

function Max(s: seq<int>): int
  requires |s| > 0
{
  if |s| == 1 then s[0]
  else max(s[0], Max(s[1..]))
}

lemma Lemma_Max_concat(s: seq<int>, x: int)
  requires |s| > 0
  ensures Max(s + [x]) == max(Max(s), x)
{
  if |s| == 1 {
  } else {
    Lemma_Max_concat(s[1..], x);
  }
}

lemma Lemma_Max_last(s: seq<int>)
  requires |s| > 0
  requires NonDecreasing(s)
  ensures Max(s) == s[|s|-1]
{
  if |s| == 1 {
  } else {
    Lemma_Max_last(s[1..]);
  }
}

function Fill(a: seq<int>): seq<int> {
  if |a| == 0 then a
  else seq(|a|, i requires 0 <= i < |a| => Max(a[0..i+1]))
}

lemma Lemma_Fill_NonDecreasing(a: seq<int>)
  ensures NonDecreasing(Fill(a))
{
  if |a| == 0 {
  } else {
    forall i | 0 <= i < |a| - 1 
      ensures Fill(a)[i] <= Fill(a)[i+1]
    {
      Lemma_Max_concat(a[0..i+1], a[i+1]);
    }
  }
}

lemma Lemma_Fill_idempotent_aux(b: seq<int>)
  requires NonDecreasing(b)
  ensures Fill(b) == b
{
  if |b| == 0 {
  } else {
    for i := 0 to |b| - 1 
      invariant forall j: int :: 0 <= j < i ==> Fill(b)[j] == b[j]
    {
      if i > 0 {
        var seg := b[0..i+1];
        Lemma_Max_last(seg);
      }
    }
  }
}

theorem Theorem_Idempotent(a: seq<int>)
  ensures Fill(Fill(a)) == Fill(a)
{
  Lemma_Fill_NonDecreasing(a);
  Lemma_Fill_idempotent_aux(Fill(a));
}

theorem Theorem_FixedPoint(a: seq<int>, i: int)
  requires 0 <= i < |a|
  ensures (i == 0 || a[i] >= Max(a[0..i])) ==> Fill(a)[i] == a[i]
{
  if i == 0 {
  } else {
    if a[i] >= Max(a[0..i]) {
      Lemma_Max_concat(a[0..i], a[i]);
    }
  }
}
