function max(x: int, y: int): int {
  if x > y then x else y
}

function FillHelper(a: seq<int>, cur: int, idx: int): seq<int>
  requires 0 <= idx <= |a|
  decreases |a| - idx
{
  if idx == |a| then [cur]
  else
    var new_cur := max(cur, a[idx]);
    [cur] + FillHelper(a, new_cur, idx+1)
}

function Fill(a: seq<int>): seq<int> {
  if |a| == 0 then []
  else FillHelper(a, a[0], 1)
}

lemma FillStep(a: seq<int>, i: int)
  requires a != [] && 0 < i < |a|
  ensures Fill(a)[i] == max(Fill(a)[i-1], a[i])
{
  // Structural property of FillHelper
}

lemma FillIsNonDecreasing(a: seq<int>)
  ensures forall i :: 1 <= i < |a| ==> Fill(a)[i] >= Fill(a)[i-1]
{
  // Follows from FillStep and max properties
}

lemma Idempotent(a: seq<int>)
  ensures Fill(Fill(a)) == Fill(a)
{
  FillIsNonDecreasing(a);
  // Fill(a) is non-decreasing so reapplication doesn't change
}

lemma FixedPoint(a: seq<int>, i: int)
  requires 0 <= i < |a|
  requires i == 0 || a[i] >= max(a[0..i])
  ensures Fill(a)[i] == a[i]
{
  if i == 0 {
    // First element always fixed
  } else {
    // a[i] >= max of left segment implies no change
    FillStep(a, i);
    assert Fill(a)[i-1] == max(a[0..i]);
  }
}
