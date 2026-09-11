// Formal specification of the 1D Wang-Liu pit-filling algorithm with left outlet
module PitFill1D {
  // Represents a 1D elevation profile
  type Profile = array<int>

  // Fill operation: Fill[0] = orig[0], Fill[i] = max(orig[i], Fill[i-1])
  function Fill(orig: Profile): Profile {
    var n := orig.Length;
    var fill := new int[n];
    fill[0] := orig[0];
    forall i | 0 < i < n {
      fill[i] := max(orig[i], fill[i-1]);
    }
    return fill;
  }

  // Property: Each raise is monotone (no cell elevation decreases)
  lemma Monotonicity(orig: Profile, fill: Profile)
    requires fill == Fill(orig)
    ensures forall i, j | 0 <= i <= j < orig.Length :: fill[i] <= fill[j]
  {
    // Base case: fill[0] = orig[0]
    // Inductive step: fill[i] = max(orig[i], fill[i-1]) >= fill[i-1]
    var n := orig.Length;
    forall i, j | 0 <= i <= j < n {
      if i == j { return; }
      if j == i + 1 {
        assert fill[j] == max(orig[j], fill[j-1]) >= fill[j-1];
      } else {
        var k := i;
        while k < j {
          invariant i <= k < j;
          invariant forall l | i <= l <= k :: fill[l] <= fill[k];
          {
            k := k + 1;
            assert fill[k] == max(orig[k], fill[k-1]) >= fill[k-1];
          }
        }
      }
    }
  }

  // Property: After a full scan the profile is nondecreasing
  lemma NonDecreasingProfile(orig: Profile, fill: Profile)
    requires fill == Fill(orig)
    ensures forall i, j | 0 <= i <= j < orig.Length :: fill[i] <= fill[j]
  {
    Monotonicity(orig, fill);
  }

  // Example usage and verification
  method Main()
  {
    var orig := new int[5];
    orig[0] := 1;
    orig[1] := 0;
    orig[2] := 2;
    orig[3] := 1;
    orig[4] := 3;
    
    var fill := Fill(orig);
    
    // Verify the properties
    assert fill[0] == 1;
    assert fill[1] == max(0, 1) == 1;
    assert fill[2] == max(2, 1) == 2;
    assert fill[3] == max(1, 2) == 2;
    assert fill[4] == max(3, 2) == 3;
    
    Monotonicity(orig, fill);
    NonDecreasingProfile(orig, fill);
  }
}
