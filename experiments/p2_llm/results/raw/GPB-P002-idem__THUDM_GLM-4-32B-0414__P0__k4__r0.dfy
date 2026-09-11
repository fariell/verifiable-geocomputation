// Pit filling is idempotent on the 1D left-outlet specialization: Fill(Fill(a)) = Fill(a).
// Cells that already do not spill to the left are fixed points of Raise.

module PitFillingIdempotent {
  // Represents a 1D elevation profile
  type ElevationProfile = seq<int>

  // Fill operation for 1D elevation profile
  function Fill(a: ElevationProfile): ElevationProfile {
    // Base case: empty profile
    if |a| == 0 then []
    // Base case: single cell profile
    else if |a| == 1 then [a[0]]
    // Recursive case: fill the profile
    else {
      var n := |a|;
      var filled := [a[0]];
      var current_max := a[0];
      var i := 1;
      while i < n
        invariant 1 <= i <= n
        invariant |filled| == i
        invariant filled == Fill(a[..i])
        invariant current_max == max(a[..i])
        decreases n - i
      {
        current_max := max(current_max, a[i]);
        filled := filled + [current_max];
        i := i + 1;
      }
      filled
    }
  }

  // Fixed point property: cells that do not spill to the left are fixed points of Raise
  lemma FixedPointProperty(a: ElevationProfile, i: int)
    requires 0 <= i < |a|
    requires a[i] >= a[i-1] when i > 0
    ensures Fill(a)[i] == a[i]
  {
    // Base case: i == 0
    if i == 0 {
      assert Fill(a)[0] == a[0];
    }
    // Inductive case: i > 0
    else {
      // By induction hypothesis, Fill(a)[i-1] == a[i-1]
      // Since a[i] >= a[i-1], the max operation in Fill will not change a[i]
      assert Fill(a)[i] == max(Fill(a)[i-1], a[i]) == max(a[i-1], a[i]) == a[i];
    }
  }

  // Idempotence property: Fill(Fill(a)) = Fill(a)
  lemma IdempotenceProperty(a: ElevationProfile)
    ensures Fill(Fill(a)) == Fill(a)
  {
    var n := |a|;
    var i := 0;
    while i < n
      invariant 0 <= i <= n
      invariant Fill(Fill(a))[..i] == Fill(a)[..i]
      decreases n - i
    {
      // By FixedPointProperty, if a[i] does not spill to the left, it is a fixed point
      if i > 0 && a[i] >= a[i-1] {
        assert Fill(a)[i] == a[i];
        // Since Fill(a)[i] == a[i], and a[i] does not spill to the left, Fill(Fill(a))[i] == Fill(a)[i]
        assert Fill(Fill(a))[i] == Fill(a)[i];
      }
      // Otherwise, Fill(Fill(a))[i] is the maximum of Fill(a)[..i], which is Fill(a)[i]
      else {
        assert Fill(Fill(a))[i] == Fill(a)[i];
      }
      i := i + 1;
    }
  }
}
