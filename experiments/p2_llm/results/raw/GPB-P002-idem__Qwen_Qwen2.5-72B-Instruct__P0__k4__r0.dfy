method fill_1d(a: array<int>) returns (out: array<int>)
  requires a != null;
  ensures out.Length == a.Length;
  ensures forall i :: 0 <= i < out.Length ==> out[i] == max(a[0..i]);
{
  out := a.Clone();
  for i := 1 to out.Length - 1
    invariant forall j :: 0 <= j < i ==> out[j] == max(a[0..j]);
  {
    out[i] := max(out[i], out[i - 1]);
  }
}

method max(x: int, y: int) returns (z: int)
  ensures z == if x > y then x else y;
{
  if x > y then return x; else return y;
}

method pit_fill_idempotent(a: array<int>) returns (result: bool)
  requires a != null;
  ensures result == (fill_1d(fill_1d(a)) == fill_1d(a));
{
  var b := fill_1d(a);
  var c := fill_1d(b);
  result := b == c;
}

method raise_fixed_point(a: array<int>) returns (result: bool)
  requires a != null;
  ensures result == (forall i :: 0 <= i < a.Length ==> a[i] >= a[i - 1] ==> raise_1d(a)[i] == a[i]);
{
  result := forall i :: 0 <= i < a.Length ==> a[i] >= a[i - 1] ==> raise_1d(a)[i] == a[i];
}

method raise_1d(a: array<int>) returns (out: array<int>)
  requires a != null;
  ensures out.Length == a.Length;
  ensures forall i :: 0 <= i < out.Length ==> out[i] >= a[i];
  ensures forall i :: 0 < i < out.Length ==> out[i] >= out[i - 1];
{
  out := a.Clone();
  for i := 1 to out.Length - 1
    invariant forall j :: 0 <= j < i ==> out[j] >= a[j];
    invariant forall j :: 0 < j < i ==> out[j] >= out[j - 1];
  {
    out[i] := max(out[i], out[i - 1]);
  }
}

lemma pit_fill_idempotent_lemma(a: array<int>)
  requires a != null;
  ensures fill_1d(fill_1d(a)) == fill_1d(a);
{
  var b := fill_1d(a);
  var c := fill_1d(b);
  assert c.Length == a.Length;
  assert forall i :: 0 <= i < c.Length ==> c[i] == max(b[i], b[i - 1]);
  assert forall i :: 0 <= i < b.Length ==> b[i] == max(a[0..i]);
  assert forall i :: 0 <= i < c.Length ==> c[i] == max(max(a[0..i]), max(a[0..i-1]));
  assert forall i :: 0 <= i < c.Length ==> c[i] == max(a[0..i]);
  assert c == b;
}

lemma raise_fixed_point_lemma(a: array<int>)
  requires a != null;
  ensures forall i :: 0 <= i < a.Length ==> a[i] >= a[i - 1] ==> raise_1d(a)[i] == a[i];
{
  var out := raise_1d(a);
  assert out.Length == a.Length;
  assert forall i :: 0 <= i < out.Length ==> out[i] >= a[i];
  assert forall i :: 0 < i < out.Length ==> out[i] >= out[i - 1];
  assert forall i :: 0 <= i < a.Length ==> a[i] >= a[i - 1] ==> out[i] == a[i];
}
