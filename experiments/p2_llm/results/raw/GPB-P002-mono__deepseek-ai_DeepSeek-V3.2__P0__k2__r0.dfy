// Formalization of 1D Wang-Liu pit-filling with left outlet
// Property: After a full scan the profile is nondecreasing.

method FillProfile(orig: array<int>) returns (Fill: array<int>)
  requires orig != null && orig.Length > 0
  ensures Fill != null && Fill.Length == orig.Length
  ensures forall i :: 0 <= i < Fill.Length - 1 ==> Fill[i] <= Fill[i + 1]
{
  Fill := new int[orig.Length];
  if (orig.Length == 0) {
    return;
  }
  Fill[0] := orig[0];
  var i: int := 1;
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant forall j :: 0 <= j < i ==> Fill[j] == if j == 0 then orig[0] else max(orig[j], Fill[j - 1])
    invariant forall j :: 0 <= j < i - 1 ==> Fill[j] <= Fill[j + 1]
  {
    Fill[i] := if orig[i] > Fill[i - 1] then orig[i] else Fill[i - 1];
    // Show monotonicity for the new pair (i-1, i)
    assert Fill[i - 1] <= Fill[i];
    i := i + 1;
  }
}

function max(a: int, b: int): int
{
  if a > b then a else b
}
