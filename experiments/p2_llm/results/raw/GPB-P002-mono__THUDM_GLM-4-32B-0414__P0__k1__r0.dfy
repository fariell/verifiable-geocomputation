// Formal specification of the 1D Wang-Liu pit-filling algorithm with left outlet
module PitFill1D {
  // Represents a 1D elevation profile
  type ElevationProfile = array<int>

  // Fill operation with left outlet
  function Fill(orig: ElevationProfile): ElevationProfile
  {
    var n := orig.Length;
    var fill := new int[n];
    fill[0] := orig[0];
    var i := 1;
    while i < n
      invariant 1 <= i <= n
      invariant forall j :: 0 <= j < i ==> fill[j] == orig[j] || fill[j] == fill[j-1]
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j]
      invariant forall j :: 0 <= j < i ==> fill[j] >= fill[j-1]
    {
      fill[i] := max(orig[i], fill[i-1]);
      i := i + 1;
    }
    return fill;
  }

  // Property: Each raise is monotone (no cell elevation decreases)
  lemma Monotonicity(orig: ElevationProfile)
  {
    var n := orig.Length;
    var fill := Fill(orig);
    var i := 0;
    while i < n - 1
      invariant 0 <= i < n - 1
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[j+1]
    {
      assert fill[i] <= fill[i+1];
      i := i + 1;
    }
  }

  // Property: After a full scan the profile is nondecreasing
  lemma NonDecreasingProfile(orig: ElevationProfile)
  {
    var n := orig.Length;
    var fill := Fill(orig);
    var i := 0;
    while i < n - 1
      invariant 0 <= i < n - 1
      invariant forall j :: 0 <= j < i ==> fill[j] <= fill[j+1]
    {
      assert fill[i] <= fill[i+1];
      i := i + 1;
    }
  }

  // Helper function to compute maximum
  function max(a: int, b: int): int
  {
    if a >= b then a else b
  }
}
