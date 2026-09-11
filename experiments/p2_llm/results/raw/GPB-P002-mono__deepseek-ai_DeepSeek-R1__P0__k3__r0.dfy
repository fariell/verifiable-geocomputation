method Fill(orig: array<real>) returns (fill: array<real>)
  requires orig != null
  ensures fill != null && fill.Length == orig.Length
  ensures forall i :: 0 <= i < fill.Length ==> orig[i] <= fill[i]  // Monotonicity: no cell decreases
  ensures forall i :: 0 <= i < fill.Length - 1 ==> fill[i] <= fill[i+1]  // Nondecreasing profile
{
  fill := new real[orig.Length];
  if orig.Length == 0 {
    return;
  }
  fill[0] := orig[0];
  var i := 1;
  while i < orig.Length
    invariant 1 <= i <= orig.Length
    invariant forall j :: 0 <= j < i ==> orig[j] <= fill[j]
    invariant forall j :: 0 <= j < i-1 ==> fill[j] <= fill[j+1]
  {
    if orig[i] > fill[i-1] {
      fill[i] := orig[i];
    } else {
      fill[i] := fill[i-1];
    }
    i := i + 1;
  }
}
