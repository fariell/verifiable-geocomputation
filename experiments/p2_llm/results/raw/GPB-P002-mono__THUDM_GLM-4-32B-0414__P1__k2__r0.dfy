module PitFillMonotonicity {
  // 1D Wang-Liu pit-filling specialization with left outlet
  function Fill(orig: array<real>): array<real>
  {
    var n := orig.Length;
    var fill := new real[n];
    fill[0] := orig[0];
    var i := 1;
    while i < n
      invariant i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] == orig[j] || fill[j] == fill[j-1];
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j];
      invariant forall j :: 0 <= j < i ==> fill[j] >= fill[j-1];
    {
      fill[i] := max(orig[i], fill[i-1]);
      i := i + 1;
    }
    return fill;
  }

  // Theorem: Each raise is monotone - no cell elevation decreases
  lemma Monotonicity(orig: array<real>)
    requires orig != null;
    ensures forall i :: 0 <= i < orig.Length ==> Fill(orig)[i] >= orig[i];
  {
    var n := orig.Length;
    var fill := Fill(orig);
    var i := 0;
    while i < n
      invariant i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j];
    {
      assert fill[i] >= orig[i];
      i := i + 1;
    }
  }

  // Theorem: After a full scan the profile is nondecreasing
  lemma NonDecreasing(orig: array<real>)
    requires orig != null;
    ensures forall i, j :: 0 <= i <= j < orig.Length ==> Fill(orig)[i] <= Fill(orig)[j];
  {
    var n := orig.Length;
    var fill := Fill(orig);
    var i := 0;
    while i < n
      invariant i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[j+1];
    {
      if i < n - 1 {
        assert fill[i] <= fill[i+1];
      }
      i := i + 1;
    }
  }

  method Main()
  {
    // Example usage
    var orig := new real[5];
    orig[0] := 1.0;
    orig[1] := 0.5;
    orig[2] := 0.8;
    orig[3] := 1.2;
    orig[4] := 0.9;
    
    var fill := Fill(orig);
    print "Original: ";
    forall i | 0 <= i < orig.Length { print orig[i], " "; }
    print "\nFilled: ";
    forall i | 0 <= i < fill.Length { print fill[i], " "; }
    print "\n";
    
    // Verify properties
    Monotonicity(orig);
    NonDecreasing(orig);
  }
}
