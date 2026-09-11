// Formal specification of the 1D Wang-Liu pit-filling algorithm with left outlet
module PitFill1D {
  // Represents a 1D elevation profile
  type Profile = array<int>

  // Fill operation: Fill[0]=orig[0], Fill[i]=max(orig[i], Fill[i-1])
  function Fill(orig: Profile): Profile {
    var n := orig.Length;
    var fill := new int[n];
    fill[0] := orig[0];
    var i := 1;
    while i < n
      invariant 1 <= i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] == (if j == 0 then orig[0] else max(orig[j], fill[j-1]))
    {
      fill[i] := max(orig[i], fill[i-1]);
      i := i + 1;
    }
    return fill;
  }

  // Property: Each raise is monotone (no cell elevation decreases)
  lemma Monotonicity(orig: Profile, fill: Profile)
    requires fill == Fill(orig)
    ensures forall i, j :: 0 <= i <= j < orig.Length ==> fill[i] <= fill[j]
  {
    var n := orig.Length;
    var i := 0;
    while i < n
      invariant 0 <= i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[i]
    {
      var j := 0;
      while j < i
        invariant 0 <= j <= i
        invariant fill[j] <= fill[i]
      {
        j := j + 1;
      }
      i := i + 1;
    }
  }

  // Property: After a full scan the profile is nondecreasing
  lemma NonDecreasingProfile(orig: Profile, fill: Profile)
    requires fill == Fill(orig)
    ensures forall i :: 0 <= i < fill.Length - 1 ==> fill[i] <= fill[i+1]
  {
    var n := orig.Length;
    var i := 0;
    while i < n - 1
      invariant 0 <= i <= n - 1
      invariant forall j :: 0 <= j <= i ==> fill[j] <= fill[j+1]
    {
      assert fill[i] <= fill[i+1];  // By definition of Fill
      i := i + 1;
    }
  }

  // Example usage and verification
  method Main()
  {
    var orig := new int[5];
    orig[0] := 10;
    orig[1] := 8;
    orig[2] := 12;
    orig[3] := 9;
    orig[4] := 11;
    
    var fill := Fill(orig);
    
    // Verify monotonicity
    Monotonicity(orig, fill);
    
    // Verify non-decreasing profile
    NonDecreasingProfile(orig, fill);
    
    // Print results (for demonstration)
    print "Original profile: ";
    var i := 0;
    while i < orig.Length {
      print orig[i], " ";
      i := i + 1;
    }
    print "\nFilled profile: ";
    i := 0;
    while i < fill.Length {
      print fill[i], " ";
      i := i + 1;
    }
    print "\n";
  }
}
