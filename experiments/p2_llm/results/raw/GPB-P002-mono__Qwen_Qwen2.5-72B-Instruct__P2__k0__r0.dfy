method Fill(orig: array<int>) returns (Fill: array<int>)
  requires orig != null;
  requires orig.Length > 0;
  ensures Fill != null;
  ensures Fill.Length == orig.Length;
  ensures Fill[0] == orig[0];
  ensures forall i :: 0 < i < Fill.Length ==> Fill[i] == max(orig[i], Fill[i-1]);
  ensures forall i :: 0 <= i < Fill.Length - 1 ==> Fill[i] <= Fill[i+1];
{
  Fill := new int[orig.Length];
  Fill[0] := orig[0];
  var i := 1;
  while i < Fill.Length
    invariant 0 <= i <= Fill.Length;
    invariant forall j :: 0 <= j < i ==> Fill[j] == max(orig[j], Fill[j-1]);
    invariant forall j :: 0 <= j < i - 1 ==> Fill[j] <= Fill[j+1];
    decreases Fill.Length - i;
  {
    Fill[i] := max(orig[i], Fill[i-1]);
    i := i + 1;
  }
}
