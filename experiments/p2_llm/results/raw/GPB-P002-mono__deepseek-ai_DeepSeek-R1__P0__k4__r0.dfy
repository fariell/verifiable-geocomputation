function Fill(orig: seq<real>): seq<real>
  decreases |orig|
  ensures |Fill(orig)| == |orig|
  ensures forall i :: 0 <= i < |orig| ==> Fill(orig)[i] >= orig[i]
  ensures forall i :: 0 <= i < |orig|-1 ==> Fill(orig)[i] <= Fill(orig)[i+1]
{
  if |orig| == 0 then []
  else if |orig| == 1 then [orig[0]]
  else
    var prev := Fill(orig[0..|orig|-1]);
    prev + [max(orig[|orig|-1], prev[|prev|-1])]
}
