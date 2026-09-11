method FillWangLiu(orig: array<real>) returns (fill: array<real>)
  requires orig != null && orig.Length >= 1
  ensures fill != null && fill.Length == orig.Length
  ensures forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]  // Monotonicity
  ensures forall i :: 1 <= i < orig.Length ==> fill[i] >= fill[i-1]  // Non-decreasing
{
  fill := new real[orig.Length];
  fill[0] := orig[0];
  var i := 1;
  
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
    invariant forall j :: 1 <= j < i ==> fill[j] >= fill[j-1]
  {
    fill[i] := if orig[i] >= fill[i-1] then orig[i] else fill[i-1];
    i := i + 1;
  }
}
