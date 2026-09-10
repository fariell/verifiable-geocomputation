method Fill(a: array<int>) returns (b: array<int>)
  requires a != null;
  ensures b != null;
  ensures b.Length == a.Length;
  ensures forall i :: 0 <= i < b.Length - 1 ==> b[i] <= b[i + 1];
{
  b := new int[a.Length];
  var maxSoFar := a[0];
  for i := 0 to a.Length - 1 do
    invariant 0 <= i <= a.Length;
    invariant forall j :: 0 <= j < i ==> b[j] == maxSoFar;
    invariant maxSoFar == max(a[0..i]);
    b[i] := maxSoFar;
    if a[i] > maxSoFar then maxSoFar := a[i];
  }
}

method Raise(a: array<int>) returns (b: array<int>)
  requires a != null;
  ensures b != null;
  ensures b.Length == a.Length;
  ensures forall i :: 0 <= i < b.Length - 1 ==> b[i] >= b[i + 1];
{
  b := new int[a.Length];
  var minSoFar := a[a.Length - 1];
  for i := a.Length - 1 to 0 do
    invariant 0 <= i <= a.Length;
    invariant forall j :: i < j < a.Length ==> b[j] == minSoFar;
    invariant minSoFar == min(a[i..a.Length]);
    b[i] := minSoFar;
    if a[i] < minSoFar then minSoFar := a[i];
  }
}

lemma FillIsIdempotent(a: array<int>)
  requires a != null;
  ensures Fill(Fill(a)) == Fill(a);
{
  var b := Fill(a);
  var c := Fill(b);
  assert forall i :: 0 <= i < a.Length ==> c[i] == b[i];
}

lemma RaiseFixesNonSpill(a: array<int>)
  requires a != null;
  requires forall i :: 0 <= i < a.Length - 1 ==> a[i] >= a[i + 1];
  ensures Raise(a) == a;
{
  var b := Raise(a);
  assert forall i :: 0 <= i < a.Length ==> b[i] == a[i];
}
