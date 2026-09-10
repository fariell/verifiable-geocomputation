method Fill(orig: array<int>) returns (Fill: array<int>)
  requires orig.Length > 0
  ensures Fill.Length == orig.Length
  ensures forall i :: 0 <= i < Fill.Length ==> Fill[i] >= orig[i]
  ensures forall i :: 0 < i < Fill.Length ==> Fill[i] >= Fill[i-1]
{
  Fill := new int[orig.Length];
  Fill[0] := orig[0];
  var i: int := 1;
  while i < Fill.Length
    invariant 1 <= i <= Fill.Length
    invariant forall j :: 0 <= j < i ==> Fill[j] >= orig[j]
    invariant forall j :: 0 < j < i ==> Fill[j] >= Fill[j-1]
  {
    Fill[i] := max(orig[i], Fill[i-1]);
    i := i + 1;
  }
}

function max(a: int, b: int): int
{
  if a >= b then a else b
}
