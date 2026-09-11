method Fill(orig: array<int>) returns (fill: array<int>)
  requires orig.Length > 0
  ensures fill.Length == orig.Length
  ensures fill[0] == orig[0]
  ensures forall i :: 1 <= i < orig.Length ==> fill[i] == (if orig[i] > fill[i-1] then orig[i] else fill[i-1])
  ensures forall i :: 0 <= i < orig.Length ==> orig[i] <= fill[i]
  ensures forall i :: 0 <= i < orig.Length - 1 ==> fill[i] <= fill[i+1]
{
  fill := new int[orig.Length];
  fill[0] := orig[0];
  var i := 1;

  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant fill[0] == orig[0]
    invariant forall j :: 1 <= j < i ==> fill[j] == (if orig[j] > fill[j-1] then orig[j] else fill[j-1])
    invariant forall j :: 0 <= j < i ==> orig[j] <= fill[j]
    invariant forall j,k :: 0 <= j <= k < i ==> fill[j] <= fill[k]
    decreases orig.Length - i
  {
    if orig[i] > fill[i-1] {
      fill[i] := orig[i];
    } else {
      fill[i] := fill[i-1];
    }
    i := i + 1;
  }
}
