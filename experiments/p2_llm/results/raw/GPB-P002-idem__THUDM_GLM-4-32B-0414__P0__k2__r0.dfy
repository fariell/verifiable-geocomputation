// Pit filling is idempotent on the 1D left-outlet specialization: Fill(Fill(a)) = Fill(a).
// Cells that already do not spill to the left are fixed points of Raise.

module PitFillingIdempotent {
  // Represents a 1D elevation profile
  type ElevationProfile = array<int>

  // Fill operation for 1D elevation profile
  function Fill(a: ElevationProfile): ElevationProfile {
    var n := a.Length;
    var result := new int[n];
    result[0] := a[0];
    for i := 1 to n - 1
      invariant 1 <= i <= n - 1
      invariant forall j :: 0 <= j < i ==> result[j] == max(a[0..j+1])
      decreases n - i
    {
      result[i] := max(a[i], result[i - 1]);
    }
    return result;
  }

  // Fixed point property: cells that do not spill to the left are fixed points of Raise
  lemma FixedPointProperty(a: ElevationProfile, i: int)
    requires 0 <= i < a.Length
    requires a[i] >= a[i - 1]  // Cell does not spill to the left
    ensures Fill(a)[i] == a[i]
  {
    // Base case: first cell is always a fixed point
    if i == 0 {
      assert Fill(a)[0] == a[0];
    } else {
      // Inductive step: if previous cell is a fixed point, current cell is too
      FixedPointProperty(a, i - 1);
      assert Fill(a)[i] == max(a[i], Fill(a)[i - 1]);
      assert Fill(a)[i - 1] == a[i - 1];
      assert a[i] >= a[i - 1];
      assert max(a[i], a[i - 1]) == a[i];
    }
  }

  // Idempotence property: Fill(Fill(a)) = Fill(a)
  lemma Idempotence(a: ElevationProfile)
    ensures Fill(Fill(a)) == Fill(a)
  {
    var n := a.Length;
    for i := 0 to n
      invariant 0 <= i <= n
      invariant forall j :: 0 <= j < i ==> Fill(Fill(a))[j] == Fill(a)[j]
      decreases n - i
    {
      // Base case: first cell is always equal
      if i == 0 {
        assert Fill(Fill(a))[0] == Fill(a)[0];
      } else {
        // Inductive step: if previous cells are equal, current cell is too
        assert Fill(Fill(a))[i - 1] == Fill(a)[i - 1];
        assert Fill(a)[i] == max(a[i], Fill(a)[i - 1]);
        assert Fill(Fill(a))[i] == max(Fill(a)[i], Fill(Fill(a))[i - 1]);
        assert Fill(Fill(a))[i - 1] == Fill(a)[i - 1];
        assert Fill(a)[i - 1] == a[i - 1] || Fill(a)[i - 1] == a[j] for some j < i - 1;
        // By the fixed point property, if a[i] >= a[i - 1], then Fill(a)[i] == a[i]
        // Otherwise, Fill(a)[i] == Fill(a)[i - 1] == a[i - 1]
        // In either case, max(Fill(a)[i], Fill(Fill(a))[i - 1]) == Fill(a)[i]
      }
    }
  }
}
