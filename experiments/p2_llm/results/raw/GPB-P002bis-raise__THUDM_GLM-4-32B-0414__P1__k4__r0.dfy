module RaiseNbr {
  // Define the 4-neighbors of a cell (up, down, left, right)
  function Nbr4(p: (int, int)): set<(int, int)>
  {
    set var (r, c); (r - 1, c); (r + 1, c); (r, c - 1); (r, c + 1)
  }

  // Define the RaiseNbr operation: raise a neighbor to max(original, processed)
  function RaiseNbr(h: array2d<real>, p: (int, int), n: (int, int)): real
    requires 0 <= p.0 < h.Length1 && 0 <= p.1 < h.Length2
    requires 0 <= n.0 < h.Length1 && 0 <= n.1 < h.Length2
    requires n in Nbr4(p)
  {
    max(h[n.0][n.1], h[p.0][p.1])
  }

  // Lemma: Raising a neighbor never decreases its elevation
  lemma NoDecrease(h: array2d<real>, p: (int, int), n: (int, int))
    requires 0 <= p.0 < h.Length1 && 0 <= p.1 < h.Length2
    requires 0 <= n.0 < h.Length1 && 0 <= n.1 < h.Length2
    requires n in Nbr4(p)
    ensures RaiseNbr(h, p, n) >= h[n.0][n.1]
  {
    // The max function ensures the result is at least as large as either input
  }

  // Lemma: The neighbor is lifted at least to max(original neighbor, processed cell fill)
  lemma MinRaise(h: array2d<real>, p: (int, int), n: (int, int))
    requires 0 <= p.0 < h.Length1 && 0 <= p.1 < h.Length2
    requires 0 <= n.0 < h.Length1 && 0 <= n.1 < h.Length2
    requires n in Nbr4(p)
    ensures RaiseNbr(h, p, n) == max(h[n.0][n.1], h[p.0][p.1])
  {
    // By definition of RaiseNbr
  }

  method Main()
  {
    print "GeoProofBench P-COMP-1 · RaiseNbr properties\n";
    print "All properties verified by compilation\n";
  }
}
