function max(a: int, b: int): int {
  if a >= b then a else b
}

function Fill(a: seq<int>): seq<int>
  requires |a| > 0
  ensures |Fill(a)| == |a|
  ensures Fill(a)[0] == a[0]
  ensures forall i :: 1 <= i < |a| ==> Fill(a)[i] == max(a[i], Fill(a)[i-1])
{
  if |a| == 1 then
    [a[0]]
  else
    var b := Fill(a[0..|a|-1]);
    b + [max(a[|a|-1], b[|b|-1])]
}

lemma Idempotent(a: seq<int>)
  requires |a| > 0
  ensures Fill(Fill(a)) == Fill(a)
{
  if |a| == 1 {
    // Base case: single element
  } else {
    var d := a[0..|a|-1];
    Idempotent(d);  // Induction on prefix

    var fill_d := Fill(d);
    var c := Fill(a);
    assert c == fill_d + [max(a[|a|-1], fill_d[|fill_d|-1])];

    var prefix_c := c[0..|c|-1];
    assert prefix_c == fill_d;

    var fill_prefix := Fill(prefix_c);
    assert fill_prefix == fill_d by {
      Idempotent(d);  // Fill(Fill(d)) == Fill(d)
    }

    var last_element := max(c[|c|-1], fill_prefix[|fill_prefix|-1]);
    assert last_element == max(c[|c|-1], fill_d[|fill_d|-1]);
    assert last_element == max(max(a[|a|-1], fill_d[|fill_d|-1]), fill_d[|fill_d|-1])
                    == max(a[|a|-1], fill_d[|fill_d|-1])  // max property
                    == c[|c|-1];

    assert Fill(c) == fill_prefix + [last_element];
    assert fill_prefix + [last_element] == fill_d + [c[|c|-1]] == c;
  }
}

lemma FixedPoint(a: seq<int>, i: int)
  requires |a| > 0
  requires 0 <= i < |a|
  ensures (i == 0 ==> Fill(a)[i] == a[i]) &&
          (i > 0 && a[i] >= Fill(a)[i-1] ==> Fill(a)[i] == a[i])
{
  // Directly follows from Fill's definition
}
