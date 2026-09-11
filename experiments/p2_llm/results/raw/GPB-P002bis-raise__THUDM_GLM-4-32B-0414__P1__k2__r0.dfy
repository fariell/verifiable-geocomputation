module RaiseNbr {
  // Define the 4-neighbors of a cell (up, down, left, right)
  function Nbr4(p: (int, int)): set<(int, int)>
  {
    set var (r, c); (r - 1, c); (r + 1, c); (r, c - 1); (r, c + 1)
  }

  // Define the RaiseNbr operation
  function RaiseNbr(h: array2d<real>, p: (int, int), processed: set<(int, int)>): real
  {
    // The neighbor must be a 4-neighbor of p and not yet processed
    var nbrs := Nbr4(p) - processed;
    if |nbrs| == 0 then h[p] else
    {
      // Raise the neighbor to the maximum of its original elevation and the processed cell's fill
      var max_elev := h[p];
      var raised_nbrs := set var (r, c); (r, c) in nbrs; h[(r, c)] := max(h[(r, c)], max_elev);
      // The raised elevation is the maximum of the original and the processed cell's fill
      max(raised_nbrs)
    }
  }

  // Lemma: Raising a 4-neighbor from an already-processed cell never decreases any cell elevation
  lemma NoDecrease(h: array2d<real>, p: (int, int), processed: set<(int, int)>)
    requires forall (r, c) :: (r, c) in processed ==> h[(r, c)] == RaiseNbr(h, (r, c), {})
    ensures forall (r, c) :: (r, c) in Nbr4(p) - processed ==> h[(r, c)] <= RaiseNbr(h, p, processed)
  {
    var nbrs := Nbr4(p) - processed;
    if |nbrs| == 0 then return;
    var max_elev := h[p];
    var raised_nbrs := set var (r, c); (r, c) in nbrs; h[(r, c)] := max(h[(r, c)], max_elev);
    forall (r, c) :: (r, c) in nbrs
      ensures h[(r, c)] <= RaiseNbr(h, p, processed)
    {
      assert h[(r, c)] <= max(h[(r, c)], max_elev);
    }
  }

  // Lemma: The neighbor is lifted at least to max(original neighbor, processed cell fill)
  lemma MinRaise(h: array2d<real>, p: (int, int), processed: set<(int, int)>)
    requires forall (r, c) :: (r, c) in processed ==> h[(r, c)] == RaiseNbr(h, (r, c), {})
    ensures forall (r, c) :: (r, c) in Nbr4(p) - processed ==>
      RaiseNbr(h, p, processed) >= max(h[(r, c)], h[p])
  {
    var nbrs := Nbr4(p) - processed;
    if |nbrs| == 0 then return;
    var max_elev := h[p];
    var raised_nbrs := set var (r, c); (r, c) in nbrs; h[(r, c)] := max(h[(r, c)], max_elev);
    forall (r, c) :: (r, c) in nbrs
      ensures RaiseNbr(h, p, processed) >= max(h[(r, c)], h[p])
    {
      assert max(h[(r, c)], max_elev) >= max(h[(r, c)], h[p]);
    }
  }
}
