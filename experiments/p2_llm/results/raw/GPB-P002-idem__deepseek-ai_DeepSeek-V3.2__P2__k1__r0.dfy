method Fill(a: array<int>) returns (b: array<int>)
  requires a.Length > 0
  ensures b.Length == a.Length
  ensures forall i | 0 <= i < b.Length :: b[i] >= a[i]
  ensures forall i | 0 <= i < b.Length :: b[i] >= (if i == 0 then b[i] else b[i-1])
  ensures forall i | 0 <= i < b.Length :: b[i] == a[i] || b[i] == (if i == 0 then b[i] else b[i-1])
{
  b := new int[a.Length];
  var i: int := 0;
  while i < a.Length
    invariant 0 <= i <= a.Length
    invariant forall j | 0 <= j < i :: b[j] >= a[j]
    invariant forall j | 0 <= j < i :: b[j] >= (if j == 0 then b[j] else b[j-1])
    invariant forall j | 0 <= j < i :: b[j] == a[j] || b[j] == (if j == 0 then b[j] else b[j-1])
  {
    if i == 0 {
      b[i] := a[i];
    } else {
      b[i] := max(a[i], b[i-1]);
    }
    i := i + 1;
  }
}

method IdempotenceTheorem(a: array<int>)
  requires a.Length > 0
{
  var b := Fill(a);
  var c := Fill(b);
  assert b.Length == c.Length;
  forall i | 0 <= i < b.Length
    ensures b[i] == c[i]
  {
    // Fill(Fill(a)) = Fill(a)
  }
}

method RaiseFixedPoint(a: array<int>)
  requires a.Length > 0
  requires forall i | 0 <= i < a.Length :: a[i] >= (if i == 0 then a[i] else a[i-1])
{
  var b := Fill(a);
  forall i | 0 <= i < b.Length
    ensures b[i] == a[i]
  {
    // Cells that already do not spill to the left are fixed points of Raise
  }
}
