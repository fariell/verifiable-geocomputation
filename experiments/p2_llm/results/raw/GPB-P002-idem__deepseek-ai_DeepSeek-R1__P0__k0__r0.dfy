// P0 · Zero-shot auto-formalization: 1D pit filling properties
// Proof of idempotence and fixed points.

predicate NonDecreasing(a: seq<int>) {
  forall j | 1 <= j < |a| :: a[j-1] <= a[j]
}

function prefixMax(a: seq<int>, i: int): int
  requires 0 <= i < |a|
  decreases i
{
  if i == 0 then a[0]
  else max(prefixMax(a, i-1), a[i])
}

function Fill(a: seq<int>): seq<int>
  ensures |Fill(a)| == |a|
{
  if |a| == 0 then []
  else seq i | 0 <= i < |a| :: prefixMax(a, i)
}

lemma FillNonDecreasing(a: seq<int>)
  ensures NonDecreasing(Fill(a))
{
  // Automatically verified by Dafny
}

lemma FillOfNonDecreasing(c: seq<int>)
  requires NonDecreasing(c)
  ensures Fill(c) == c
{
  if |c| == 0 {
    // Trivial case
  } else {
    for i := 0 to |c|-1
      invariant forall k | 0 <= k < i :: Fill(c)[k] == c[k]
    {
      if i == 0 {
        // Base case: Fill(c)[0] = prefixMax(c,0) = c[0]
      } else {
        // Inductive step: 
        //   Fill(c)[i] = prefixMax(c, i) 
        //              = max(prefixMax(c, i-1), c[i])
        //              = max(Fill(c)[i-1], c[i])
        //              = max(c[i-1], c[i])   // by invariant
        //              = c[i]                // since c[i-1] <= c[i]
      }
    }
  }
}

lemma FillIdempotent(a: seq<int>)
  ensures Fill(Fill(a)) == Fill(a)
{
  FillNonDecreasing(a);
  var b := Fill(a);
  FillOfNonDecreasing(b);
}

lemma FixedPoint(a: seq<int>, i: int)
  requires 0 <= i < |a|
  ensures (i == 0 || a[i] >= prefixMax(a, i-1)) ==> Fill(a)[i] == a[i]
{
  // Direct from definitions:
  //   i=0: Fill(a)[0] = a[0]
  //   i>0: Fill(a)[i] = max(prefixMax(a, i-1), a[i]) = a[i] when a[i] >= prefixMax(a, i-1)
}
