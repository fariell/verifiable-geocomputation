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
      var filled := new int[n];
      filled[0] := a[0];
      var i := 1;
      while i < n
        invariant 1 <= i <= n
        invariant forall j :: 0 <= j < i ==> filled[j] == max(a[0..j+1])
        decreases n - i
      {
        filled[i] := max(a[i], filled[i-1]);
        i := i + 1;
      }
      filled
    }
  }

  // Fixed point property: cells that do not spill to the left are fixed points of Raise
  lemma FixedPoint(a: ElevationProfile, i: int)
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
      // By the invariant of Fill, we know that Fill(a)[i-1] == max(a[0..i])
      // Since a[i] >= a[i-1], and a[i-1] >= max(a[0..i-1]) by the fixed point property,
      // we have a[i] >= max(a[0..i]), so Fill(a)[i] == a[i]
      assert Fill(a)[i] == max(a[i], Fill(a)[i-1]);
      assert Fill(a)[i-1] == a[i-1];
      assert a[i] >= a[i-1];
      assert a[i] >= max(a[0..i]);
      assert Fill(a)[i] == a[i];
    }
  }

  // Idempotence property: Fill(Fill(a)) = Fill(a)
  lemma Idempotence(a: ElevationProfile)
    ensures Fill(Fill(a)) == Fill(a)
  {
    var n := |a|;
    var i := 0;
    while i < n
      invariant 0 <= i <= n
      invariant forall j :: 0 <= j < i ==> Fill(Fill(a))[j] == Fill(a)[j]
      decreases n - i
    {
      // By the fixed point property, if a[j] does not spill to the left,
      // then Fill(a)[j] == a[j], and Fill(Fill(a))[j] == Fill(a)[j]
      if i > 0 && a[i] >= a[i-1] {
        FixedPoint(a, i);
        assert Fill(Fill(a))[i] == Fill(a)[i];
      }
      // Otherwise, Fill(Fill(a))[i] == Fill(a)[i] by the definition of Fill
      else {
        assert Fill(Fill(a))[i] == Fill(a)[i];
      }
      i := i + 1;
    }
  }
}
