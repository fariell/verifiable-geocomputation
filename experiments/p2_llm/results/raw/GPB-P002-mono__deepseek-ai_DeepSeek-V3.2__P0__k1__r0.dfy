// Formalization of 1D Wang-Liu pit-filling with left outlet
// Property: After a full scan the profile is nondecreasing.

method FillProfile(orig: array<int>) returns (Fill: array<int>)
  requires orig.Length > 0
  ensures Fill.Length == orig.Length
  ensures forall i :: 0 <= i < Fill.Length ==> Fill[i] >= orig[i]  // monotone raise
  ensures forall i :: 0 < i < Fill.Length ==> Fill[i] >= Fill[i-1]  // nondecreasing profile
{
  Fill := new int[orig.Length];
  Fill[0] := orig[0];
  var i: int := 1;
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant forall j :: 0 <= j < i ==> Fill[j] >= orig[j]
    invariant forall j :: 0 < j < i ==> Fill[j] >= Fill[j-1]
  {
    Fill[i] := if orig[i] > Fill[i-1] then orig[i] else Fill[i-1];
    i := i + 1;
  }
}
