function max(a: real, b: real): real {
  if a >= b then a else b
}

function Fill(orig: seq<real>): seq<real>
  ensures |Fill(orig)| == |orig|
  ensures |orig| > 0 ==> Fill(orig)[0] == orig[0]
  ensures forall i :: 1 <= i < |orig| ==> Fill(orig)[i] == max(orig[i], Fill(orig)[i-1])
  ensures forall i, j :: 0 <= i <= j < |orig| ==> Fill(orig)[i] <= Fill(orig)[j]
{
  if orig == [] then []
  else
    var f0 := orig[0];
    var frest := FillRest(orig[1..], f0);
    [f0] + frest
}

function FillRest(rest: seq<real>, prev: real): seq<real>
  ensures |FillRest(rest, prev)| == |rest|
  ensures |rest| > 0 ==> FillRest(rest, prev)[0] == max(rest[0], prev)
  ensures forall i :: 1 <= i < |rest| ==> FillRest(rest, prev)[i] == max(rest[i], FillRest(rest, prev)[i-1])
  ensures forall i, j :: 0 <= i <= j < |rest| ==> FillRest(rest, prev)[i] <= FillRest(rest, prev)[j]
  ensures |rest| > 0 ==> FillRest(rest, prev)[0] >= prev
{
  if rest == [] then []
  else
    var cur := max(rest[0], prev);
    var frest1 := FillRest(rest[1..], cur);
    [cur] + frest1
}
