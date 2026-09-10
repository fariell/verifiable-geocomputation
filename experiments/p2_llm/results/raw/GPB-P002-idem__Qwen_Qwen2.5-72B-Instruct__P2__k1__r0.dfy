method Fill(a: array<int>) returns (b: array<int>)
  requires a != null;
  requires a.Length > 0;
  ensures b != null;
  ensures b.Length == a.Length;
  ensures forall i :: 0 <= i < b.Length - 1 ==> b[i] <= b[i + 1];
{
  b := new int[a.Length];
  var max := a[0];
  for i := 0 to a.Length - 1
    invariant 0 <= i <= a.Length;
    invariant forall j :: 0 <= j < i ==> b[j] == a[j] || b[j] == max;
    invariant max == a[0] || (exists k :: 0 <= k < i ==> max == a[k]);
  {
    if a[i] > max {
      max := a[i];
    }
    b[i] := max;
  }
}

method Raise(a: array<int>) returns (b: array<int>)
  requires a != null;
  requires a.Length > 0;
  ensures b != null;
  ensures b.Length == a.Length;
  ensures forall i :: 0 <= i < b.Length - 1 ==> b[i] <= b[i + 1];
  ensures forall i :: 0 <= i < a.Length ==> a[i] <= b[i];
{
  b := new int[a.Length];
  var max := a[0];
  for i := 0 to a.Length - 1
    invariant 0 <= i <= a.Length;
    invariant forall j :: 0 <= j < i ==> b[j] == a[j] || b[j] == max;
    invariant max == a[0] || (exists k :: 0 <= k < i ==> max == a[k]);
  {
    if a[i] > max {
      max := a[i];
    }
    b[i] := max;
  }
}

lemma FillIsIdempotent(a: array<int>)
  requires a != null;
  requires a.Length > 0;
  ensures Fill(Fill(a)) == Fill(a);
{
  var b := Fill(a);
  var c := Fill(b);
  assert forall i :: 0 <= i < a.Length ==> c[i] == b[i];
}

lemma RaiseFixesNonSpill(a: array<int>)
  requires a != null;
  requires a.Length > 0;
  requires forall i :: 0 <= i < a.Length - 1 ==> a[i] <= a[i + 1];
  ensures Raise(a) == a;
{
  var b := Raise(a);
  assert forall i :: 0 <= i < a.Length ==> b[i] == a[i];
}
