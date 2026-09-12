function max(a: int, b: int): int {
  if a >= b then a else b
}

function method Fill(a: array<int>): (b: array<int>)
  requires a.Length >= 1
  ensures b.Length == a.Length
  ensures b[0] == a[0]
  ensures forall i :: 1 <= i < a.Length ==> b[i] == max(a[i], b[i-1])
{
  b := new int[a.Length];
  b[0] := a[0];
  var idx := 1;
  while idx < a.Length
    invariant 1 <= idx <= a.Length
    invariant b[0] == a[0]
    invariant forall j :: 1 <= j < idx ==> b[j] == max(a[j], b[j-1])
    decreases a.Length - idx
  {
    b[idx] := max(a[idx], b[idx-1]);
    idx := idx + 1;
  }
  b
}

predicate ArrayEqual(a: array<int>, b: array<int>)
  requires a != null && b != null
  requires a.Length == b.Length
{
  forall i | 0 <= i < a.Length :: a[i] == b[i]
}

predicate NonDecreasing(a: array<int>)
  requires a != null
{
  forall i | 1 <= i < a.Length :: a[i] >= a[i-1]
}

lemma LemmaFillMakesNonDecreasing(a: array<int>)
  requires a.Length >= 1
  ensures NonDecreasing(Fill(a))
{
  var b := Fill(a);
}

lemma LemmaFillIdempotentOnNonDecreasing(a: array<int>)
  requires a.Length >= 1
  requires NonDecreasing(a)
  ensures ArrayEqual(Fill(a), a)
{
  var b := Fill(a);
  for i := 0 to a.Length - 1
    invariant forall j | 0 <= j < i :: b[j] == a[j]
  {
    if i > 0 {
      assert a[i] >= a[i-1] by {
        assert NonDecreasing(a);
      }
    }
  }
}

lemma LemmaIdempotent(a: array<int>)
  requires a.Length >= 1
  ensures ArrayEqual(Fill(Fill(a)), Fill(a))
{
  var b := Fill(a);
  LemmaFillMakesNonDecreasing(a);
  LemmaFillIdempotentOnNonDecreasing(b);
}

lemma LemmaFixedPoint(a: array<int>, i: int)
  requires a.Length >= 1
  requires 0 <= i < a.Length
  requires forall j | 1 <= j <= i :: a[j] >= a[j-1]
  ensures Fill(a)[i] == a[i]
{
  var b := Fill(a);
  for k := 0 to i
    invariant forall j | 0 <= j < k :: b[j] == a[j]
  {
    if k > 0 {
      assert a[k] >= a[k-1] by {
        assert k <= i;
      }
    }
  }
}
