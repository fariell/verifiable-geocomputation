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
    invariant maxSoFar == max(a[..i]);
    b[i] := maxSoFar;
    if a[i] > maxSoFar then maxSoFar := a[i];
  }
}

method Raise(a: array<int>) returns (b: array<int>)
  requires a != null;
  ensures b != null;
  ensures b.Length == a.Length;
  ensures forall i :: 0 <= i < b.Length - 1 ==> b[i] <= b[i + 1];
  ensures forall i :: 0 <= i < b.Length ==> b[i] >= a[i];
{
  b := new int[a.Length];
  var minSoFar := a[0];
  for i := 0 to a.Length - 1 do
    invariant 0 <= i <= a.Length;
    invariant forall j :: 0 <= j < i ==> b[j] == minSoFar;
    invariant minSoFar == min(a[..i]);
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

lemma RaiseFixesNonSpillers(a: array<int>)
  requires a != null;
  ensures forall i :: 0 <= i < a.Length - 1 ==> a[i] <= a[i + 1] ==> Raise(a)[i] == a[i];
{
  var b := Raise(a);
  assert forall i :: 0 <= i < a.Length - 1 ==> a[i] <= a[i + 1] ==> b[i] == a[i];
}
