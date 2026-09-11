function max(a: int, b: int): int {
  if a > b then a else b
}

method ComputeFill(orig: array<int>) returns (fill: array<int>)
  requires orig != null
  ensures fill != null && fill.Length == orig.Length
  ensures fill[0] == orig[0]
  ensures forall i :: 1 <= i < orig.Length ==> fill[i] == max(orig[i], fill[i-1])
  ensures forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]
  ensures forall i, j :: 0 <= i <= j < fill.Length ==> fill[i] <= fill[j]
{
  fill := new int[orig.Length];
  if orig.Length == 0 {
    return;
  }
  fill[0] := orig[0];
  var i := 1;
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant fill[0] == orig[0]
    invariant forall k :: 1 <= k < i ==> fill[k] == max(orig[k], fill[k-1])
    invariant forall k :: 0 <= k < i ==> fill[k] >= orig[k]
    invariant forall k, j :: 0 <= k <= j < i ==> fill[k] <= fill[j]
  {
    fill[i] := max(orig[i], fill[i-1]);
    i := i + 1;
  }
}
