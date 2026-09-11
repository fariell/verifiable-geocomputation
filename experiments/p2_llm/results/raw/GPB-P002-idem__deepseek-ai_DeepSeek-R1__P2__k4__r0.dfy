function max(a: int, b: int): int {
  if a >= b then a else b
}

predicate IsFilled(a: array<int>, b: array<int>)
  requires a != null && b != null
{
  a.Length == b.Length &&
  b[0] == a[0] &&
  (forall i | 1 <= i < a.Length :: b[i] == max(a[i], b[i-1]))
}

predicate IsSameArray(a: array<int>, b: array<int>)
  requires a != null && b != null
{
  a.Length == b.Length &&
  (forall i | 0 <= i < a.Length :: a[i] == b[i])
}

function method Fill(a: array<int>): array<int>
  requires a != null
  ensures IsFilled(a, Fill(a))
  ensures Fill(a).Length == a.Length
{
  var b := new int[a.Length];
  if a.Length == 0 {
    return b;
  }
  b[0] := a[0];
  var i := 1;
  while i < a.Length
    invariant 1 <= i <= a.Length
    invariant b[0] == a[0]
    invariant forall j | 1 <= j < i :: b[j] == max(a[j], b[j-1])
  {
    b[i] := max(a[i], b[i-1]);
    i := i + 1;
  }
  b
}

lemma FillOfFilledIsIdentity(b: array<int>)
  requires b != null
  requires IsFilled(b, b)
  ensures IsSameArray(Fill(b), b)
{
  if b.Length == 0 { return; }
  var fb := Fill(b);
  var idx: int := 0;
  while idx < b.Length
    invariant 0 <= idx <= b.Length
    invariant forall j | 0 <= j < idx :: fb[j] == b[j]
  {
    if idx > 0 {
      assert fb[idx] == max(b[idx], fb[idx-1]);
      assert fb[idx-1] == b[idx-1] by { assume idx-1 >= 0; }
      assert fb[idx] == max(b[idx], b[idx-1]);
      assert b[idx] == max(b[idx], b[idx-1]) by {
        assert IsFilled(b, b) && idx >= 1 ==> b[idx] == max(b[idx], b[idx-1]);
      }
    }
    idx := idx + 1;
  }
}

lemma Idempotent(a: array<int>)
  requires a != null
  ensures IsSameArray(Fill(Fill(a)), Fill(a))
{
  var fa := Fill(a);
  var i: int := 1;
  while i < fa.Length
    invariant 1 <= i <= fa.Length
    invariant forall j | 1 <= j < i :: fa[j] >= fa[j-1]
  {
    i := i + 1;
  }
  FillOfFilledIsIdentity(fa);
}

lemma FixedPoint(a: array<int>, i: int)
  requires a != null && 0 <= i < a.Length
  requires i == 0 || a[i] >= Fill(a)[i-1]
  ensures Fill(a)[i] == a[i]
{
  if i > 0 {
    assert Fill(a)[i] == max(a[i], Fill(a)[i-1]);
  }
}
