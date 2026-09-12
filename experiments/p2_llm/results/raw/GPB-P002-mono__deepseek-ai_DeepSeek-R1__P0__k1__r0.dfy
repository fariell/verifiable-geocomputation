function Fill(orig: seq<real>, i: int): real
  requires 0 <= i < |orig|
  decreases i
{
  if i == 0 then orig[0] else max(orig[i], Fill(orig, i-1))
}

lemma Monotonicity(orig: seq<real>, i: int)
  requires |orig| >= 1
  requires 0 <= i < |orig|
  ensures Fill(orig, i) >= orig[i]
{
  if i != 0 {
    Monotonicity(orig, i-1);
  }
}

lemma Nondecreasing(orig: seq<real>, i: int)
  requires |orig| >= 1
  requires 0 <= i < |orig| - 1
  ensures Fill(orig, i) <= Fill(orig, i+1)
{
  if i+1 != 0 {
    assert Fill(orig, i+1) == max(orig[i+1], Fill(orig, i));
  }
}
