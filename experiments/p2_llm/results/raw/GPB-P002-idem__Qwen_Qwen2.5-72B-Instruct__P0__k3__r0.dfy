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

method max(a: seq<int>, b: int) returns (result: int)
  ensures result == if a.Length == 0 then b else a.Max;
{
  if a.Length == 0 {
    return b;
  } else {
    return a.Max;
  }
}

method PitFillingIdempotent(a: array<int>) returns (result: bool)
  requires a != null;
  ensures result == (fill_1d(fill_1d(a)) == fill_1d(a));
{
  var filled1 := fill_1d(a);
  var filled2 := fill_1d(filled1);
  return filled1 == filled2;
}

method RaiseFixedPoint(a: array<int>) returns (result: bool)
  requires a != null;
  ensures result == (forall i :: 0 <= i < a.Length ==> a[i] >= a[i-1] ==> fill_1d(a)[i] == a[i]);
{
  var filled := fill_1d(a);
  result := forall i :: 0 <= i < a.Length ==> a[i] >= a[i-1] ==> filled[i] == a[i];
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
  var filled := fill_1d(a);
  forall i | 0 <= i < a.Length
    ensures a[i] >= a[i-1] ==> filled[i] == a[i];
  {
    if i == 0 {
      assert filled[i] == a[i];
    } else {
      if a[i] >= a[i-1] {
        assert filled[i] == max(filled[i], filled[i-1]);
        assert filled[i-1] == a[i-1];
        assert filled[i] == a[i];
      }
    }
  }
}
