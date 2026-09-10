method Fill(a: array<int>) returns (b: array<int>)
  requires a.Length > 0
  ensures b.Length == a.Length
  ensures forall i | 0 <= i < b.Length :: b[i] >= a[i]
  ensures forall i | 0 <= i < b.Length :: b[i] >= (if i == 0 then b[i] else b[i-1])
  ensures forall i | 0 <= i < b.Length :: b[i] == a[i] || (i > 0 && b[i] == b[i-1])
{
  b := new int[a.Length];
  var i := 0;
  while i < a.Length
    invariant 0 <= i <= a.Length
    invariant forall j | 0 <= j < i :: b[j] >= a[j]
    invariant forall j | 0 <= j < i :: b[j] >= (if j == 0 then b[j] else b[j-1])
    invariant forall j | 0 <= j < i :: b[j] == a[j] || (j > 0 && b[j] == b[j-1])
  {
    if i == 0 {
      b[i] := a[i];
    } else {
      b[i] := max(a[i], b[i-1]);
    }
    i := i + 1;
  }
}

method Idempotence(a: array<int>)
  requires a.Length > 0
{
  var b := Fill(a);
  var c := Fill(b);
  assert b.Length == c.Length;
  forall i | 0 <= i < b.Length
    ensures b[i] == c[i]
  {
    assert b[i] == c[i];
  }
}

method RaiseFixedPoint(a: array<int>, i: int)
  requires a.Length > 0
  requires 0 <= i < a.Length
  requires i == 0 || a[i] >= a[i-1]
{
  var b := Fill(a);
  assert b[i] == a[i];
}
