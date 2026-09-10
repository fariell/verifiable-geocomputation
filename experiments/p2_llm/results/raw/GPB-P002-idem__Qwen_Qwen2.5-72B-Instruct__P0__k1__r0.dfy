method fill_1d(a: array<int>) returns (out: array<int>)
  requires a != null;
  ensures out.Length == a.Length;
  ensures forall i :: 0 <= i < out.Length ==> out[i] == max(a[0..i]);
{
  out := a.Clone();
  for i := 1 to a.Length - 1
    invariant 0 <= i <= a.Length;
    invariant forall j :: 0 <= j < i ==> out[j] == max(a[0..j]);
  {
    out[i] := max(out[i], out[i - 1]);
  }
}

method max(a: seq<int>, b: int) returns (result: int)
  ensures result == if a != [] then a.Max else b;
{
  if a != [] {
    result := a.Max;
  } else {
    result := b;
  }
}

method PitFillingIdempotent(a: array<int>) returns (result: bool)
  requires a != null;
  ensures result == (fill_1d(fill_1d(a)) == fill_1d(a));
{
  var filled1 := fill_1d(a);
  var filled2 := fill_1d(filled1);
  result := filled1 == filled2;
}

method RaiseFixedPoint(a: array<int>) returns (result: bool)
  requires a != null;
  ensures result == (forall i :: 0 <= i < a.Length ==> a[i] >= a[i-1] ==> fill_1d(a)[i] == a[i]);
{
  result := true;
  for i := 1 to a.Length - 1
    invariant 0 <= i <= a.Length;
    invariant forall j :: 0 <= j < i ==> (a[j] >= a[j-1] ==> fill_1d(a)[j] == a[j]);
  {
    if a[i] >= a[i-1] && fill_1d(a)[i] != a[i] {
      result := false;
      return;
    }
  }
}

lemma FillIdempotent(a: array<int>)
  requires a != null;
{
  var filled1 := fill_1d(a);
  var filled2 := fill_1d(filled1);
  assert filled1 == filled2;
}

lemma RaiseFixedPointLemma(a: array<int>)
  requires a != null;
{
  forall i | 0 <= i < a.Length
    ensures a[i] >= a[i-1] ==> fill_1d(a)[i] == a[i];
  {
    if i == 0 {
      assert fill_1d(a)[0] == a[0];
    } else {
      if a[i] >= a[i-1] {
        assert fill_1d(a)[i] == max(fill_1d(a)[0..i], a[i]);
        assert fill_1d(a)[i-1] == max(fill_1d(a)[0..i-1], a[i-1]);
        assert fill_1d(a)[i] == max(fill_1d(a)[i-1], a[i]);
        assert fill_1d(a)[i] == a[i];
      }
    }
  }
}
