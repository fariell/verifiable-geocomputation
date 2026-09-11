method Fill(orig: array<int>) returns (fill: array<int>)
  requires orig.Length >= 1
  ensures fill.Length == orig.Length
  ensures forall i :: 0 <= i < fill.Length ==> fill[i] >= orig[i]  // Monotonicity
  ensures forall i :: 0 <= i < fill.Length-1 ==> fill[i] <= fill[i+1]  // Nondecreasing
{
  fill := new int[orig.Length];
  fill[0] := orig[0];
  var i := 1;
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
    invariant forall j :: 0 <= j < i-1 ==> fill[j] <= fill[j+1]
    decreases orig.Length - i
  {
    fill[i] := if orig[i] > fill[i-1] then orig[i] else fill[i-1];
    i := i + 1;
  }
}
