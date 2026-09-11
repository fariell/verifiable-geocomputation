// Formal specification of the 1D Wang-Liu pit-filling algorithm with left outlet
module PitFill1D {
  // Represents a 1D elevation profile
  type Profile = array<int>

  // Fill operation: Fill[0]=orig[0], Fill[i]=max(orig[i], Fill[i-1])
  function Fill(orig: Profile): Profile
  {
    var n := orig.Length;
    var fill := new int[n];
    fill[0] := orig[0];
    var i := 1;
    while i < n
      invariant 1 <= i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] == (if j == 0 then orig[0] else max(orig[j], fill[j-1]));
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]; // No cell elevation decreases
    {
      fill[i] := max(orig[i], fill[i-1]);
      i := i + 1;
    }
    return fill;
  }

  // Property: After a full scan, the profile is nondecreasing
  lemma FillIsNonDecreasing(orig: Profile)
  {
    var n := orig.Length;
    var fill := Fill(orig);
    var i := 1;
    while i < n
      invariant 1 <= i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[j+1];
    {
      assert fill[i-1] <= fill[i];
      i := i + 1;
    }
  }

  // Property: Each raise is monotone (no cell elevation decreases)
  lemma FillIsMonotone(orig: Profile)
  {
    var n := orig.Length;
    var fill := Fill(orig);
    var i := 0;
    while i < n
      invariant 0 <= i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j];
    {
      assert fill[i] >= orig[i];
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
    orig[3] := 6;
    orig[4] := 9;
    
    var fill := Fill(orig);
    
    // Verify the properties
    FillIsNonDecreasing(orig);
    FillIsMonotone(orig);
    
    // Print the results (for demonstration purposes)
    print "Original profile: ";
    var i := 0;
    while i < orig.Length
    {
      print orig[i], " ";
      i := i + 1;
    }
    print "\nFilled profile: ";
    i := 0;
    while i < fill.Length
    {
      print fill[i], " ";
      i := i + 1;
    }
    print "\n";
  }
}
