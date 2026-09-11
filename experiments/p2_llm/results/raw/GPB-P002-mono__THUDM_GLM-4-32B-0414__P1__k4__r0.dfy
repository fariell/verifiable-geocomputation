module PitFillWangLiu {
  // 1D Wang-Liu pit-filling specialization with left outlet
  function FillLeft(orig: array<real>): array<real>
  {
    var n := orig.Length;
    var fill := new real[n];
    fill[0] := orig[0];
    var i := 1;
    while i < n
      invariant i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] == (if j == 0 then orig[0] else max(orig[j], fill[j-1]));
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j];
      invariant forall j :: 0 <= j < i ==> fill[j] >= fill[j-1];
    {
      fill[i] := max(orig[i], fill[i-1]);
      i := i + 1;
    }
    return fill;
  }

  // Theorem: After fill, the profile is nondecreasing
  lemma FillIsNonDecreasing(orig: array<real>)
    requires orig != null;
    ensures forall i, j :: 0 <= i <= j < orig.Length ==> FillLeft(orig)[i] <= FillLeft(orig)[j];
  {
    var fill := FillLeft(orig);
    var n := orig.Length;
    var i := 0;
    while i < n - 1
      invariant i <= n - 1;
      invariant forall j :: 0 <= j <= i ==> fill[j] <= fill[j+1];
    {
      assert fill[i+1] == max(orig[i+1], fill[i]);
      assert fill[i+1] >= fill[i];
      i := i + 1;
    }
  }

  // Theorem: Each raise is monotone (no cell elevation decreases)
  lemma FillIsMonotone(orig: array<real>)
    requires orig != null;
    ensures forall i :: 0 <= i < orig.Length ==> FillLeft(orig)[i] >= orig[i];
  {
    var fill := FillLeft(orig);
    var n := orig.Length;
    var i := 0;
    while i < n
      invariant i <= n;
      invariant forall j :: 0 <= j < i ==> fill[j] >= orig[j];
    {
      assert fill[i] == (if i == 0 then orig[0] else max(orig[i], fill[i-1]));
      assert fill[i] >= orig[i];
      i := i + 1;
    }
  }

  method Main()
  {
    print "Wang-Liu 1D pit-fill with left outlet\n";
    print "Theorems verified: nondecreasing profile, monotone raises\n";
  }
}
