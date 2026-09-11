method FillPits(orig: array<int>) returns (fill: array<int>)
  requires orig != null
  ensures fill != null && fill.Length == orig.Length
  ensures forall i :: 0 <= i < fill.Length ==> fill[i] >= orig[i]
  ensures forall i :: 1 <= i < fill.Length ==> fill[i] >= fill[i-1]
{
  fill := new int[orig.Length];
  if orig.Length == 0 {
    return;
  }
  fill[0] := orig[0];
  var i := 1;
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
    invariant forall j :: 1 <= j < i ==> fill[j] >= fill[j-1]
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
