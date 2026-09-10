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
  if x > y then return x else return y;
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
  ensures result == (forall i :: 0 <= i < a.Length ==> a[i] >= a[i - 1] ==> fill_1d(a)[i] == a[i]);
{
  result := true;
  for i := 1 to a.Length - 1
    invariant forall j :: 0 <= j < i ==> a[j] >= a[j - 1] ==> fill_1d(a)[j] == a[j];
  {
    if a[i] >= a[i - 1] && fill_1d(a)[i] != a[i] {
      result := false;
      break;
    }
  }
}

method main()
{
  var a := new int[3];
  a[0] := 3;
  a[1] := 1;
  a[2] := 4;

  var b := new int[4];
  b[0] := 0;
  b[1] := 1;
  b[2] := 2;
  b[3] := 3;

  var c := new int[3];
  c[0] := 3;
  c[1] := 1;
  c[2] := 0;

  var d := new int[4];
  d[0] := 5;
  d[1] := 5;
  d[2] := 5;
  d[3] := 5;

  var cases := [a, b, c, d];
  var expected := [new int[3]{3, 3, 4}, new int[4]{0, 1, 2, 3}, new int[3]{3, 3, 3}, new int[4]{5, 5, 5, 5}];

  for i := 0 to cases.Length - 1
  {
    var a := cases[i];
    var e := expected[i];
    var f := fill_1d(a);
    assert f == e; // This should be checked by the user or another method to ensure correctness
    var g := fill_1d(f);
    assert g == f; // This should be checked by the user or another method to ensure correctness
  }

  var idempotent := pit_fill_idempotent(a);
  var fixed_point := raise_fixed_point(a);

  print "Idempotent: ", idempotent, "\n";
  print "Fixed Point: ", fixed_point, "\n";
}
