// Pit filling is idempotent on the 1D left-outlet specialization: Fill(Fill(a)) = Fill(a).
// Cells that already do not spill to the left are fixed points of Raise.

method Fill1D(a: array<int>) returns (b: array<int>)
  requires a != null
  ensures b != null && b.Length == a.Length
  ensures forall i :: 0 <= i < a.Length ==> b[i] >= a[i]
  ensures forall i :: 1 <= i < a.Length ==> b[i] >= b[i-1]
{
  b := new int[a.Length];
  b[0] := a[0];
  for i := 1 to a.Length - 1
    invariant 1 <= i <= a.Length
    invariant forall j :: 1 <= j < i ==> b[j] >= b[j-1]
    invariant forall j :: 0 <= j < i ==> b[j] >= a[j]
  {
    b[i] := max(b[i-1], a[i]);
  }
}

lemma IdempotentFill1D(a: array<int>)
  requires a != null
  ensures Fill1D(Fill1D(a)) == Fill1D(a)
{
  var b := Fill1D(a);
  var c := Fill1D(b);
  assert c == b;
}

method Main()
{
  var a := new int[4];
  a[0] := 0;
  a[1] := 1;
  a[2] := 2;
  a[3] := 3;
  var b := Fill1D(a);
  var c := Fill1D(b);
  assert b == c;
}
