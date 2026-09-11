module PitFillWangLiu {
  // 1D Wang-Liu pit-filling specialization with left outlet
  function FillLeft(orig: array<real>): array<real>
  {
    var n := orig.Length;
    var fill := new real[n];
    fill[0] := orig[0];
    var i := 1;
    while i < n
      invariant i >= 1 && i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] == orig[j] || fill[j] == fill[j-1]
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
      invariant forall j :: 0 <= j < i ==> fill[j] >= fill[j-1]
    {
      fill[i] := max(orig[i], fill[i-1]);
      i := i + 1;
    }
    return fill;
  }

  // Theorem: Each raise is monotone (no cell elevation decreases)
  lemma MonotoneRise(orig: array<real>)
    requires orig != null
    ensures forall i :: 0 <= i < orig.Length ==> FillLeft(orig)[i] >= orig[i]
  {
    var fill := FillLeft(orig);
    var n := orig.Length;
    var i := 0;
    while i < n
      invariant i >= 0 && i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
    {
      assert fill[i] >= orig[i];
      i := i + 1;
    }
  }

  // Theorem: After a full scan the profile is nondecreasing
  lemma NonDecreasingProfile(orig: array<real>)
    requires orig != null
    ensures forall i :: 0 <= i < orig.Length - 1 ==> FillLeft(orig)[i] <= FillLeft(orig)[i+1]
  {
    var fill := FillLeft(orig);
    var n := orig.Length;
    var i := 0;
    while i < n - 1
      invariant i >= 0 && i <= n - 1
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[j+1]
    {
      assert fill[i] <= fill[i+1];
      i := i + 1;
    }
  }

  method Main()
  {
    var orig := new real[5];
    orig[0] := 1.0;
    orig[1] := 0.5;
    orig[2] := 0.8;
    orig[3] := 0.3;
    orig[4] := 0.7;
    
    var fill := FillLeft(orig);
    print "Original: ";
    forall i | 0 <= i < orig.Length
      print orig[i], " ";
    print "\nFilled: ";
    forall i | 0 <= i < fill.Length
      print fill[i], " ";
    print "\n";
    
    // Verify theorems
    MonotoneRise(orig);
    NonDecreasingProfile(orig);
  }
}
